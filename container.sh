#!/bin/bash

# Prompt user for input
echo "Enter domain name (FQDN):"
read fqdn

echo "Enter MySQL database username:"
read user

echo "Enter MySQL database password:"
read password

echo "Enter host directory for program files and databases:"
read host_dir

echo "Enter backup time (in cron format, for example 0 15 * * * for 3 PM every day):"
read backup_time

echo "Enter email for Let's Encrypt SSL certificate:"
read email

# Create backup directory
backup_dir="$host_dir/backup"
mkdir -p $backup_dir

# Create the backup script
cat > $backup_dir/backup.sh << EOL
#!/bin/bash
filename="\$(date +"%Y-%m-%d").sql"
docker exec $fqdn sh -c "mysqldump -u $user -p$password --all-databases > /backup/\$filename"
EOL

# Make the script executable
chmod +x $backup_dir/backup.sh

# Create cron job for backup
crontab -l | { cat; echo "$backup_time $backup_dir/backup.sh"; } | crontab -

# Choose a unique port for phpMyAdmin
pmaport=$((8080 + $(docker ps -q | wc -l)))

# Create a docker image for nginx server with MySQL, modsecurity, and SSL
docker run -it --name $fqdn -p 80:80 -p 443:443 -p $pmaport:80 \
           --mount type=bind,source=$host_dir,target=/var/www/html \
           --mount type=bind,source=$backup_dir,target=/backup \
           --restart unless-stopped \
           -e FQDN=$fqdn -e MYSQL_USER=$user -e MYSQL_PASSWORD=$password \
           -d nginx-mysql-modsecurity-letsencrypt /bin/bash -c "apt-get update && apt-get install -y certbot python-certbot-nginx && certbot --nginx -d $fqdn --email $email --agree-tos --non-interactive && apt-get install -y phpmyadmin && ln -s /usr/share/phpmyadmin /var/www/html/phpmyadmin && echo 'location /phpmyadmin {
  root /var/www/html;
  index index.php index.html;
  location ~ \.php$ {
    try_files \$uri =404;
    fastcgi_pass unix:/var/run/php/php7.2-fpm.sock;
    fastcgi_index index.php;
    fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
    include fastcgi_params;
  }
}' >> /etc/nginx/sites-available/$fqdn.conf && service nginx restart"

# Create cron job for SSL certificate renewal
cat > /etc/cron.d/renew-ssl << EOL
0 0 * * * docker exec $fqdn sh -c "certbot renew --nginx"
EOL
