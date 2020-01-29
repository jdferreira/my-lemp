ARG PHP_VERSION
FROM php:${PHP_VERSION}-fpm

# Copy shared setup scripts into the container
COPY .shared/setup-scripts /root/setup-scripts/
RUN chmod u+x /root/setup-scripts/*

# Set timezone
ARG TZ=UTC
RUN /root/setup-scripts/timezone

# Ensure www-data mimicks the host's UID and GID
ARG HOST_USER_ID=1000
ARG HOST_GROUP_ID=1000
RUN /root/setup-scripts/create-user www-data www-data ${HOST_USER_ID} ${HOST_GROUP_ID}

# Install common stuff in the container
RUN /root/setup-scripts/install-software
RUN /root/setup-scripts/install-php-extensions

# PHP and PHP-FPM configuration
COPY .shared/config/php/conf.d/* /usr/local/etc/php/conf.d/
COPY php-fpm/php-fpm.d/* /usr/local/etc/php-fpm.d/site/
RUN echo 'include=etc/php-fpm.d/site/*.conf' >> /usr/local/etc/php-fpm.conf
EXPOSE 9000

# Working directory
WORKDIR /var/www/html

# Entry point
COPY .shared/entrypoint/* /bin/docker-entrypoint/
RUN chmod u+x /bin/docker-entrypoint/*

# Cleanup
RUN /root/setup-scripts/cleanup

# Define how to start the container
ENTRYPOINT [ \
    "/bin/docker-entrypoint/resolve-docker-host-ip", \
    "php-fpm" \
]
