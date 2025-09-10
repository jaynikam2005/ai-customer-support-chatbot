# Java Backend Deployment Guide

This document provides instructions for deploying the Java backend service to cloud platforms.

## Option 1: Deploy to Render

### Prerequisites
1. A [Render](https://render.com) account
2. Your repository connected to Render

### Deployment Steps

1. Log in to Render and click "New Web Service"
2. Connect your repository
3. Configure the service:
   - Name: `ai-chatbot-java-backend`
   - Root Directory: `backend-java`
   - Runtime: `Docker`
   - Branch: `main`
   - Build Command: `(leave blank - using Dockerfile)`
   - Start Command: `(leave blank - using Dockerfile)`
   
4. Add environment variables:
   - `SPRING_DATASOURCE_URL`: JDBC URL to your PostgreSQL database
   - `SPRING_DATASOURCE_USERNAME`: Database username
   - `SPRING_DATASOURCE_PASSWORD`: Database password
   - `AI_SERVICE_URL`: URL to your deployed Python AI service
   
5. Click "Create Web Service"

## Option 2: Deploy to Railway

### Prerequisites
1. A [Railway](https://railway.app) account
2. Railway CLI installed (optional)

### Deployment Steps

1. Log in to Railway and click "New Project"
2. Select "Deploy from GitHub repo"
3. Configure the service:
   - Repository: Select your repository
   - Root Directory: `backend-java`
   - Service Name: `java-backend`
   
4. Add environment variables:
   - `SPRING_DATASOURCE_URL`: JDBC URL to your PostgreSQL database
   - `SPRING_DATASOURCE_USERNAME`: Database username
   - `SPRING_DATASOURCE_PASSWORD`: Database password
   - `AI_SERVICE_URL`: URL to your deployed Python AI service
   
5. Deploy the service

## Option 3: Deploy to Heroku

### Prerequisites
1. A [Heroku](https://heroku.com) account
2. Heroku CLI installed

### Deployment Steps

1. Log in to Heroku CLI: `heroku login`
2. Navigate to the Java backend directory: `cd backend-java`
3. Create a new Heroku app: `heroku create ai-chatbot-java-backend`
4. Add a `system.properties` file to specify Java version:
   ```
   java.runtime.version=21
   ```
5. Set up environment variables:
   ```
   heroku config:set SPRING_DATASOURCE_URL=jdbc:postgresql://your-db-host:5432/chatbot
   heroku config:set SPRING_DATASOURCE_USERNAME=your_username
   heroku config:set SPRING_DATASOURCE_PASSWORD=your_password
   heroku config:set AI_SERVICE_URL=https://your-python-service-url
   ```
6. Deploy the application: `git subtree push --prefix backend-java heroku main`

## Required Permissions

To deploy this service, you will need:

1. **Database Permissions**:
   - CREATE, SELECT, INSERT, UPDATE, DELETE on all tables
   - CONNECT permission on the database
   
2. **Environment Access**:
   - Read access to environment variables
   - Network access to connect to the Python AI service
   - Network access for inbound connections from the frontend
   
3. **Platform Permissions**:
   - Permission to create and manage web services
   - Permission to set environment variables
   - Access to deployment logs

## Verifying Deployment

After deployment:

1. Check the health endpoint: `/actuator/health`
2. Verify database connectivity
3. Test API endpoints using a tool like Postman
4. Check logs for any startup errors