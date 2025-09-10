# PostgreSQL Database Deployment Guide

This document provides instructions for deploying and managing the PostgreSQL database for the AI Customer Support Chatbot.

## Option 1: Managed PostgreSQL Services

### Neon (Serverless PostgreSQL)

1. Sign up for [Neon](https://neon.tech)
2. Create a new project
3. Create a new database named "chatbot"
4. Create a role with username "chatbot_user" (or your preferred name)
5. Set a secure password
6. Copy the connection string from the Neon dashboard
7. Use the connection string in your backend service environment variables

### Supabase

1. Sign up for [Supabase](https://supabase.com)
2. Create a new project
3. Go to the SQL Editor
4. Run the schema SQL from the db-schema.sql file in your repository
5. Get the connection details from Settings > Database
6. Use these details in your backend service environment variables

### Railway PostgreSQL

1. Sign up for [Railway](https://railway.app)
2. Create a new project
3. Add a PostgreSQL database service
4. Once created, view the "Connect" tab for connection details
5. Run the schema SQL from your db-schema.sql file in the Railway database console
6. Use the provided connection details in your backend service environment variables

## Option 2: Self-Hosted with Docker

You can use the existing PostgreSQL container configuration from your docker-compose.yml:

1. Set up a server with Docker installed
2. Create a directory for persistent data storage
3. Create a docker-compose.yml file:

```yaml
version: '3'

services:
  postgres:
    image: postgres:16
    container_name: chatbot-postgres
    environment:
      POSTGRES_DB: chatbot
      POSTGRES_USER: chatbot_user
      POSTGRES_PASSWORD: your_secure_password  # Change this!
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./db-schema.sql:/docker-entrypoint-initdb.d/init.sql
    restart: always

volumes:
  postgres_data:
```

4. Start the database: `docker compose up -d`
5. Configure your backend to connect to this database

## Required Database Permissions

The database user needs the following permissions:

```sql
-- Create a dedicated user (if not using a managed service that does this)
CREATE USER chatbot_user WITH PASSWORD 'your_secure_password';

-- Grant privileges
GRANT CONNECT ON DATABASE chatbot TO chatbot_user;
GRANT USAGE ON SCHEMA public TO chatbot_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO chatbot_user;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO chatbot_user;

-- Make sure new tables will have the same grants
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO chatbot_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT USAGE, SELECT ON SEQUENCES TO chatbot_user;
```

## Security Considerations

1. **Never** use the default "postgres" user in production
2. Use strong, unique passwords
3. Restrict IP access to the database when possible
4. Enable SSL connections for all database traffic
5. Back up your database regularly
6. Do not expose your database port (5432) directly to the internet
7. Store database credentials securely as environment variables

## Migrating Data Between Environments

When moving from development to production:

1. Export your schema: 
   ```
   pg_dump -U chatbot_user -d chatbot --schema-only > schema.sql
   ```

2. Export your data (if needed):
   ```
   pg_dump -U chatbot_user -d chatbot --data-only > data.sql
   ```

3. Import to the new database:
   ```
   psql -U chatbot_user -d chatbot -f schema.sql
   psql -U chatbot_user -d chatbot -f data.sql
   ```

## Connection Strings

For the Java backend, use the following format in your environment variables:

```
SPRING_DATASOURCE_URL=jdbc:postgresql://hostname:5432/chatbot
SPRING_DATASOURCE_USERNAME=chatbot_user
SPRING_DATASOURCE_PASSWORD=your_secure_password
```

Replace `hostname`, `chatbot_user`, and `your_secure_password` with your actual database details.