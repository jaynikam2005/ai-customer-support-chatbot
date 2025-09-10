# CI/CD Workflow Setup Guide

This document explains how to configure the GitHub Actions workflows for automated deployment.

## Required Repository Secrets

To enable the automated deployment, you'll need to add the following secrets in your GitHub repository (Settings > Secrets and variables > Actions):

### Vercel Deployment (Frontend)
- `VERCEL_TOKEN`: Your Vercel API token
- `VERCEL_ORG_ID`: Your Vercel organization ID
- `VERCEL_PROJECT_ID`: Your Vercel project ID for the frontend
- `BACKEND_API_URL`: The URL to your deployed Java backend

### Database Connection
- `POSTGRES_URL`: JDBC connection URL for your PostgreSQL database
- `POSTGRES_USER`: Database username
- `POSTGRES_PASSWORD`: Database password

### AI Service
- `GEMINI_API_KEY`: Your Google Gemini API key
- `AI_SERVICE_URL`: The URL to your deployed Python AI service

### Deployment Platform Credentials

#### For Railway
- `RAILWAY_TOKEN`: Your Railway API token

#### For Heroku
- `HEROKU_API_KEY`: Your Heroku API key
- `HEROKU_EMAIL`: Your Heroku account email

## Required Repository Variables

In addition to secrets, configure the following repository variables to control deployment targets:

- `BACKEND_DEPLOY_TARGET`: Set to either `railway` or `heroku`
- `PYTHON_DEPLOY_TARGET`: Set to either `railway` or `heroku`
- `RAILWAY_JAVA_SERVICE_NAME`: The name of your Java service on Railway
- `RAILWAY_PYTHON_SERVICE_NAME`: The name of your Python service on Railway
- `HEROKU_JAVA_APP_NAME`: The name of your Java app on Heroku
- `HEROKU_PYTHON_APP_NAME`: The name of your Python app on Heroku

## How to Obtain Required Credentials

### Vercel
1. Log in to [Vercel](https://vercel.com)
2. Go to Settings > Tokens to create an API token
3. Get your Organization ID and Project ID from your project settings

### Railway
1. Log in to [Railway](https://railway.app)
2. Go to Account Settings > Developer > API Keys to generate a token

### Heroku
1. Log in to [Heroku](https://heroku.com)
2. Go to Account Settings > API Key to reveal your API key

### Google Gemini
1. Go to [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Create an API key for Gemini

## Required Permissions

1. **GitHub Repository**:
   - Write access to the repository for GitHub Actions
   
2. **Vercel**:
   - Deploy permissions through Vercel token
   
3. **Railway/Heroku**:
   - Permission to deploy and manage applications
   - Permission to set environment variables
   
4. **Database**:
   - Connection permissions as outlined in the database deployment guide

## Workflow Customization

You can customize the deployment workflow by:

1. Editing `.github/workflows/deployment.yml` to add additional steps
2. Modifying environment variables or secrets as needed
3. Adding additional deployment targets

## Manually Triggering Deployment

You can manually trigger the workflow by:

1. Going to the Actions tab in your GitHub repository
2. Selecting the "Deploy AI Customer Support Chatbot" workflow
3. Clicking "Run workflow"
4. Selecting the branch to deploy from