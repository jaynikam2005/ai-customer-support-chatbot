# Python AI Service Deployment Guide

This document provides instructions for deploying the Python AI service to cloud platforms.

## Option 1: Deploy to Render

### Prerequisites

1. A [Render](https://render.com) account
2. Your repository connected to Render

### Deployment Steps

1. Log in to Render and click "New Web Service"
2. Connect your repository
3. Configure the service:
   - Name: `ai-chatbot-python-service`
   - Root Directory: `backend-python`
   - Runtime: `Docker`
   - Branch: `main`
   - Build Command: `(leave blank - using Dockerfile)`
   - Start Command: `(leave blank - using Dockerfile)`
   
4. Add environment variables (check your .env file for necessary variables):
   - Add your API keys for any AI/LLM services
   - Add database connection information if needed
   
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
   - Root Directory: `backend-python`
   - Service Name: `python-ai-service`
   
4. Add all environment variables from your .env file:
   - AI service API keys
   - Other configuration variables
   
5. Deploy the service

## Option 3: Deploy to Heroku

### Prerequisites

1. A [Heroku](https://heroku.com) account
2. Heroku CLI installed

### Deployment Steps

1. Log in to Heroku CLI: `heroku login`
2. Navigate to the Python backend directory: `cd backend-python`
3. Create a new Heroku app: `heroku create ai-chatbot-python-service`
4. Set up environment variables (from your .env file):
   ```bash
   heroku config:set GEMINI_API_KEY=your_api_key
   # Add all other needed environment variables
   ```
5. Create a `Procfile` in the backend-python directory with:
   ```
   web: cd app && gunicorn main:app
   ```
6. Deploy the application: `git subtree push --prefix backend-python heroku main`

## Required API Keys and Permissions

For the Python AI service to function, you will need to set up:

1. **Google Gemini API**
   - Create an API key at Google AI Studio: https://makersuite.google.com/app/apikey
   - Set as `GEMINI_API_KEY` environment variable

2. **Environment Access**:
   - Read access to environment variables
   - Network access for inbound connections from the Java backend
   - Outbound network access to connect to external AI APIs

3. **Platform Permissions**:
   - Permission to create and manage web services
   - Permission to set environment variables
   - Access to deployment logs
   - Sufficient memory allocation (512MB minimum recommended)

## Verifying Deployment

After deployment:

1. Check the health endpoint: `/health`
2. Test a basic AI request to verify API connectivity
3. Check logs for any startup errors or API connection issues

## Security Considerations

For securing your API keys and services:

1. Never commit API keys to your repository
2. Use environment variables for all sensitive information
3. Configure proper CORS settings to restrict access
4. Consider adding rate limiting for production deployments