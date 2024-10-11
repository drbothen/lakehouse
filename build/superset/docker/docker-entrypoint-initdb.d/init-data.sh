#!/bin/bash
set -e;

# This script is used to create a PostgreSQL user and database (if not exists), and grant necessary permissions.
# It is intended to be run during the PostgreSQL container initialization, typically placed in docker-entrypoint-initdb.d.

# Check if the environment variables POSTGRES_NON_ROOT_USER and POSTGRES_NON_ROOT_PASSWORD are set.
# These variables are required to create a new non-root user in PostgreSQL.
# - POSTGRES_NON_ROOT_USER: The name of the new non-root user to create.
# - POSTGRES_NON_ROOT_PASSWORD: The password for the new non-root user.
# - POSTGRES_NON_ROOT_DB: Optional. The name of the database to create and grant the non-root user access to.
if [ -n "${POSTGRES_NON_ROOT_USER:-}" ] && [ -n "${POSTGRES_NON_ROOT_PASSWORD:-}" ]; then
    # Check if the POSTGRES_NON_ROOT_DB environment variable is set, which will be used to create a database.
    if [ -n "${POSTGRES_NON_ROOT_DB:-}" ]; then
        # Execute the SQL commands in the PostgreSQL database using psql
        # -v ON_ERROR_STOP=1: Stop execution on any SQL error.
        # --username "$POSTGRES_USER": Connect as the PostgreSQL superuser (typically 'postgres').
        # --dbname "$POSTGRES_DB": Connect to the default database defined by the POSTGRES_DB environment variable.
        psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
            -- Create the database if it doesn't exist.
            -- This block checks if the database defined by POSTGRES_NON_ROOT_DB exists, and creates it if it does not.
            DO \$\$
            BEGIN
                IF NOT EXISTS (SELECT FROM pg_database WHERE datname = '${POSTGRES_NON_ROOT_DB}') THEN
                    CREATE DATABASE ${POSTGRES_NON_ROOT_DB};
                END IF;
            END
            \$\$;

            -- Create a new PostgreSQL user with the provided username and password.
            -- This creates the user defined by POSTGRES_NON_ROOT_USER with the password from POSTGRES_NON_ROOT_PASSWORD.
            CREATE USER ${POSTGRES_NON_ROOT_USER} WITH PASSWORD '${POSTGRES_NON_ROOT_PASSWORD}';

            -- Grant all privileges on the newly created or existing database to the non-root user.
            -- This ensures the new user has full access to the database defined by POSTGRES_NON_ROOT_DB.
            GRANT ALL PRIVILEGES ON DATABASE ${POSTGRES_NON_ROOT_DB} TO ${POSTGRES_NON_ROOT_USER};

            -- Grant the CREATE privilege on the 'public' schema to the non-root user.
            -- This allows the user to create objects like tables in the public schema.
            GRANT CREATE ON SCHEMA public TO ${POSTGRES_NON_ROOT_USER};
        EOSQL
    else
        # If POSTGRES_NON_ROOT_DB is not set, print an informational message.
        echo "SETUP INFO: No database name provided in POSTGRES_NON_ROOT_DB!"
    fi
else
    # If either POSTGRES_NON_ROOT_USER or POSTGRES_NON_ROOT_PASSWORD is not set, print an informational message.
    echo "SETUP INFO: No Environment variables for user or password!"
fi
