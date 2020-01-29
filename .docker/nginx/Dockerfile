FROM nginx:latest

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

# nginx configuration
COPY nginx/nginx.conf /etc/nginx/
COPY nginx/sites-available/default.conf /etc/nginx/sites-available/
EXPOSE 80 443

# Cleanup
RUN /root/setup-scripts/cleanup

# Define how to start the container
CMD ["nginx"]
