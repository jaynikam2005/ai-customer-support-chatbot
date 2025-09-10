# Deployment script for AI Customer Support Chatbot (PowerShell version)

# Define color variables
$Green = "Green"
$Yellow = "Yellow"
$Blue = "Cyan"
$Red = "Red"

# Print banner
Write-Host "================================================" -ForegroundColor $Blue
Write-Host "   AI Customer Support Chatbot - Deployment Tool " -ForegroundColor $Blue
Write-Host "================================================" -ForegroundColor $Blue
Write-Host ""

# Function to check if a command exists
function Test-CommandExists {
    param ($command)
    return ($null -ne (Get-Command $command -ErrorAction SilentlyContinue))
}

# Check for required tools
Write-Host "Checking for required tools..." -ForegroundColor $Yellow

$missingTools = $false

if (-not (Test-CommandExists "docker")) {
    Write-Host "X Docker not found. Please install Docker: https://docs.docker.com/get-docker/" -ForegroundColor $Red
    $missingTools = $true
}

# Determine the correct Docker Compose command
$composeCmd = $null
try {
    $null = & docker compose version 2>$null
    $composeCmd = "docker compose"
} catch {
    try {
        $null = docker-compose --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            $composeCmd = "docker-compose"
        }
    } catch {
        # leave $composeCmd null
    }
}

if (-not $composeCmd) {
    Write-Host "X Docker Compose not found. Please install Docker Desktop or Docker Compose plugin." -ForegroundColor $Red
    $missingTools = $true
}

if ($missingTools) {
    Write-Host "Please install the missing tools and try again." -ForegroundColor $Red
    exit 1
}

Write-Host "✓ All required tools are installed." -ForegroundColor $Green
Write-Host ""

# Environment setup
Write-Host "Setting up environment files..." -ForegroundColor $Yellow

# Create backend-python/.env if it doesn't exist
if (-not (Test-Path "backend-python/.env")) {
    if (Test-Path "backend-python/.env.sample") {
        Copy-Item "backend-python/.env.sample" "backend-python/.env"
        Write-Host "✓ Created backend-python/.env from sample" -ForegroundColor $Green
        Write-Host "Please edit backend-python/.env to add your API keys" -ForegroundColor $Yellow
    }
    else {
        Write-Host "X backend-python/.env.sample not found. Creating a basic .env file." -ForegroundColor $Red
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
        Write-Host "Please edit backend-python/.env to add your API keys" -ForegroundColor $Yellow
    }
}

# Deployment options
Write-Host ""
Write-Host "How would you like to deploy?" -ForegroundColor $Blue
Write-Host "1) Local deployment with Docker Compose"
Write-Host "2) Prepare for Render deployment"
Write-Host "3) Prepare for Railway deployment"
Write-Host "4) Prepare for cloud deployment with separate services"
Write-Host "5) Exit"

$deploymentChoice = Read-Host "Enter your choice (1-5)"

switch ($deploymentChoice) {
    "1" {
        Write-Host "Starting local deployment with Docker Compose..." -ForegroundColor $Yellow

        if (-not (Test-Path "frontend/.env.local")) {
            Write-Host "Creating frontend/.env.local" -ForegroundColor $Yellow
            "" | Out-File -FilePath "frontend/.env.local" -Encoding utf8
            Write-Host "✓ Created frontend/.env.local" -ForegroundColor $Green
        }

        Write-Host "Building and starting containers..." -ForegroundColor $Yellow
        & $composeCmd up -d --build

        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ Deployment successful!" -ForegroundColor $Green
            Write-Host "✓ Services are now running:" -ForegroundColor $Green
            Write-Host "  - Frontend: http://localhost:3000" -ForegroundColor $Blue
            Write-Host "  - Java Backend API: http://localhost:8080" -ForegroundColor $Blue
            Write-Host "  - Python AI Service: http://localhost:5000" -ForegroundColor $Blue
            Write-Host "  - PostgreSQL: localhost:5432" -ForegroundColor $Blue
        }
        else {
            Write-Host "X Deployment failed. Check the error messages above." -ForegroundColor $Red
        }
    }
    "2" {
        Write-Host "Preparing for Render deployment..." -ForegroundColor $Yellow
        Write-Host "✓ Your project is already configured for Render deployment." -ForegroundColor $Green
        Write-Host "Follow these steps:" -ForegroundColor $Yellow
        Write-Host "1. Create a PostgreSQL database service on Render"
        Write-Host "2. Deploy the Python AI service using the Dockerfile in backend-python"
        Write-Host "3. Deploy the Java backend service using the Dockerfile in backend-java"
        Write-Host "4. Deploy the frontend using the Dockerfile in frontend"
        Write-Host "See the DEPLOYMENT.md files in each directory for detailed instructions." -ForegroundColor $Yellow
    }
    "3" {
        Write-Host "Preparing for Railway deployment..." -ForegroundColor $Yellow
        Write-Host "✓ Your project is already configured for Railway deployment." -ForegroundColor $Green
        Write-Host "Follow these steps:" -ForegroundColor $Yellow
        Write-Host "1. Create a new Railway project"
        Write-Host "2. Add a PostgreSQL service"
        Write-Host "3. Deploy each service using the respective Dockerfiles"
        Write-Host "See the DEPLOYMENT.md files in each directory for detailed instructions." -ForegroundColor $Yellow
    }
    "4" {
        Write-Host "Preparing for cloud deployment with separate services..." -ForegroundColor $Yellow
        Write-Host "✓ Created a deployment checklist:" -ForegroundColor $Green

        @"
# Deployment Checklist for AI Customer Support Chatbot
...
"@ | Out-File -FilePath "DEPLOYMENT_CHECKLIST.md" -Encoding utf8

        Write-Host "✓ Created DEPLOYMENT_CHECKLIST.md" -ForegroundColor $Green
        Write-Host "Follow the checklist and refer to the DEPLOYMENT.md files in each directory." -ForegroundColor $Yellow
    }
    "5" {
        Write-Host "Exiting deployment tool." -ForegroundColor $Blue
        exit 0
    }
    default {
        Write-Host "Invalid option. Exiting." -ForegroundColor $Red
        exit 1
    }
}

Write-Host ""
Write-Host "================================================" -ForegroundColor $Blue
Write-Host "   Deployment process completed                 " -ForegroundColor $Blue
Write-Host "================================================" -ForegroundColor $Blue
