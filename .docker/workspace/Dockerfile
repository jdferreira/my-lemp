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
RUN apt-get update -qq && apt-get upgrade -yqq bash-completion git htop vim unzip >/dev/null

# PHP and PHP-FPM configuration
COPY .shared/config/php/conf.d/* /usr/local/etc/php/conf.d/

# Setup SSH
RUN \
    apt-get update -qq && \
    apt-get upgrade -yqq openssh-server >/dev/null && \
    mkdir /var/run/sshd
USER www-data
COPY workspace/.ssh/id_rsa.pub /tmp/id_rsa.pub
RUN \
    mkdir -p ~/.ssh && \
    cat /tmp/id_rsa.pub >> ~/.ssh/authorized_keys && \
    chown -R www-data: ~/.ssh && \
    chmod 0700 ~/.ssh && \
    chmod 0600 ~/.ssh/authorized_keys
USER root

# Setup node
USER www-data
ARG NODE_VERSION=node
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash
RUN if [ "${NODE_VERSION}" != "node" ]; then . ~/.nvm/nvm.sh && nvm install ${NODE_VERSION}; fi
RUN ( \
        echo '# Node, npm and nvm' && \
        echo 'export NVM_DIR="$HOME/.nvm"' && \
        echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm' && \
        echo \
    ) >> ~/.bash_profile
USER root
COPY --chown=www-data:www-data workspace/node/default-packages /home/www-data/.nvm/

# Setup composer
COPY workspace/install-composer /tmp/install-composer
RUN chmod u+x /tmp/install-composer && /tmp/install-composer && rm /tmp/install-composer

# Install composer autocomplete
RUN curl -s -o /usr/share/bash-completion/completions/composer \
        https://raw.githubusercontent.com/sjorek/composer-bash-completion/master/composer-completion.bash

USER www-data
RUN curl -s -o ~/.composer-completion.php \
        https://raw.githubusercontent.com/sjorek/composer-bash-completion/master/composer-completion.php
RUN ( \
        echo '# Autocomplete for composer' && \
        echo 'export COMPOSER_COMPLETION_PHP_SCRIPT=~/.composer-completion.php' && \
        echo \
    ) >> ~/.bash_profile
USER root

# Working directory
USER www-data
WORKDIR /var/www/html
RUN ( \
        echo '# Move to the relevant path' && \
        echo 'cd /var/www/html' && \
        echo \
    ) >> ~/.bash_profile
USER root

# Entry point
COPY .shared/entrypoint/* /bin/docker-entrypoint/
RUN chmod u+x /bin/docker-entrypoint/*

# Define how to start the container
CMD [ "/usr/sbin/sshd", "-D"]
ENTRYPOINT [ "/bin/docker-entrypoint/resolve-docker-host-ip" ]
