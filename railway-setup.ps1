# Railway Project Setup Script for PowerShell

# Check for Railway CLI
if (-not (Get-Command railway -ErrorAction SilentlyContinue)) {
    Write-Host "Railway CLI not found. Installing..." -ForegroundColor Yellow
    npm install -g @railway/cli
}

# Login to Railway
Write-Host "Please login to Railway..." -ForegroundColor Cyan
railway login

# Create a new project
Write-Host "Creating a new Railway project..." -ForegroundColor Cyan
railway init
$projectName = "ai-customer-support-chatbot"
railway project create $projectName

# Add PostgreSQL
Write-Host "Adding PostgreSQL database..." -ForegroundColor Cyan
railway add --plugin postgresql

# Link services
Write-Host "Now we'll create and link each service." -ForegroundColor Cyan
Write-Host "Please follow the instructions in RAILWAY_DEPLOYMENT.md to complete the setup." -ForegroundColor Cyan

# Display useful information
Write-Host ""
Write-Host "===== SETUP COMPLETE =====" -ForegroundColor Green
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Deploy your services following RAILWAY_DEPLOYMENT.md" -ForegroundColor White
Write-Host "2. Configure environment variables using the .env.railway template" -ForegroundColor White
Write-Host "3. Initialize your database with db-schema.sql" -ForegroundColor White
Write-Host ""
Write-Host "Your Railway project is ready for deployment!" -ForegroundColor Green