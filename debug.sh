#!/bin/bash

DB_CONTAINER_NAME='db_1'
MATOMO_CONTAINER_NAME='app_1'
DB_USER='matomo'
DB_NAME='matomo'

execute_in_db_container() {
    docker exec -it $DB_CONTAINER_NAME bash -c "$1"
}

echo "Checking if Docker containers are running..."
if ! docker ps | grep -q $DB_CONTAINER_NAME; then
    echo "Database container ($DB_CONTAINER_NAME) is not running."
    exit 1
else
    echo "Database container is running."
fi

if ! docker ps | grep -q $MATOMO_CONTAINER_NAME; then
    echo "Matomo container ($MATOMO_CONTAINER_NAME) is not running."
    exit 1
else
    echo "Matomo container is running."
fi

echo "Checking database user permissions for '$DB_USER'..."
USER_PRIVILEGES=$(execute_in_db_container "mysql -uroot -p\$MYSQL_ROOT_PASSWORD -e 'SHOW GRANTS FOR \"$DB_USER\"@\"%\";'")
echo "Privileges for $DB_USER: "
echo "$USER_PRIVILEGES"

echo "Testing database connection for user '$DB_USER'..."
CONNECTION_TEST=$(execute_in_db_container "mysql -u$DB_USER -p\$MATOMO_DATABASE_PASSWORD -e 'SHOW DATABASES LIKE \"$DB_NAME\";'")
if [[ "$CONNECTION_TEST" == *"$DB_NAME"* ]]; then
    echo "Connection test successful. $DB_USER can connect to the $DB_NAME database."
else
    echo "Connection test failed. $DB_USER cannot connect to the $DB_NAME database."
fi

echo "Script completed."
