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
  ubuntu bash -c '
    # Update the package repository and install Nginx, MySQL, ModSecurity, Let's Encrypt SSL certificates, and phpMyAdmin
    apt-get update && \
    apt-get install -y nginx mysql-server libapache2-mod-security2 certbot python3-certbot-nginx phpmyadmin && \
    sed -i "s/.*listen.*/listen 80;/" /etc/nginx/conf.d/default.conf && \
    sed -i "s/.*server_name.*/server_name $FQDN;/" /etc/nginx/conf.d/default.conf && \
    certbot --nginx -d $FQDN
    
    # Configure phpMyAdmin
    ln -s /usr/share/phpmyadmin /var/www/html/phpmyadmin && \
    sed -i "s/.*listen.*/listen 80;/" /etc/phpmyadmin/apache.conf && \
    sed -i "s/.*server_name.*/server_name $FQDN;/" /etc/phpmyadmin/apache.conf
    
    # Start Nginx and MySQL
    service nginx start && \
    service mysql start
  '
