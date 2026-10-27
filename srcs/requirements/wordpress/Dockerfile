FROM debian:bookworm

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates curl \
        php8.2-fpm php8.2-cli php8.2-mysqli php8.2-curl php8.2-gd \
        php8.2-mbstring php8.2-xml php8.2-zip \
        mariadb-client && \
    rm -rf /var/lib/apt/lists/*

RUN curl -o /usr/local/bin/wp \
        https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    chmod +x /usr/local/bin/wp

COPY conf/www.conf /etc/php/8.2/fpm/pool.d/www.conf
COPY tools/init-wp.sh /usr/local/bin/init-wp.sh
RUN chmod +x /usr/local/bin/init-wp.sh

RUN mkdir -p /var/www/html /run/php

EXPOSE 9000

ENTRYPOINT ["/usr/local/bin/init-wp.sh"]
