#!/bin/sh
set -e

DOMAIN_NAME="${DOMAIN_NAME:-localhost}"

# Render the server block with the configured domain.
sed "s/\${DOMAIN_NAME}/${DOMAIN_NAME}/g" /etc/nginx/templates/default.conf > /etc/nginx/conf.d/default.conf

# Generate a self-signed certificate on first start.
if [ ! -f /etc/nginx/ssl/cert.pem ]; then
    mkdir -p /etc/nginx/ssl
    openssl req -x509 -nodes -newkey rsa:2048 \
        -keyout /etc/nginx/ssl/key.pem \
        -out    /etc/nginx/ssl/cert.pem \
        -days 365 \
        -subj "/CN=${DOMAIN_NAME}"
fi

exec nginx -g "daemon off;"
