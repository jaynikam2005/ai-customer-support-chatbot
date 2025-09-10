# Deploying AI Customer Support Chatbot on Render

This guide will walk you through the process of deploying the AI Customer Support Chatbot on [Render](https://render.com).

## Prerequisites

1. A [Render](https://render.com) account
2. Your code pushed to a GitHub repository
3. Google Gemini API key (you already have: AIzaSyBws4xBo1bGCF3Tecqc68FBP44VhcnYY7E)

## Deployment Steps

### Step 1: Fork/Push the Repository

Ensure your codebase is available on GitHub, as Render will deploy directly from your repository.

### Step 2: Deploy with Blueprint (Recommended)

The easiest way to deploy all services is using the `render.yaml` blueprint we've created:

1. Log in to your [Render Dashboard](https://dashboard.render.com)
2. Click "New" and select "Blueprint"
3. Connect your GitHub repository
4. Select the repository containing your AI Customer Support Chatbot
5. Render will automatically detect the `render.yaml` file
6. Review the services that will be created:
   - `chatbot-db`: PostgreSQL database
   - `chatbot-java-api`: Java Spring Boot backend
   - `chatbot-python-ai`: Python FastAPI AI service
   - `chatbot-frontend`: React frontend
7. Click "Apply" to start the deployment

Render will now create and deploy all services according to the blueprint. This may take a few minutes.

### Step 3: Manual Deployment (Alternative)

If you prefer to deploy services manually or need more control:

#### 3.1 Deploy PostgreSQL Database

1. From your Render Dashboard, click "New" → "PostgreSQL"
2. Configure your database:
   - Name: `chatbot-db`
   - Database: `chatbot`
   - User: `chatbot_user`
   - Select your preferred region
3. Click "Create Database"
4. Note the internal Database URL, you'll need this for the Java backend

Once created, initialize the database:
1. Go to the database dashboard
2. Navigate to "Shell" tab
3. Paste and execute the contents of `db-schema.sql`

#### 3.2 Deploy Java Backend

1. From your Render Dashboard, click "New" → "Web Service"
2. Connect your GitHub repository
3. Configure the service:
   - Name: `chatbot-java-api`
   - Environment: "Docker"
   - Root Directory: `backend-java`
   - Health Check Path: `/actuator/health`
4. Add the following environment variables:
   - `SPRING_DATASOURCE_URL`: The Render-provided PostgreSQL connection string
   - `SPRING_DATASOURCE_USERNAME`: `chatbot_user`
   - `SPRING_DATASOURCE_PASSWORD`: Your database password
   - `JWT_SECRET`: Generate a secure random string
   - `JWT_EXPIRATION`: `86400000`
   - `JAVA_OPTS`: `-Xmx512m -Xms128m`
5. Click "Create Web Service"

#### 3.3 Deploy Python AI Service

1. From your Render Dashboard, click "New" → "Web Service"
2. Connect your GitHub repository
3. Configure the service:
   - Name: `chatbot-python-ai`
   - Environment: "Docker"
   - Root Directory: `backend-python`
   - Health Check Path: `/health`
4. Add the following environment variables:
   - `GOOGLE_API_KEY`: Your Google Gemini API key
   - `GEMINI_MODEL`: `gemini-1.5-flash`
   - `HOST`: `0.0.0.0`
   - `PYTHONUNBUFFERED`: `1`
   - `PYTHONPATH`: `/workspace`
5. Click "Create Web Service"

#### 3.4 Deploy Frontend

1. From your Render Dashboard, click "New" → "Web Service"
2. Connect your GitHub repository
3. Configure the service:
   - Name: `chatbot-frontend`
   - Environment: "Node"
   - Root Directory: `frontend`
   - Build Command: `npm install && npm run build`
   - Start Command: `npx serve -s dist`
   - Node Version: `18.16.0`
4. Add the following environment variables:
   - `VITE_API_URL`: URL of your Java backend (e.g., `https://chatbot-java-api.onrender.com`)
5. Click "Create Web Service"

### Step 4: Configure Cross-Service Communication

After all services are deployed, you need to update the CORS settings:

1. Go to your Java backend service on Render
2. Add/update environment variable:
   - `APP_CORS_ALLOWED_ORIGINS`: URL of your frontend (e.g., `https://chatbot-frontend.onrender.com`)

3. Go to your Python AI service on Render
4. Add/update environment variable:
   - `ALLOWED_ORIGINS`: URL of your frontend (e.g., `https://chatbot-frontend.onrender.com`)

5. Go to your Java backend service on Render
6. Add/update environment variable:
   - `AI_SERVICE_URL`: URL of your Python AI service (e.g., `https://chatbot-python-ai.onrender.com`)

7. Go to your frontend service on Render
8. Add/update environment variable:
   - `VITE_API_URL`: URL of your Java backend (e.g., `https://chatbot-java-api.onrender.com`)

### Step 5: Verify Deployment

Once all services are deployed:

1. Access your frontend URL (e.g., `https://chatbot-frontend.onrender.com`)
2. Try registering a new user and logging in
3. Test the chat functionality
4. Check the logs of each service if you encounter any issues

## Troubleshooting

### Service Crashes
- Check service logs in the Render dashboard
- Ensure all environment variables are correctly set
- Verify the database schema was properly initialized

### CORS Issues
- Double-check the `APP_CORS_ALLOWED_ORIGINS` and `ALLOWED_ORIGINS` variables
- Ensure they include the https:// prefix and no trailing slash

### Database Connection Issues
- Verify the connection string format in `SPRING_DATASOURCE_URL`
- Check that the database user has proper permissions

### Memory Issues
- Consider upgrading to a larger Render instance if you're experiencing out-of-memory errors
- Adjust `JAVA_OPTS` to limit memory usage on smaller instances

## Cost Optimization

- Use Render's free tier for development/testing
- For production, consider:
  - Using Render's "suspended" feature for services when not in use
  - Setting up automatic scaling rules for traffic peaks

## Additional Resources

- [Render Documentation](https://docs.render.com)
- [Spring Boot on Render](https://docs.render.com/deploy-spring-boot)
- [FastAPI on Render](https://docs.render.com/deploy-fastapi)
- [Node.js on Render](https://docs.render.com/deploy-node-express-app)
- [PostgreSQL on Render](https://docs.render.com/databases)