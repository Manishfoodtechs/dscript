#!/bin/bash

# Pull the latest Ubuntu image
docker pull ubuntu

# Create the Docker image
docker build -t nginx-mysql-modsecurity-letsencrypt-phpmyadmin . << EOF
FROM ubuntu

# Set environment variables
ENV MYSQL_PASSWORD secret
ENV FQDN example.com

# Update the package repository and install Nginx, MySQL, ModSecurity, Let's Encrypt SSL certificates, and phpMyAdmin
RUN apt-get update && \
    apt-get install -y nginx mysql-server libapache2-mod-security2 certbot python3-certbot-nginx phpmyadmin && \
    sed -i "s/.*listen.*/listen 80;/" /etc/nginx/conf.d/default.conf && \
    sed -i "s/.*server_name.*/server_name \$FQDN;/" /etc/nginx/conf.d/default.conf && \
    certbot --nginx -d \$FQDN

# Configure phpMyAdmin
RUN ln -s /usr/share/phpmyadmin /var/www/html/phpmyadmin && \
    sed -i "s/.*listen.*/listen 80;/" /etc/phpmyadmin/apache.conf && \
    sed -i "s/.*server_name.*/server_name \$FQDN;/" /etc/phpmyadmin/apache.conf

# Start Nginx and MySQL
CMD service nginx start && \
    service mysql start
EOF

# Run the Docker container
docker run -d -p 80:80 nginx-mysql-modsecurity-letsencrypt-phpmyadmin
