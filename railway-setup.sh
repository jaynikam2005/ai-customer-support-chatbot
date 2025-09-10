#!/bin/bash
# Railway Project Setup Script

# Check for Railway CLI
if ! command -v railway &> /dev/null; then
    echo "Railway CLI not found. Installing..."
    npm install -g @railway/cli
fi

# Login to Railway
echo "Please login to Railway..."
railway login

# Create a new project
echo "Creating a new Railway project..."
railway init
project_name="ai-customer-support-chatbot"
railway project create $project_name

# Add PostgreSQL
echo "Adding PostgreSQL database..."
railway add --plugin postgresql

# Link services
echo "Now we'll create and link each service."
echo "Please follow the instructions in RAILWAY_DEPLOYMENT.md to complete the setup."

# Display useful information
echo ""
echo "===== SETUP COMPLETE ====="
echo "Next steps:"
echo "1. Deploy your services following RAILWAY_DEPLOYMENT.md"
echo "2. Configure environment variables using the .env.railway template"
echo "3. Initialize your database with db-schema.sql"
echo ""
echo "Your Railway project is ready for deployment!"