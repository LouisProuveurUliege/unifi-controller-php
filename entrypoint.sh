#! /bin/sh

set -e

php artisan config:clear

echo "Waiting for MySQL at $DB_HOST:$DB_PORT..."

while ! php -r "new PDO('mysql:host=$DB_HOST;port=$DB_PORT', getenv('DB_USERNAME'), getenv('DB_PASSWORD'));" 2>/dev/null; do
    echo "Database not ready yet... sleeping 2s"
    sleep 2
done

echo "Database is ready!"

php artisan migrate
php artisan vendor:publish --provider="ImperianSystems\UnifiController\UnifiControllerProvider" --tag="config"

sed -i 's/^\(.*auth:api.*\)$/\/\/ \1/' "config/unifi-controller.php"

php artisan serve --host=[0.0.0.0]
