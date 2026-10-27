#!/bin/sh
set -e

DB_PASSWORD=$(cat /run/secrets/db_password)
WP_ADMIN_PASSWORD=$(cat /run/secrets/wp_admin_password)
WP_USER_PASSWORD=$(cat /run/secrets/wp_user_password)

cd /var/www/html


i=0
until mariadb-admin ping -h"${MYSQL_HOST}" -u"${MYSQL_USER}" -p"${DB_PASSWORD}" --silent; do
    i=$((i + 1))
    if [ "$i" -ge 30 ]; then
        echo "ERROR: MariaDB not reachable at ${MYSQL_HOST} after 60s" >&2
        exit 1
    fi
    echo "Waiting for MariaDB... (${i}/30)"
    sleep 2
done

if [ ! -f /var/www/html/wp-config.php ]; then
    wp core download --allow-root

    wp config create --allow-root \
        --dbname="${MYSQL_DATABASE}" \
        --dbuser="${MYSQL_USER}" \
        --dbpass="${DB_PASSWORD}" \
        --dbhost="${MYSQL_HOST}"

    wp core install --allow-root \
        --url="https://${DOMAIN_NAME}" \
        --title="${WP_TITLE}" \
        --admin_user="${WP_ADMIN_USER}" \
        --admin_password="${WP_ADMIN_PASSWORD}" \
        --admin_email="${WP_ADMIN_EMAIL}"

    wp user create --allow-root \
        "${WP_USER}" "${WP_USER_EMAIL}" \
        --role=author \
        --user_pass="${WP_USER_PASSWORD}"

    chown -R www-data:www-data /var/www/html
fi

exec php-fpm8.2 -F
