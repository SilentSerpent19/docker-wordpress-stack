# Docker WordPress Stack

A self-hosted WordPress stack built from scratch with Docker: NGINX for TLS
termination, WordPress on php-fpm, and MariaDB, each in its own container,
built from a pinned Debian base rather than pre-built service images.

```
            https://wordpress.local (443)
                        │
                 ┌──────▼──────┐
                 │    nginx    │  TLS 1.2/1.3, self-signed cert
                 └──────┬──────┘
                        │ FastCGI :9000
                 ┌──────▼──────┐
                 │  wordpress  │  php-fpm 8.2 + WP-CLI
                 └──────┬──────┘
                        │ MySQL :3306
                 ┌──────▼──────┐
                 │   mariadb   │
                 └─────────────┘
          bridge network "inception" · two persistent volumes
```

## Highlights

- **Custom images only.** Every service is built from `debian:bookworm` with its
  own Dockerfile, config and entrypoint. No `latest` tags, no upstream app images.
- **Secrets stay out of images and git.** Passwords are mounted as files under
  `/run/secrets`; non-sensitive settings live in `.env`.
- **Idempotent bootstrap.** MariaDB and WordPress initialise only on first boot
  and detect existing data on restart, so state survives rebuilds.
- **Correct process model.** Each container `exec`s its real service as PID 1,
  so signals and shutdown behave properly.
- **Single entry point.** Only port 443 on NGINX is published. Services talk over
  a private bridge network using Docker DNS.
- **Persistent data** lives in named volumes bound to `~/data/{mariadb,wordpress}`.

## Requirements

- Linux host (or a VM) with Docker Engine and the Docker Compose plugin
- GNU Make
- `sudo` for the full clean target (removes host data directories)

## Quick start

1. Copy the example configuration and adjust it if needed:

   ```sh
   cp srcs/.env.example srcs/.env
   for f in secrets/*.example; do cp "$f" "${f%.example}"; done
   ```

   Put a real password in each `secrets/*.txt` file (one value, no trailing newline).
   The admin username must not contain `admin` or `administrator`.

2. Point the domain at your machine:

   ```sh
   echo "127.0.0.1 wordpress.local" | sudo tee -a /etc/hosts
   ```

3. Build and start:

   ```sh
   make
   ```

4. Open `https://wordpress.local` and accept the self-signed certificate.
   The admin panel is at `https://wordpress.local/wp-admin`.

## Make targets

| Target        | Effect                                                     |
| ------------- | ---------------------------------------------------------- |
| `make`/`up`   | Create data dirs, build images, start the stack detached   |
| `make down`   | Stop and remove containers                                 |
| `make clean`  | Also remove volumes                                        |
| `make fclean` | Also remove images and wipe `~/data/{mariadb,wordpress}`   |
| `make re`     | Full rebuild                                               |

## Project layout

```
.
├── Makefile
├── secrets/                  # *.txt ignored by git, *.example committed
└── srcs/
    ├── .env.example          # domain, DB name/user, WP title and users
    ├── docker-compose.yml
    └── requirements/
        ├── mariadb/   Dockerfile, conf/50-server.cnf, tools/init-db.sh
        ├── nginx/     Dockerfile, conf/nginx.conf,    tools/nginx-entry.sh
        └── wordpress/ Dockerfile, conf/www.conf,      tools/init-wp.sh
```

## How it works

**MariaDB** runs `mariadb-install-db` on an empty data directory, then uses
bootstrap mode to create the database, the application user and the root
password from the mounted secrets. On later starts it skips straight to
`mariadbd`.

**WordPress** waits for the database to answer `mariadb-admin ping`, then uses
WP-CLI to download core, write `wp-config.php`, install the site and create a
second (author) user. If `wp-config.php` already exists the whole step is skipped.
php-fpm listens on port 9000 inside the network.

**NGINX** renders its server block from a template using `DOMAIN_NAME`,
generates a self-signed certificate on first start, and proxies PHP requests to
the WordPress container over FastCGI. It serves only TLS on 443.

## Operations

```sh
docker ps                              # all three containers should be Up
docker logs nginx|wordpress|mariadb    # service output
docker exec -it wordpress sh           # shell into a container
curl -kI https://wordpress.local       # should return HTTP/1.1 200 or 302
docker exec -it mariadb mariadb -u root -p   # then: SHOW DATABASES;
```

## Design notes

**Secrets vs environment variables.** Environment variables show up in
`docker inspect`, process listings and child processes, so they are used here
only for non-sensitive configuration. Passwords are Docker secrets: mounted as
files, never baked into an image, and ignored by git.

**Bridge network vs host network.** A user-defined bridge gives the containers
a private subnet and name-based DNS, and exposes only published ports. Host
networking would be marginally faster but would expose every service directly.

**Named volumes with bind options.** The volumes are declared as named volumes
but bound to a known host path via `driver_opts`, so data is easy to find,
back up and wipe while still being managed through Compose.

## License

MIT, see [LICENSE](LICENSE).
