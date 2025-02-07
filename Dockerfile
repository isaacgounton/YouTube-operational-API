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
    && sed -i 's/AllowOverride None/AllowOverride All/g' /etc/apache2/apache2.conf \
    && echo "ServerName localhost" >> /etc/apache2/apache2.conf \
    && echo "DirectoryIndex index.php index.html" >> /etc/apache2/apache2.conf

COPY --from=composer/composer:latest-bin /composer /usr/bin/composer

# Create necessary directories first
RUN mkdir -p /var/www/html/ytPrivate \
    && mkdir -p /var/www/html/proto/php \
    && chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html

# Copy application files
COPY . .

# Install dependencies and compile proto files
RUN cd /var/www/html \
    && composer require google/protobuf \
    && protoc --php_out=proto/php/ --proto_path=proto/prototypes/ $(find proto/prototypes/ -type f) \
    && chown -R www-data:www-data . \
    && chmod -R 755 . \
    && find . -type f -exec chmod 644 {} \; \
    && find . -type d -exec chmod 755 {} \; \
    && chmod 777 ytPrivate

# Add health check for Coolify
HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:80/ || exit 1

EXPOSE 80

CMD ["apache2-foreground"]
