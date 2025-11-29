FROM php:8.3-fpm

# Install system dependencies and PHP extensions
RUN apt-get update && apt-get install -y \
    git zip unzip curl nano vim openssh-server \
    libpq-dev libzip-dev libpng-dev libjpeg-dev libonig-dev libxml2-dev libicu-dev libxslt-dev libssl-dev \
    && docker-php-ext-install pdo_mysql mysqli zip gd intl opcache \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Configure PHP error logging
RUN echo "log_errors = On" >> /usr/local/etc/php/conf.d/docker-php-logging.ini \
 && echo "error_log = /proc/self/fd/2" >> /usr/local/etc/php/conf.d/docker-php-logging.ini

# Configure PHP-FPM logging to stdout/stderr
RUN sed -i 's|;catch_workers_output = yes|catch_workers_output = yes|' /usr/local/etc/php-fpm.d/www.conf \
 && sed -i 's|;access.log = log/\$pool.access.log|access.log = /proc/self/fd/2|' /usr/local/etc/php-fpm.d/www.conf

# Install Composer (from official image)
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Install Node.js + npm + yarn (for Drupal theming)
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
 && apt-get install -y nodejs \
 && npm install -g yarn

# Configure SSH for remote container access
RUN apt-get install -y openssh-server && mkdir -p /var/run/sshd \
  && useradd -ms /bin/bash developer \
  && echo "developer:Password@102030" | chpasswd \
  && echo "root:Password@102030" | chpasswd \
  && sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config \
  && echo "AllowUsers developer root" >> /etc/ssh/sshd_config

# --- 🔥 Important for Drupal ---
# Change workdir to /var/www/html/web to match Drupal webroot
WORKDIR /var/www/html/web

# Ensure permissions (especially for /sites/default/files)
RUN chown -R www-data:www-data /var/www/html

# Expose PHP-FPM and SSH ports
EXPOSE 9000 22

# Start both SSH and PHP-FPM
CMD service ssh start && php-fpm
