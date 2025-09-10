# Deployment script for AI Customer Support Chatbot (PowerShell version)

# Text colors
$Green = @{ForegroundColor = "Green"}
$Yellow = @{ForegroundColor = "Yellow"}
$Blue = @{ForegroundColor = "Cyan"}
$Red = @{ForegroundColor = "Red"}

# Print banner
Write-Host "================================================" @Blue
Write-Host "   AI Customer Support Chatbot - Deployment Tool " @Blue
Write-Host "================================================" @Blue
Write-Host ""

# Function to check if a command exists
function Test-CommandExists {
    param ($command)
    $exists = $null -ne (Get-Command $command -ErrorAction SilentlyContinue)
    return $exists
}

# Check for required tools
Write-Host "Checking for required tools..." @Yellow

$missingTools = $false

if (-not (Test-CommandExists "docker")) {
    Write-Host "✗ Docker not found. Please install Docker: https://docs.docker.com/get-docker/" @Red
    $missingTools = $true
}

if (-not (Test-CommandExists "docker-compose") -and -not (docker compose --version 2>$null)) {
    Write-Host "✗ Docker Compose not found. Please install Docker Desktop or Docker Compose plugin." @Red
    $missingTools = $true
}

if ($missingTools) {
    Write-Host "Please install the missing tools and try again." @Red
    exit 1
}

Write-Host "✓ All required tools are installed." @Green
Write-Host ""

# Environment setup
Write-Host "Setting up environment files..." @Yellow

# Create backend-python/.env if it doesn't exist
if (-not (Test-Path "backend-python/.env")) {
    if (Test-Path "backend-python/.env.sample") {
        Copy-Item "backend-python/.env.sample" "backend-python/.env"
        Write-Host "✓ Created backend-python/.env from sample" @Green
        Write-Host "⚠ Please edit backend-python/.env to add your API keys" @Yellow
    } else {
        Write-Host "✗ backend-python/.env.sample not found. Creating a basic .env file." @Red
        @"
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
"@ | Out-File -FilePath "backend-python/.env" -Encoding utf8
        Write-Host "⚠ Please edit backend-python/.env to add your API keys" @Yellow
    }
}

# Deployment options
Write-Host ""
Write-Host "How would you like to deploy?" @Blue
Write-Host "1) Local deployment with Docker Compose"
Write-Host "2) Prepare for Render deployment"
Write-Host "3) Prepare for Railway deployment" 
Write-Host "4) Prepare for cloud deployment with separate services"
Write-Host "5) Exit"

$deploymentChoice = Read-Host "Enter your choice (1-5)"

switch ($deploymentChoice) {
    "1" {
        # Local Docker Compose deployment
        Write-Host "Starting local deployment with Docker Compose..." @Yellow
        
        # Check for frontend environment variables
        if (-not (Test-Path "frontend/.env.local")) {
            Write-Host "Creating frontend/.env.local" @Yellow
            @"
VITE_API_URL=http://localhost:8080
"@ | Out-File -FilePath "frontend/.env.local" -Encoding utf8
            Write-Host "✓ Created frontend/.env.local" @Green
        }
        
        # Start containers
        Write-Host "Building and starting containers..." @Yellow
        $result = docker-compose up -d --build
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ Deployment successful!" @Green
            Write-Host "✓ Services are now running:" @Green
            Write-Host "  - Frontend: http://localhost:3000" @Blue
            Write-Host "  - Java Backend API: http://localhost:8080" @Blue
            Write-Host "  - Python AI Service: http://localhost:5000" @Blue
            Write-Host "  - PostgreSQL: localhost:5432" @Blue
        } else {
            Write-Host "✗ Deployment failed. Check the error messages above." @Red
        }
    }
    
    "2" {
        # Render deployment preparation
        Write-Host "Preparing for Render deployment..." @Yellow
        Write-Host "✓ Your project is already configured for Render deployment." @Green
        Write-Host "Follow these steps:" @Yellow
        Write-Host "1. Create a PostgreSQL database service on Render"
        Write-Host "2. Deploy the Python AI service using the Dockerfile in backend-python"
        Write-Host "3. Deploy the Java backend service using the Dockerfile in backend-java"
        Write-Host "4. Deploy the frontend using the Dockerfile in frontend"
        Write-Host "See the DEPLOYMENT.md files in each directory for detailed instructions." @Yellow
    }
    
    "3" {
        # Railway deployment preparation
        Write-Host "Preparing for Railway deployment..." @Yellow
        Write-Host "✓ Your project is already configured for Railway deployment." @Green
        Write-Host "Follow these steps:" @Yellow
        Write-Host "1. Create a new Railway project"
        Write-Host "2. Add a PostgreSQL service"
        Write-Host "3. Deploy each service using the respective Dockerfiles"
        Write-Host "See the DEPLOYMENT.md files in each directory for detailed instructions." @Yellow
    }
    
    "4" {
        # Cloud deployment with separate services
        Write-Host "Preparing for cloud deployment with separate services..." @Yellow
        Write-Host "✓ Created a deployment checklist:" @Green
        
        @"
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
"@ | Out-File -FilePath "DEPLOYMENT_CHECKLIST.md" -Encoding utf8
        
        Write-Host "✓ Created DEPLOYMENT_CHECKLIST.md" @Green
        Write-Host "Follow the checklist and refer to the DEPLOYMENT.md files in each directory." @Yellow
    }
    
    "5" {
        # Exit
        Write-Host "Exiting deployment tool." @Blue
        exit 0
    }
    
    default {
        Write-Host "Invalid option. Exiting." @Red
        exit 1
    }
}

Write-Host ""
Write-Host "================================================" @Blue
Write-Host "   Deployment process completed                 " @Blue
Write-Host "================================================" @Blue