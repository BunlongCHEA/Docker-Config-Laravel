#!/bin/sh

# Wait for PostgreSQL to be ready
echo "Waiting for PostgreSQL..."
until nc -z postgres 5432; do
  sleep 2
done
echo "PostgreSQL is up - running migrations"

# Run migrations
php artisan migrate --force

# Create storage symlink
#php artisan storage:link

# Set correct permissions for storage and bootstrap cache
#chmod -R 775 storage bootstrap/cache
#chown -R www-data:www-data storage bootstrap/cache

# Check if public/storage exists, if not, create the symlink
if [ ! -d "/var/www/html/public/storage" ]; then
    echo "Creating storage symlink... ./public/storage"
    php artisan storage:link
    # Set correct permissions for storage and bootstrap cache
    chmod -R 775 storage bootstrap/cache
    chown -R www-data:www-data storage bootstrap/cache
else
    echo "Storage symlink already exists. Skipping."
fi

# Start PHP-FPM
php-fpm
