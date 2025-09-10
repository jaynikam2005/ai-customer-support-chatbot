# Frontend Deployment to Vercel

This document provides instructions for deploying the AI Customer Support Chatbot frontend to Vercel.

## Prerequisites

1. A [Vercel](https://vercel.com) account
2. The [Vercel CLI](https://vercel.com/docs/cli) installed locally (optional for direct deployment)
3. Backend services already deployed and accessible via public URLs

## Deployment Steps

### Option 1: Direct Deployment via GitHub

1. Fork or push this repository to GitHub
2. Log in to your Vercel account
3. Click "Add New Project"
4. Import your GitHub repository
5. Configure the project:
   - Framework Preset: Vite
   - Root Directory: `frontend`
   - Build Command: `npm run build`
   - Output Directory: `dist`
6. Add environment variables:
   - `VITE_API_URL`: The URL to your deployed Java backend API
7. Click "Deploy"

### Option 2: Using Vercel CLI

1. Install Vercel CLI: `npm i -g vercel`
2. Navigate to the frontend directory: `cd frontend`
3. Login to Vercel: `vercel login`
4. Deploy with configuration: `vercel --prod`
5. When prompted, configure:
   - Project path: `./`
   - Link to existing project: Choose your project or create new
   - Environment variables: Add `VITE_API_URL` when prompted

## Environment Variables

| Variable Name | Description | Example |
|---------------|-------------|---------|
| VITE_API_URL | URL to your Java backend API | https://your-backend-api.com |

## Post-Deployment Verification

After deployment:

1. Visit your Vercel deployment URL
2. Verify that the application loads correctly
3. Test authentication flow
4. Test chat functionality
5. Check that API connections to backend services work properly

## Troubleshooting

If you encounter issues:

1. Check the API URL configuration
2. Verify CORS settings on your backend
3. Check Vercel's deployment logs
4. Test locally with the same environment variables