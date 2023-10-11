FROM php:8.1-apache

ARG ENV
ENV ENV=${ENV:-production}

# Instala Dependencias
RUN apt-get update \
&& apt-get install -y curl wget nano git unzip libpq-dev libicu-dev libzip-dev gnupg \
zlib1g-dev g++ libpng-dev libonig-dev unixodbc-dev \
&& curl -s https://getcomposer.org/installer > composer_installer.php && \
php composer_installer.php \
&& mv composer.phar /usr/local/bin/composer && \
rm composer_installer.php

# Microsoft SQL Server Drivers & Tools
RUN curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add -
RUN curl https://packages.microsoft.com/config/ubuntu/20.04/prod.list > /etc/apt/sources.list.d/mssql-release.list
RUN apt-get update && ACCEPT_EULA=Y apt-get install -y msodbcsql18 \
    && ACCEPT_EULA=Y apt-get install -y mssql-tools18 \
    && echo 'export PATH="$PATH:/opt/mssql-tools18/bin"' >> ~/.bashrc \
    source ~/.bashrc
# Required extensions
RUN docker-php-ext-install pdo intl gd mbstring zip \
    && pecl install sqlsrv pdo_sqlsrv  \
    && docker-php-ext-enable sqlsrv pdo_sqlsrv
# Fetch and unzip the Project Nami specific version
WORKDIR /var/www/html
RUN wget https://github.com/ProjectNami/projectnami/archive/refs/tags/3.3.1.zip && \
    unzip 3.3.1.zip && \
    mv projectnami-3.3.1/* . && \
    rm -rf projectnami-3.3.1 3.3.1.zip && \
    chown -R www-data:www-data /var/www/html
# Create wp-config.php from sample and replace with environment variables
RUN cp wp-config-sample.php wp-config.php \
    && sed -i 's/database_name_here/${WORDPRESS_DB_NAME}/g' wp-config.php \
    && sed -i 's/username_here/${WORDPRESS_DB_USER}/g' wp-config.php \
    && sed -i 's/password_here/${WORDPRESS_DB_PASSWORD}/g' wp-config.php \
    && sed -i 's/localhost/${WORDPRESS_DB_HOST}/g' wp-config.php
# Database connection variables for WordPress setup
ARG WP_DB_HOST="wp-server01.database.windows.net"
ARG WP_DB_NAME="wp-database"
ARG WP_DB_USER="adminuser"
ARG WP_DB_PASSWORD="Ayush@007"

ENV WORDPRESS_DB_HOST=${WP_DB_HOST}
ENV WORDPRESS_DB_NAME=${WP_DB_NAME}
ENV WORDPRESS_DB_USER=${WP_DB_USER}
ENV WORDPRESS_DB_PASSWORD=${WP_DB_PASSWORD}

# Set Apache as foreground process
ENTRYPOINT [ "docker-php-entrypoint" ]
CMD [ "apache2-foreground" ]
