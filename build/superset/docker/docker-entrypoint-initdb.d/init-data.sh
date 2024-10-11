#!/bin/bash
set -e;

if [ -n "${POSTGRES_NON_ROOT_USER:-}" ] && [ -n "${POSTGRES_NON_ROOT_PASSWORD:-}" ]; then
    if [ -n "${POSTGRES_NON_ROOT_DB:-}" ]; then
        psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
            -- Create the database if it doesn't exist
            DO \$\$
            BEGIN
                IF NOT EXISTS (SELECT FROM pg_database WHERE datname = '${POSTGRES_NON_ROOT_DB}') THEN
                    CREATE DATABASE ${POSTGRES_NON_ROOT_DB};
                END IF;
            END
            \$\$;

            -- Create user and grant privileges
            CREATE USER ${POSTGRES_NON_ROOT_USER} WITH PASSWORD '${POSTGRES_NON_ROOT_PASSWORD}';
            GRANT ALL PRIVILEGES ON DATABASE ${POSTGRES_NON_ROOT_DB} TO ${POSTGRES_NON_ROOT_USER};
            GRANT CREATE ON SCHEMA public TO ${POSTGRES_NON_ROOT_USER};
        EOSQL
    else
        echo "SETUP INFO: No database name provided in POSTGRES_NON_ROOT_DB!"
    fi
else
    echo "SETUP INFO: No Environment variables for user or password!"
fi
