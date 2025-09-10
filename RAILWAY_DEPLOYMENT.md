# Railway Deployment Guide for AI Customer Support Chatbot

This guide provides step-by-step instructions for deploying the AI Customer Support Chatbot on Railway.

## Prerequisites

1. A Railway account (sign up at [railway.app](https://railway.app) using GitHub)
2. Google Gemini API key
3. Your project code in a GitHub repository

## Deployment Steps

### Step 1: Create a Railway Project

1. Log in to [Railway Dashboard](https://railway.app)
2. Click "New Project"
3. Select "Deploy from GitHub repo"
4. Find and select your `ai-customer-support-chatbot` repository
5. Name your project (e.g., "AI Customer Support Chatbot")

### Step 2: Deploy PostgreSQL Database

1. In your project dashboard, click "New Service" → "Database"
2. Select "PostgreSQL"
3. Wait for the database to provision

### Step 3: Initialize Database Schema

1. Once the PostgreSQL database is provisioned, click on it
2. Go to "Connect" → "SQL Console"
3. Copy the contents from `db-schema.sql` and execute it to create the necessary tables

### Step 4: Deploy Python AI Service

1. In your project dashboard, click "New Service" → "GitHub Repo"
2. Select your repository
3. Change settings:
   - Root Directory: `backend-python`
   - Builder: Dockerfile (will use the existing Dockerfile)
4. Click "Deploy"
5. Once deployed, add the required environment variables:
   - `GOOGLE_API_KEY` (your Gemini API key)
   - `GEMINI_MODEL=gemini-1.5-flash`
   - `HOST=0.0.0.0`
   - `PORT=$PORT` (Railway sets this automatically)
   - `PYTHONPATH=/workspace`
   - `PYTHONUNBUFFERED=1`

### Step 5: Deploy Java Backend Service

1. In your project dashboard, click "New Service" → "GitHub Repo"
2. Select your repository
3. Change settings:
   - Root Directory: `backend-java`
   - Builder: Dockerfile
4. Click "Deploy"
5. After deployment, set up environment variables linking to the database:
   - `SERVER_PORT=$PORT` (Railway sets this automatically)
   - `SPRING_DATASOURCE_URL=jdbc:postgresql://${{Postgres.PGHOST}}:${{Postgres.PGPORT}}/${{Postgres.PGDATABASE}}`
   - `SPRING_DATASOURCE_USERNAME=${{Postgres.PGUSER}}`
   - `SPRING_DATASOURCE_PASSWORD=${{Postgres.PGPASSWORD}}`
   - `AI_SERVICE_URL=https://your-python-service.up.railway.app` (use your actual Python service URL)
   - `JWT_SECRET` (a secure random string for token signing)
   - `JWT_EXPIRATION=86400000` (24 hours)
   - `JAVA_OPTS=-XX:+UseZGC -XX:+UnlockExperimentalVMOptions -Xmx512m`

### Step 6: Deploy Frontend

1. In your project dashboard, click "New Service" → "GitHub Repo"
2. Select your repository
3. Change settings:
   - Root Directory: `frontend`
   - Builder: Dockerfile
4. Click "Deploy"
5. Set environment variables:
   - `VITE_API_URL=https://your-java-backend.up.railway.app` (use your actual Java backend URL)

### Step 7: Configure CORS Settings

1. Go to your Python AI Service
2. Add/modify environment variable:

   ```env
   ALLOWED_ORIGINS=https://your-frontend.up.railway.app
   ```

3. Go to your Java Backend Service
4. Add/modify environment variable:

   ```env
   APP_CORS_ALLOWED_ORIGINS=https://your-frontend.up.railway.app
   ```

### Step 8: Enable Service Sleep for Free Tier

Each service in Railway has a `railway.json` file that includes `"sleepApplication": true`. This setting will make your services sleep when inactive, which helps save credits in Railway's free tier.

## Linking Services with Railway Variables

Railway allows using variables from one service in another using the `${{Service.VARIABLE}}` syntax. To link services:

1. Go to your Java backend service settings
2. Under "Variables", click "Add Variable"
3. Use "Reference" to link database variables:
   - Select your PostgreSQL service
   - Choose the variable you want to reference
   - Apply

## Monitoring and Troubleshooting

1. Each service has a "Logs" tab where you can see console output
2. Check the "Deployments" tab to see deployment history and errors
3. Use "Metrics" to monitor resource usage

## Custom Domain Setup (Optional)

1. Go to your frontend service
2. Click "Settings" → "Domains"
3. Add your custom domain and follow the DNS configuration instructions

## Saving Railway Credits

1. Enable "Scale to Zero" for all services (set in railway.json)
2. Use the Railway CLI to stop services when not in use:

   ```bash
   railway down
   ```

3. Restart services when needed:

   ```bash
   railway up
   ```

## Automating Deployment with GitHub Actions

1. Railway provides a GitHub Action that can be used to deploy your app when you push to your repository
2. Add the Railway token as a GitHub secret
3. Create a GitHub workflow file that uses the Railway action

For more information, refer to [Railway documentation](https://docs.railway.app)