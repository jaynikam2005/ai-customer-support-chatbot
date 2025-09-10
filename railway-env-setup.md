# Railway Environment Variables Setup

This document provides guidance on setting up environment variables for deploying the AI Customer Support Chatbot on Railway.

## PostgreSQL Database Service

When creating a PostgreSQL database service on Railway, the following environment variables will be automatically provided:

- `DATABASE_URL` - Full PostgreSQL connection URL
- `PGHOST` - PostgreSQL host
- `PGPORT` - PostgreSQL port
- `PGUSER` - PostgreSQL username
- `PGPASSWORD` - PostgreSQL password
- `PGDATABASE` - PostgreSQL database name

## Python AI Service Environment Variables

Set these variables for the Python backend service:

| Variable | Description | Example |
|----------|-------------|---------|
| `GOOGLE_API_KEY` | Your Google Gemini API key | `AIzaSyXXXXXXXXX...` |
| `GEMINI_MODEL` | Gemini model to use | `gemini-1.5-flash` |
| `HOST` | Host to bind to | `0.0.0.0` |
| `PORT` | Port to listen on (set automatically by Railway) | `$PORT` |
| `ALLOWED_ORIGINS` | Comma-separated list of allowed frontend origins | `https://frontend-service.up.railway.app` |
| `PYTHONPATH` | Python module path | `/workspace` |
| `PYTHONUNBUFFERED` | Disable Python output buffering | `1` |

## Java Backend Environment Variables

Set these variables for the Java backend service:

| Variable | Description | Example |
|----------|-------------|---------|
| `SERVER_PORT` | Port for Spring Boot to listen on | `$PORT` (Railway provided) |
| `SPRING_DATASOURCE_URL` | JDBC URL for PostgreSQL | `jdbc:postgresql://$PGHOST:$PGPORT/$PGDATABASE` |
| `SPRING_DATASOURCE_USERNAME` | Database username | `$PGUSER` |
| `SPRING_DATASOURCE_PASSWORD` | Database password | `$PGPASSWORD` |
| `AI_SERVICE_URL` | URL to the Python AI service | `https://python-service.up.railway.app` |
| `APP_CORS_ALLOWED_ORIGINS` | Comma-separated list of allowed frontend origins | `https://frontend-service.up.railway.app` |
| `JWT_SECRET` | Secret for JWT token generation | `[random secure string]` |
| `JWT_EXPIRATION` | JWT expiration time in milliseconds | `86400000` |
| `JAVA_OPTS` | JVM options | `-XX:+UseZGC -XX:+UnlockExperimentalVMOptions -Xmx512m` |

## Frontend Environment Variables

Set these variables for the frontend service:

| Variable | Description | Example |
|----------|-------------|---------|
| `VITE_API_URL` | URL to the Java backend service | `https://java-backend.up.railway.app` |
| `PORT` | Port for the frontend server to listen on (set automatically by Railway) | `$PORT` |

## Important Notes

1. Railway automatically assigns a `PORT` variable to your service, which your application must use instead of a hardcoded port.

2. When connecting services, you'll need to use the Railway-provided domain names rather than internal Docker network names.

3. Use Railway's built-in environment variable sharing functionality to avoid manually copying database credentials.

4. For sensitive values like API keys and JWT secrets, use Railway's secret management features.

5. The `sleepApplication` setting in railway.json files will make your services sleep when inactive, saving credits in the free tier.