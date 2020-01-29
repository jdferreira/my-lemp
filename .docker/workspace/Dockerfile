ARG PHP_VERSION
FROM php:${PHP_VERSION}-cli

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

# Install additional utilities
RUN apt-get update -qq && apt-get upgrade -yqq git htop vim

# PHP and PHP-FPM configuration
COPY .shared/config/php/conf.d/* /usr/local/etc/php/conf.d/

# Setup SSH
RUN \
    apt-get update -qq && \
    apt-get upgrade -yqq openssh-server >/dev/null && \
    mkdir /var/run/sshd
USER www-data
COPY workspace/.ssh/insecure_id_rsa.pub /tmp/insecure_id_rsa.pub
RUN \
    mkdir -p ~/.ssh && \
    cat /tmp/insecure_id_rsa.pub >> ~/.ssh/authorized_keys && \
    chown -R www-data: ~/.ssh && \
    chmod 0700 ~/.ssh && \
    chmod 0600 ~/.ssh/authorized_keys
USER root

# Setup node
ARG NODE_VERSION=node
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash
RUN if [ "${NODE_VERSION}" != "node" ]; then . ~/.nvm/nvm.sh && nvm install ${NODE_VERSION}; fi
COPY workspace/node/default-packages /root/.nvm/

# Setup composer
COPY workspace/install-composer /tmp/install-composer
RUN chmod u+x /tmp/install-composer && /tmp/install-composer

# Activate bash completion feature, which is missing from the base image
RUN apt-get update -qq && apt-get upgrade -yqq bash-completion >/dev/null
RUN \
    ( \
        echo && \
        echo '# Enable programmable completion features' && \
        echo 'source /usr/share/bash-completion/bash_completion' \
    ) >> ~/.bashrc

# Working directory
WORKDIR /var/www/html

# Entry point
COPY .shared/entrypoint/* /bin/docker-entrypoint/
RUN chmod u+x /bin/docker-entrypoint/*

# Cleanup
RUN /root/setup-scripts/cleanup

# Define how to start the container
CMD [ "/usr/sbin/sshd", "-D"]
ENTRYPOINT [ \
    "/bin/docker-entrypoint/resolve-docker-host-ip" \
]
