FROM php:8.2-apache

RUN apt-get update && apt-get install -y \
    libfreetype6-dev libjpeg62-turbo-dev libpng-dev \
    libzip-dev libxml2-dev libpq-dev libcurl4-openssl-dev \
    libonig-dev libicu-dev libxslt1-dev \
    unzip curl \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
       gd zip xml pdo pdo_pgsql pgsql mbstring curl soap intl opcache exif \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN curl -sL "https://download.moodle.org/download.php/direct/stable404/moodle-latest-404.tgz" \
    | tar -xz -C /var/www/ \
    && chown -R www-data:www-data /var/www/moodle

RUN printf '<VirtualHost *:80>\n\
  DocumentRoot /var/www/moodle\n\
  <Directory /var/www/moodle>\n\
    Options Indexes FollowSymLinks\n\
    AllowOverride All\n\
    Require all granted\n\
  </Directory>\n\
</VirtualHost>\n' > /etc/apache2/sites-available/000-default.conf \
    && a2dismod mpm_event && a2enmod mpm_prefork rewrite headers

RUN printf "max_input_vars=5000\nupload_max_filesize=50M\npost_max_size=50M\nmemory_limit=256M\n" \
    > /usr/local/etc/php/conf.d/moodle.ini

RUN mkdir -p /var/moodledata && chown -R www-data:www-data /var/moodledata

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 80
ENTRYPOINT ["/entrypoint.sh"]
