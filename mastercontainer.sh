#!/bin/bash

# Pull the latest Ubuntu image
docker pull ubuntu

# Set environment variables
MYSQL_PASSWORD=secret
FQDN=example.com

# Create the Docker container
docker run -d --name nginx-mysql-modsecurity-letsencrypt-phpmyadmin \
  -e MYSQL_PASSWORD=$MYSQL_PASSWORD \
  -e FQDN=$FQDN \
  -p 80:80 \
-p 443:443 \
-p 3306:3306 \
  ubuntu bash -c '
    # Update the package repository and install Nginx, MySQL, ModSecurity, Let's Encrypt SSL certificates, and phpMyAdmin
    apt-get update && \
    apt-get install -y nginx mysql-server certbot phpmyadmin && \
    sed -i "s/.*listen.*/listen 3306;/" /etc/nginx/conf.d/default.conf && \
    sed -i "s/.*server_name.*/server_name $FQDN;/" /etc/nginx/conf.d/default.conf && \
    certbot --nginx -d $FQDN && \
    ln -s /usr/share/phpmyadmin /var/www/html/phpmyadmin
    
    # Start Nginx and MySQL
    service nginx start && \
    service mysql start
  '
