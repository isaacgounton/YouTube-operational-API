FROM php:8.2-apache

WORKDIR /var/www/html

RUN apt-get update && apt-get install -y \
    protobuf-compiler \
    libzip-dev \
    unzip \
    curl \
    && rm -rf /var/list/apt/lists/* \
    && docker-php-ext-install zip pdo pdo_mysql \
    && mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini" \
    && sed -i 's/memory_limit = 128M/memory_limit = 256M/g' "$PHP_INI_DIR/php.ini" \
    && a2enmod rewrite \
    && sed -ri -e 'N;N;N;s/(<Directory \/var\/www\/>\n)(.*\n)(.*)AllowOverride None/\1\2\3AllowOverride All/;p;d;' /etc/apache2/apache2.conf \
    && echo "ServerName localhost" >> /etc/apache2/apache2.conf \
    && echo "DirectoryIndex index.php index.html" >> /etc/apache2/apache2.conf

COPY --from=composer/composer:latest-bin /composer /usr/bin/composer

COPY . .
RUN chown -R www-data:www-data /var/www/html \
    && find /var/www/html -type f -exec chmod 644 {} \; \
    && find /var/www/html -type d -exec chmod 755 {} \; \
    && composer require google/protobuf \
    && protoc --php_out=proto/php/ --proto_path=proto/prototypes/ $(find proto/prototypes/ -type f)

EXPOSE 80

CMD ["apache2-foreground"]
