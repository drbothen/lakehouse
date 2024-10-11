#!/bin/bash
set -e;

# Check if the environment variables POSTGRES_NON_ROOT_USER and POSTGRES_NON_ROOT_PASSWORD are set.
if [ -n "${POSTGRES_NON_ROOT_USER:-}" ] && [ -n "${POSTGRES_NON_ROOT_PASSWORD:-}" ]; then
    if [ -n "${POSTGRES_NON_ROOT_DB:-}" ]; then
        # Check if the database already exists. If not, create it.
        if ! psql -U "$POSTGRES_USER" -tAc "SELECT 1 FROM pg_database WHERE datname='${POSTGRES_NON_ROOT_DB}'" | grep -q 1; then
            psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<EOSQL
                CREATE DATABASE ${POSTGRES_NON_ROOT_DB};
EOSQL
        fi

        # Create the user and grant privileges on the database.
        psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<EOSQL
            CREATE USER ${POSTGRES_NON_ROOT_USER} WITH PASSWORD '${POSTGRES_NON_ROOT_PASSWORD}';
            GRANT ALL PRIVILEGES ON DATABASE ${POSTGRES_NON_ROOT_DB} TO ${POSTGRES_NON_ROOT_USER};
EOSQL

        # Connect to the created database and grant schema privileges.
        psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" -d "${POSTGRES_NON_ROOT_DB}" <<EOSQL
            GRANT CREATE ON SCHEMA public TO ${POSTGRES_NON_ROOT_USER};
EOSQL
    else
        echo "SETUP INFO: No database name provided in POSTGRES_NON_ROOT_DB!"
    fi
else
    echo "SETUP INFO: No Environment variables for user or password!"
fi
