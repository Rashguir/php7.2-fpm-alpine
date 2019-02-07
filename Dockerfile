FROM php:7.2.14-fpm-alpine3.9

MAINTAINER Nicolas Sicard <nicolas.sicard@mandarine.academy>

RUN apk update -q; \
    apk add -q --no-cache \
        git \
        curl \
        make \
    ;

RUN apk add -q --no-cache --virtual .build-deps \
        $PHPIZE_DEPS \
        icu-dev \
        libzip-dev \
        zlib-dev \
    ;\
    pecl install -q xdebug-2.6.1 ;\
    docker-php-ext-enable xdebug; \
    docker-php-ext-configure zip --with-libzip; \
    docker-php-ext-install zip pdo pdo_mysql; \
    runDeps="$( \
        scanelf --needed --nobanner --format '%n#p' --recursive /usr/local/lib/php/extensions \
            | tr ',' '\n' \
            | sort -u \
            | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
    )"; \
    apk add -q --no-cache --virtual .api-phpexts-rundeps $runDeps; \
    apk del -q .build-deps;
    

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
ENV COMPOSER_ALLOW_SUPERUSER=1
ENV COMPOSER_ALLOW_XDEBUG=1
ENV COMPOSER_DISABLE_XDEBUG_WARN=1
RUN composer global require "symfony/flex" --prefer-dist --no-progress --no-suggest --classmap-authoritative
ENV PATH="${PATH}:/root/.composer/vendor/bin"

WORKDIR /var/www/html

