FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    apache2 \
    php8.1 \
    php8.1-pgsql \
    php8.1-gd \
    php8.1-curl \
    php8.1-xml \
    php8.1-mbstring \
    php8.1-zip \
    php8.1-intl \
    php8.1-soap \
    php8.1-opcache \
    libapache2-mod-php8.1 \
    curl unzip \
    && a2enmod rewrite headers \
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
</VirtualHost>\n' > /etc/apache2/sites-available/000-default.conf

RUN printf "max_input_vars=5000\nupload_max_filesize=50M\npost_max_size=50M\nmemory_limit=256M\n" \
    > /etc/php/8.1/apache2/conf.d/moodle.ini

RUN mkdir -p /var/moodledata && chown -R www-data:www-data /var/moodledata

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 80
ENTRYPOINT ["/entrypoint.sh"]
