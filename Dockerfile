FROM php:8.1.34-zts-alpine AS build-snappy

RUN apk add --no-cache \
    git \
    autoconf \
    g++ \
    make \
    snappy-dev

RUN git clone --recursive --depth=1 https://github.com/kjdev/php-ext-snappy.git /usr/src/php-ext-snappy

WORKDIR /usr/src/php-ext-snappy

RUN phpize && \
    ./configure && \
    make && \
    make install

FROM alpine AS get-controller

RUN apk add --no-cache git

RUN git clone https://github.com/imperian-systems/unifi-controller.git /usr/src/unifi-controller


FROM php:8.1.34-zts-alpine AS build

RUN apk add --no-cache \
    snappy \
    php83-xml \
    gmp-dev \
    mysql-client

COPY --from=build-snappy /usr/local/lib/php/extensions/ /usr/local/lib/php/extensions/

RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
    && php composer-setup.php --install-dir=/usr/local/bin --filename=composer \
    && rm composer-setup.php

RUN docker-php-ext-enable snappy \
    && docker-php-ext-install gmp pdo_mysql \
    && composer create-project laravel/laravel:^8.0 unifi-controller


COPY . /usr/src/unifi-controller

WORKDIR /unifi-controller

RUN composer config repositories.unifi-controller path /usr/src/unifi-controller \
    && composer require imperian-systems/unifi-controller

COPY entrypoint.sh entrypoint.sh
RUN chmod +x entrypoint.sh

RUN sed -i \
    -e "s/DB_CONNECTION=.*/DB_CONNECTION=mysql/" \
    -e "s/DB_HOST=.*/DB_HOST=mysql/" \
    -e "s/DB_PORT=.*/DB_PORT=3306/" \
    -e "s/DB_DATABASE=.*/DB_DATABASE=laravel/" \
    -e "s/DB_USERNAME=.*/DB_USERNAME=laravel/" \
    -e "s/DB_PASSWORD=.*/DB_PASSWORD=secret/" \
    -e "s/DB_SSL_MODE=.*/DB_SSL_MODE=DISABLED/" \
    .env

CMD [ "./entrypoint.sh" ]
