#!/bin/bash
# Deployment script for AI Customer Support Chatbot

# Text colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Print banner
echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}   AI Customer Support Chatbot - Deployment Tool ${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""

# Function to check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Check for required tools
echo -e "${YELLOW}Checking for required tools...${NC}"

MISSING_TOOLS=0

if ! command_exists docker; then
  echo -e "${RED}✗ Docker not found. Please install Docker: https://docs.docker.com/get-docker/${NC}"
  MISSING_TOOLS=1
fi

if ! command_exists docker-compose || ! command_exists docker compose; then
  echo -e "${RED}✗ Docker Compose not found. Please install Docker Compose: https://docs.docker.com/compose/install/${NC}"
  MISSING_TOOLS=1
fi

if [ $MISSING_TOOLS -eq 1 ]; then
  echo -e "${RED}Please install the missing tools and try again.${NC}"
  exit 1
fi

echo -e "${GREEN}✓ All required tools are installed.${NC}"
echo ""

# Environment setup
echo -e "${YELLOW}Setting up environment files...${NC}"

# Create backend-python/.env if it doesn't exist
if [ ! -f backend-python/.env ]; then
  if [ -f backend-python/.env.sample ]; then
    cp backend-python/.env.sample backend-python/.env
    echo -e "${GREEN}✓ Created backend-python/.env from sample${NC}"
    echo -e "${YELLOW}⚠ Please edit backend-python/.env to add your API keys${NC}"
  else
    echo -e "${RED}✗ backend-python/.env.sample not found. Creating a basic .env file.${NC}"
    cat > backend-python/.env << EOF
# Google Gemini API Configuration
GOOGLE_API_KEY=your_gemini_api_key_here
GEMINI_MODEL=gemini-1.5-flash

# Server configuration
HOST=0.0.0.0
PORT=5000

# CORS settings
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:5173

# Python configuration
PYTHONPATH=/workspace
PYTHONUNBUFFERED=1
EOF
    echo -e "${YELLOW}⚠ Please edit backend-python/.env to add your API keys${NC}"
  fi
fi

# Deployment options
echo ""
echo -e "${BLUE}How would you like to deploy?${NC}"
echo "1) Local deployment with Docker Compose"
echo "2) Prepare for Render deployment"
echo "3) Prepare for Railway deployment"
echo "4) Prepare for cloud deployment with separate services"
echo "5) Exit"

read -p "Enter your choice (1-5): " deployment_choice

case $deployment_choice in
  1)
    # Local Docker Compose deployment
    echo -e "${YELLOW}Starting local deployment with Docker Compose...${NC}"
    
    # Check for frontend environment variables
    if [ ! -f frontend/.env.local ]; then
      echo -e "${YELLOW}Creating frontend/.env.local${NC}"
      cat > frontend/.env.local << EOF
VITE_API_URL=http://localhost:8080
EOF
      echo -e "${GREEN}✓ Created frontend/.env.local${NC}"
    fi
    
    # Start containers
    echo -e "${YELLOW}Building and starting containers...${NC}"
    docker-compose up -d --build
    
    if [ $? -eq 0 ]; then
      echo -e "${GREEN}✓ Deployment successful!${NC}"
      echo -e "${GREEN}✓ Services are now running:${NC}"
      echo -e "  - Frontend: ${BLUE}http://localhost:3000${NC}"
      echo -e "  - Java Backend API: ${BLUE}http://localhost:8080${NC}"
      echo -e "  - Python AI Service: ${BLUE}http://localhost:5000${NC}"
      echo -e "  - PostgreSQL: ${BLUE}localhost:5432${NC}"
    else
      echo -e "${RED}✗ Deployment failed. Check the error messages above.${NC}"
    fi
    ;;
    
  2)
    # Render deployment preparation
    echo -e "${YELLOW}Preparing for Render deployment...${NC}"
    echo -e "${GREEN}✓ Your project is already configured for Render deployment.${NC}"
    echo -e "${YELLOW}Follow these steps:${NC}"
    echo "1. Create a PostgreSQL database service on Render"
    echo "2. Deploy the Python AI service using the Dockerfile in backend-python"
    echo "3. Deploy the Java backend service using the Dockerfile in backend-java"
    echo "4. Deploy the frontend using the Dockerfile in frontend"
    echo -e "${YELLOW}See the DEPLOYMENT.md files in each directory for detailed instructions.${NC}"
    ;;
    
  3)
    # Railway deployment preparation
    echo -e "${YELLOW}Preparing for Railway deployment...${NC}"
    echo -e "${GREEN}✓ Your project is already configured for Railway deployment.${NC}"
    echo -e "${YELLOW}Follow these steps:${NC}"
    echo "1. Create a new Railway project"
    echo "2. Add a PostgreSQL service"
    echo "3. Deploy each service using the respective Dockerfiles"
    echo -e "${YELLOW}See the DEPLOYMENT.md files in each directory for detailed instructions.${NC}"
    ;;
    
  4)
    # Cloud deployment with separate services
    echo -e "${YELLOW}Preparing for cloud deployment with separate services...${NC}"
    echo -e "${GREEN}✓ Created a deployment checklist:${NC}"
    
    cat > DEPLOYMENT_CHECKLIST.md << EOF
# Deployment Checklist for AI Customer Support Chatbot

## Database Deployment
- [ ] Deploy PostgreSQL database (see database/DEPLOYMENT.md)
- [ ] Run database migrations
- [ ] Set up database credentials securely
- [ ] Configure database backups

## Python AI Service Deployment
- [ ] Set up environment variables (copy from .env.sample)
- [ ] Deploy Python service (see backend-python/DEPLOYMENT.md)
- [ ] Verify health endpoint: /health
- [ ] Configure API keys securely

## Java Backend Deployment
- [ ] Configure to use your PostgreSQL database
- [ ] Configure to connect to your Python AI service
- [ ] Deploy Java service (see backend-java/DEPLOYMENT.md)
- [ ] Verify health endpoint: /actuator/health

## Frontend Deployment
- [ ] Configure VITE_API_URL to point to your Java backend
- [ ] Deploy frontend (see frontend/DEPLOY_TO_VERCEL.md)
- [ ] Verify connectivity

## Post-Deployment Verification
- [ ] Test user registration
- [ ] Test user login
- [ ] Test chatbot Q&A functionality
- [ ] Verify that caching is working properly
- [ ] Check security settings (CORS, authentication)
EOF
    
    echo -e "${GREEN}✓ Created DEPLOYMENT_CHECKLIST.md${NC}"
    echo -e "${YELLOW}Follow the checklist and refer to the DEPLOYMENT.md files in each directory.${NC}"
    ;;
    
  5)
    # Exit
    echo -e "${BLUE}Exiting deployment tool.${NC}"
    exit 0
    ;;
    
  *)
    echo -e "${RED}Invalid option. Exiting.${NC}"
    exit 1
    ;;
esac

echo ""
echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}   Deployment process completed                 ${NC}"
echo -e "${BLUE}================================================${NC}"