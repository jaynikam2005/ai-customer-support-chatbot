# AI Customer Support Chatbot Deployment Guide

This comprehensive guide provides instructions for deploying the AI Customer Support Chatbot to various hosting platforms.

## Table of Contents

1. [Project Overview](#project-overview)
2. [Deployment Options](#deployment-options)
3. [Local Deployment with Docker Compose](#local-deployment-with-docker-compose)
4. [Cloud Deployment - All-in-One Docker Compose](#cloud-deployment---all-in-one-docker-compose)
5. [Cloud Deployment - Separate Services](#cloud-deployment---separate-services)
6. [Environment Variables Reference](#environment-variables-reference)
7. [Security Considerations](#security-considerations)
8. [Post-Deployment Verification](#post-deployment-verification)
9. [Troubleshooting](#troubleshooting)

## Project Overview

This project consists of four main components:

1. **Frontend**: React/TypeScript application built with Vite
2. **Java Backend**: Spring Boot application for user management and API
3. **Python AI Service**: FastAPI application for AI/ML operations
4. **PostgreSQL Database**: For storing users, conversations, and application data

## Deployment Options

### Quick Deployment Scripts

For convenience, the project includes deployment scripts:
- `deploy.sh` for Linux/Mac users
- `deploy.ps1` for Windows users

Run either script and follow the prompts to deploy locally or prepare for cloud deployment.

## Local Deployment with Docker Compose

### Prerequisites

1. Docker and Docker Compose installed
2. Git repository cloned

### Steps

1. Create a `.env` file in the project root (or copy from `.env.sample`)
2. Configure the Python AI service:
   ```bash
   cp backend-python/.env.sample backend-python/.env
   ```
3. Edit `backend-python/.env` to add your Google Gemini API key
4. Start all services:
   ```bash
   docker-compose up -d
   ```
5. Access the application at http://localhost:3000

## Cloud Deployment - All-in-One Docker Compose

For platforms that support Docker Compose (e.g., DigitalOcean App Platform, AWS ECS, etc.):

1. Fork or clone this repository
2. Configure the necessary environment variables for your cloud platform
3. Point your cloud platform to the docker-compose.yml file

### Required Environment Variables

See the [Environment Variables Reference](#environment-variables-reference) section below.

## Cloud Deployment - Separate Services

For deploying services individually to different platforms:

### Database Deployment

1. Create a PostgreSQL database using your preferred provider:
   - [Neon](https://neon.tech) (serverless PostgreSQL)
   - [Supabase](https://supabase.com) 
   - [Railway](https://railway.app)
   - [AWS RDS](https://aws.amazon.com/rds/)
   - [Azure Database for PostgreSQL](https://azure.microsoft.com/products/postgresql/)
   - [GCP Cloud SQL](https://cloud.google.com/sql)

2. Run the database migration script from `db-schema.sql`

3. Make note of the connection details (host, port, database name, username, password)

### Python AI Service Deployment

1. Deploy the Python AI service to a platform of your choice:
   
   #### Render
   ```
   1. Connect your GitHub repository to Render
   2. Create a new Web Service
   3. Select backend-python directory
   4. Set environment variables (see Backend-Python Variables section)
   5. Deploy
   ```

   #### Railway
   ```
   1. Connect your GitHub repository to Railway
   2. Create a new service pointing to backend-python
   3. Set environment variables
   4. Deploy
   ```

   #### Heroku
   ```
   1. heroku create ai-chatbot-python-service
   2. git subtree push --prefix backend-python heroku main
   3. Set environment variables through Heroku dashboard
   ```

   #### Fly.io
   ```
   1. Install flyctl
   2. cd backend-python
   3. fly launch
   4. Set environment variables
   5. fly deploy
   ```

2. Make note of the deployed URL for the Python AI service

### Java Backend Deployment

1. Deploy the Java backend to a platform of your choice:

   #### Render
   ```
   1. Connect your GitHub repository to Render
   2. Create a new Web Service
   3. Select backend-java directory
   4. Set environment variables including database and Python AI service URL
   5. Deploy
   ```

   #### Railway
   ```
   1. Connect your GitHub repository to Railway
   2. Create a new service pointing to backend-java
   3. Set environment variables
   4. Deploy
   ```

   #### Heroku
   ```
   1. heroku create ai-chatbot-java-backend
   2. git subtree push --prefix backend-java heroku main
   3. Set environment variables through Heroku dashboard
   ```

2. Make note of the deployed URL for the Java backend

### Frontend Deployment

1. Deploy the frontend to a platform of your choice:

   #### Vercel
   ```
   1. Connect your GitHub repository to Vercel
   2. Create a new project
   3. Configure the root directory as frontend
   4. Set VITE_API_URL to your Java backend URL
   5. Deploy
   ```

   #### Netlify
   ```
   1. Connect your GitHub repository to Netlify
   2. Set base directory to frontend
   3. Set build command to "npm run build"
   4. Set publish directory to "dist"
   5. Set environment variables
   6. Deploy
   ```

   #### GitHub Pages
   ```
   1. Update vite.config.ts to set the correct base path
   2. Add a GitHub workflow for deployment
   3. Configure environment variables
   4. Deploy
   ```

## Environment Variables Reference

### Root .env (for Docker Compose)

| Variable | Description | Default |
|----------|-------------|---------|
| POSTGRES_DB | PostgreSQL database name | chatbot |
| POSTGRES_USER | PostgreSQL username | chatbot_user |
| POSTGRES_PASSWORD | PostgreSQL password | chatbot_password |
| POSTGRES_PORT | PostgreSQL port | 5432 |
| PYTHON_PORT | Python service external port | 5000 |
| PORT | Python service internal port | 5000 |
| JAVA_PORT | Java backend external port | 8080 |
| SERVER_PORT | Java backend internal port | 8080 |
| FRONTEND_PORT | Frontend external port | 3000 |
| FRONTEND_CONTAINER_PORT | Frontend internal port | 3000 |
| VITE_API_URL | URL for the frontend to access the Java backend | http://localhost:8080 |
| ALLOWED_ORIGINS | CORS allowed origins (comma-separated) | http://localhost:3000,http://localhost:5173 |

### Python AI Service Variables

| Variable | Description | Required |
|----------|-------------|----------|
| GOOGLE_API_KEY | Google Gemini API key | Yes |
| GEMINI_MODEL | Gemini model name | Yes |
| HOST | Server host | No |
| PORT | Server port | No |
| ALLOWED_ORIGINS | CORS allowed origins | No |
| RESPONSE_CACHE_ENABLED | Enable response caching | No |
| RESPONSE_CACHE_TTL | Cache TTL in seconds | No |
| MAX_CACHE_ITEMS | Maximum cached items | No |

### Java Backend Variables

| Variable | Description | Required |
|----------|-------------|----------|
| SPRING_DATASOURCE_URL | JDBC URL for PostgreSQL | Yes |
| SPRING_DATASOURCE_USERNAME | Database username | Yes |
| SPRING_DATASOURCE_PASSWORD | Database password | Yes |
| AI_SERVICE_URL | URL to the Python AI service | Yes |
| SERVER_PORT | Server port | No |
| JWT_SECRET | Secret for JWT tokens | Yes (in production) |
| JWT_EXPIRATION | Token expiration in milliseconds | No |
| APP_CORS_ALLOWED_ORIGINS | CORS allowed origins | No |

### Frontend Variables

| Variable | Description | Required |
|----------|-------------|----------|
| VITE_API_URL | URL to the Java backend API | Yes |

## Security Considerations

### API Keys

1. Never commit API keys to the repository
2. Use environment variables for all sensitive information
3. Consider using a vault service for production deployments

### Database

1. Use strong, unique passwords
2. Restrict network access to the database
3. Enable SSL for database connections
4. Regularly backup your database

### JWT Security

1. Use a strong, random JWT secret in production
2. Set an appropriate expiration time for tokens
3. Consider implementing refresh tokens for long-lived sessions

### CORS Configuration

1. Restrict allowed origins to your frontend domains
2. Don't use wildcard (*) origins in production

## Post-Deployment Verification

After deployment, verify:

1. User registration and login functionality
2. Chat messages are being sent and received
3. AI responses are being generated correctly
4. Response caching is working (subsequent similar questions should be faster)

## Troubleshooting

### Common Issues

1. **Connection errors between services**
   - Check that services can reach each other
   - Verify URLs and ports are correctly configured

2. **Database connection failures**
   - Verify database credentials and connection string
   - Check network connectivity and firewall settings

3. **API key issues**
   - Verify Google Gemini API key is valid and has sufficient quota
   - Check that the key is correctly set in environment variables

4. **CORS errors**
   - Ensure frontend domain is in the allowed origins list
   - Check for protocol mismatches (http vs https)

### Logs

- View Docker container logs:
  ```bash
  docker-compose logs -f [service_name]
  ```

- Check platform-specific logs in your cloud provider's dashboard