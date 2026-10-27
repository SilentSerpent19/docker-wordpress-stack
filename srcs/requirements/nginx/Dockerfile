FROM debian:bookworm

RUN apt-get update && \
    apt-get install -y --no-install-recommends nginx openssl && \
    rm -rf /var/lib/apt/lists/*

COPY conf/nginx.conf /etc/nginx/templates/default.conf
COPY tools/nginx-entry.sh /usr/local/bin/nginx-entry.sh
RUN chmod +x /usr/local/bin/nginx-entry.sh

RUN rm -f /etc/nginx/sites-enabled/default

EXPOSE 443

ENTRYPOINT ["/usr/local/bin/nginx-entry.sh"]
