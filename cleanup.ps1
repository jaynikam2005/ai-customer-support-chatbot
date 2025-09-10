# Cleanup Script for AI Customer Support Chatbot
# Removes unnecessary files and directories from the project

Write-Host "==== AI Customer Support Chatbot Cleanup ====" -ForegroundColor Cyan

# Step 1: Remove build artifacts and cache files
Write-Host "`nRemoving build artifacts and cache files..." -ForegroundColor Yellow

# Remove node_modules (comment out if you're actively developing the frontend)
if (Test-Path -Path ".\frontend\node_modules") {
    Write-Host "Removing frontend/node_modules directory..." -ForegroundColor Gray
    Remove-Item -Path ".\frontend\node_modules" -Recurse -Force
    Write-Host "✅ Removed frontend/node_modules" -ForegroundColor Green
} else {
    Write-Host "✓ frontend/node_modules already removed" -ForegroundColor Gray
}

# Remove root node_modules (if exists)
if (Test-Path -Path ".\node_modules") {
    Write-Host "Removing root node_modules directory..." -ForegroundColor Gray
    Remove-Item -Path ".\node_modules" -Recurse -Force
    Write-Host "✅ Removed root node_modules" -ForegroundColor Green
} else {
    Write-Host "✓ Root node_modules already removed" -ForegroundColor Gray
}

# Remove Python cache files
if (Test-Path -Path ".\backend-python\app\__pycache__") {
    Write-Host "Removing Python __pycache__ directories..." -ForegroundColor Gray
    Get-ChildItem -Path ".\backend-python" -Include "__pycache__" -Recurse -Force | ForEach-Object {
        Remove-Item -Path $_.FullName -Recurse -Force
        Write-Host "✅ Removed $($_.FullName)" -ForegroundColor Green
    }
} else {
    Write-Host "✓ Python __pycache__ directories already removed" -ForegroundColor Gray
}

# Remove Java build artifacts
if (Test-Path -Path ".\backend-java\target") {
    Write-Host "Removing Java target directory..." -ForegroundColor Gray
    Remove-Item -Path ".\backend-java\target" -Recurse -Force
    Write-Host "✅ Removed backend-java/target" -ForegroundColor Green
} else {
    Write-Host "✓ Java target directory already removed" -ForegroundColor Gray
}

# Step 2: Remove redundant deployment files (if you're standardizing on Railway deployment)
Write-Host "`nRemoving redundant deployment files..." -ForegroundColor Yellow

# Prompt user about which deployment platform to keep
$deploymentChoice = Read-Host "Which deployment platform do you want to keep? [1=Railway (default), 2=General, 3=Keep All]"
if ($deploymentChoice -eq "2") {
    # Keep general deployment, remove Railway specific
    if (Test-Path -Path ".\railway.json") {
        Write-Host "Removing Railway specific files..." -ForegroundColor Gray
        Remove-Item -Path ".\railway*.json" -Force
        Remove-Item -Path ".\railway-*.ps1" -Force
        Remove-Item -Path ".\railway-*.sh" -Force
        Remove-Item -Path ".\railway-*.md" -Force
        Remove-Item -Path ".\RAILWAY_DEPLOYMENT.md" -Force
        Remove-Item -Path ".\.env.railway" -Force
        Write-Host "✅ Removed Railway specific files" -ForegroundColor Green
    }
} elseif ($deploymentChoice -eq "1" -or $deploymentChoice -eq "") {
    # Keep Railway, remove general deployment
    Write-Host "Keeping Railway deployment files, removing general deployment..." -ForegroundColor Gray
    if (Test-Path -Path ".\deploy.ps1") { Remove-Item -Path ".\deploy.ps1" -Force }
    if (Test-Path -Path ".\deploy.sh") { Remove-Item -Path ".\deploy.sh" -Force }
    Write-Host "✅ Removed general deployment scripts" -ForegroundColor Green
}
# Option 3 - Keep all, do nothing

# Step 3: Standardize on PowerShell or Bash scripts based on user preference
$scriptChoice = Read-Host "Which script type do you want to keep? [1=PowerShell (default), 2=Bash, 3=Keep Both]"
if ($scriptChoice -eq "1" -or $scriptChoice -eq "") {
    # Keep PowerShell, remove Bash
    Write-Host "Keeping PowerShell scripts, removing Bash scripts..." -ForegroundColor Gray
    if (Test-Path -Path ".\*.sh") {
        Get-ChildItem -Path "." -Filter "*.sh" -File | ForEach-Object {
            Remove-Item -Path $_.FullName -Force
            Write-Host "✅ Removed $($_.Name)" -ForegroundColor Green
        }
    }
} elseif ($scriptChoice -eq "2") {
    # Keep Bash, remove PowerShell
    Write-Host "Keeping Bash scripts, removing PowerShell scripts..." -ForegroundColor Gray
    if (Test-Path -Path ".\*.ps1") {
        # Don't remove this cleanup script itself
        Get-ChildItem -Path "." -Filter "*.ps1" -File | Where-Object { $_.Name -ne "cleanup.ps1" } | ForEach-Object {
            Remove-Item -Path $_.FullName -Force
            Write-Host "✅ Removed $($_.Name)" -ForegroundColor Green
        }
    }
}
# Option 3 - Keep all, do nothing

# Step 4: Remove test files
$testChoice = Read-Host "Do you want to remove test scripts? [Y/N] (default: N)"
if ($testChoice -eq "Y" -or $testChoice -eq "y") {
    Write-Host "Removing test scripts..." -ForegroundColor Gray
    if (Test-Path -Path ".\e2e-test.ps1") { Remove-Item -Path ".\e2e-test.ps1" -Force }
    if (Test-Path -Path ".\test-frontend-api.ps1") { Remove-Item -Path ".\test-frontend-api.ps1" -Force }
    Write-Host "✅ Removed test scripts" -ForegroundColor Green
} else {
    Write-Host "✓ Keeping test scripts" -ForegroundColor Gray
}

# Step 5: Remove unnecessary environment files
$envChoice = Read-Host "Which environment template to keep? [1=.env.railway (default), 2=.env.sample, 3=Keep All]"
if ($envChoice -eq "1" -or $envChoice -eq "") {
    # Keep .env.railway, remove .env.sample
    if (Test-Path -Path ".\.env.sample") {
        Remove-Item -Path ".\.env.sample" -Force
        Write-Host "✅ Removed .env.sample" -ForegroundColor Green
    }
} elseif ($envChoice -eq "2") {
    # Keep .env.sample, remove .env.railway
    if (Test-Path -Path ".\.env.railway") {
        Remove-Item -Path ".\.env.railway" -Force
        Write-Host "✅ Removed .env.railway" -ForegroundColor Green
    }
}
# Option 3 - Keep all, do nothing

Write-Host "`n✅ Cleanup complete!" -ForegroundColor Green
Write-Host "Project size reduced and optimized for deployment." -ForegroundColor Cyan