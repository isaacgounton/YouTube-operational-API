FROM php:8.2-apache

# Set working directory
WORKDIR /var/www/html

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    protobuf-compiler \
    libzip-dev \
    && rm -rf /var/list/apt/lists/*

# Install PHP extensions
RUN docker-php-ext-install zip

# Enable Apache modules
RUN a2enmod rewrite

# Configure Apache
RUN sed -ri -e 'N;N;N;s/(<Directory \/var\/www\/>\n)(.*\n)(.*)AllowOverride None/\1\2\3AllowOverride All/;p;d;' /etc/apache2/apache2.conf

# Install composer
COPY --from=composer/composer:latest-bin /composer /usr/bin/composer

# Copy application files
COPY . .

# Set correct permissions
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html

# Install dependencies and compile proto files
RUN composer require google/protobuf \
    && protoc --php_out=proto/php/ --proto_path=proto/prototypes/ $(find proto/prototypes/ -type f)

# Expose port 80 (Apache default)
EXPOSE 80

# Start Apache in foreground
CMD ["apache2-foreground"]
