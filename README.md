# Create Admin User With Command Console

After start docker, you need to create admin role to allow access all function, **app** is service name you define

    docker-compose exec app php artisan app:create-admin-user

# Modify .env For Config Database, Redis, Main, AWS, etc

You can modify to use .env for changing environment to the Laravel project without need to access Docker Container - app - 

But the .env config must also the same to what you install Postgres Environment like username, password, etc.

    DB_CONNECTION=pgsql
    DB_HOST=postgres
    DB_PORT=5432
    DB_DATABASE=cuisine
    DB_USERNAME=admins
    DB_PASSWORD=admin12345

# Docker Compose For Multiple Docker Container

    nano docker-compose.yaml
    
Add this content:

    version: "3.8"
    services:
      app:
        image: cbunlong/laravel_order_cuisine:v1.0
        container_name: order_cuisine
        restart: always
        volumes:
          - ./docker-entrypoint.sh:/var/www/html/docker-entrypoint.sh
          - storage_volume:/var/www/html/storage    #Share storage folder
        depends_on:
          - postgres
        networks:
          - laravel_network
        env_file:
          - .env
        entrypoint: ["/bin/sh", "/var/www/html/docker-entrypoint.sh"]
      postgres:
        image: postgres:latest
        container_name: postgres_db
        restart: always
        environment:
          POSTGRES_USER: admins
          POSTGRES_PASSWORD: admin12345
          POSTGRES_DB: cuisine
        ports:
          - "5432:5432"
        volumes:
          - /etc/postgres/data:/var/lib/postgresql/data
        networks:
          - laravel_network
      nginx:
        image: nginx:latest
        container_name: nginx_server
        restart: always
        ports:
          - "80:80"
        volumes:
          - ./nginx/default.conf:/etc/nginx/conf.d/default.conf
          - storage_volume:/var/www/html/storage    #Share storage with Nginx
        depends_on:
          - app
        networks:
          - laravel_network
    networks:
      laravel_network:
        driver: bridge
    #Define the shared volume for storage
    volumes:
      storage_volume:

# Docker Entrypoint To Start Laravel Project

Add docker entrypoint allow custom configuration to before starting laravel application, like waiting database up, migrating data, creating symbol link-name, etc

    nano docker-entrypoint.sh

Add this content

    #!/bin/sh
    
    # Wait for PostgreSQL to be ready
    echo "Waiting for PostgreSQL..."
    until nc -z postgres 5432; do
      sleep 2
    done
    echo "PostgreSQL is up - running migrations"
    
    # Run migrations
    php artisan migrate --force
    
    # Check if public/storage exists, if not, create the symlink
    if [ ! -d "/var/www/html/public/storage" ]; then
        echo "Creating storage symlink... ./public/storage"
        php artisan storage:link
        # Set correct permissions for storage and bootstrap cache
        chmod -R 777 storage bootstrap/cache
        chown -R www-data:www-data storage bootstrap/cache
    else
        echo "Storage symlink already exists. Skipping."
    fi
    
    # Start PHP-FPM
    php-fpm

# Nginx To Host Application

Config allow to host application and handle request depend configuration, ex: handle upload and find located images to display to USER

    mkdir nginx
    nano default.conf

Add this content

    server {
        listen 80;
        server_name localhost;
    
        root /var/www/html/public;
        index index.php index.html index.htm;
    
        location / {
            try_files $uri $uri/ /index.php?$query_string;
        }
    
        #Handles requests for /storage/ URLs as Nginx will look for images in /var/www/html/storage/app/public/images/
        location /storage {
            #Alias to map /storage/ to /var/www/html/storage/app/public/
            alias /var/www/html/storage/app/public;
            #Disables access logs for performance
            access_log off;
            #Prevents logging missing file errors
            log_not_found off;
            expires 30d;
            #If the requested file exists, serve it; if not, return 404 Not Found
            try_files $uri $uri/ =404;
        }
    
        location ~ \.php$ {
            include fastcgi_params;
            fastcgi_pass app:9000;
            fastcgi_index index.php;
            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        }
    }

# Start Application 

Build and start application with docker compose

    docker-compose up -d --build

Check status application after start

    docker-compose ps

To also check time create and how long is it running

    docker compose ps

Login inside container of application

    docker exec -it <container-name> bash

Stop application

    docker-compose down -v

Remove all unused containers, networks

    docker system prune

OR even remove images (both dangling and unused)

    docker system prune -a
