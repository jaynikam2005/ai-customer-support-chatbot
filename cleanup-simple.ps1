# Simple Cleanup Script
# This script will remove all unnecessary files at once without prompting

Write-Host "=== Removing Unnecessary Files ===" -ForegroundColor Cyan

# 1. Remove build artifacts
Write-Host "Cleaning build artifacts..."

# Python cache
Get-ChildItem -Path . -Include "__pycache__", "*.pyc", "*.pyo" -Recurse -Force | ForEach-Object {
    Remove-Item -Path $_.FullName -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "Removed: $($_.FullName)" -ForegroundColor Gray
}

# Java build artifacts
if (Test-Path -Path ".\backend-java\target") {
    Remove-Item -Path ".\backend-java\target" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "Removed: backend-java\target" -ForegroundColor Gray
}

# 2. Remove test scripts if not needed
$removeTestChoice = Read-Host "Remove test scripts? (e2e-test.ps1, test-frontend-api.ps1) [Y/N]"
if ($removeTestChoice -eq "Y" -or $removeTestChoice -eq "y") {
    if (Test-Path -Path ".\e2e-test.ps1") { 
        Remove-Item -Path ".\e2e-test.ps1" -Force -ErrorAction SilentlyContinue 
        Write-Host "Removed: e2e-test.ps1" -ForegroundColor Gray
    }
    if (Test-Path -Path ".\test-frontend-api.ps1") { 
        Remove-Item -Path ".\test-frontend-api.ps1" -Force -ErrorAction SilentlyContinue 
        Write-Host "Removed: test-frontend-api.ps1" -ForegroundColor Gray
    }
}

# 3. Standardize deployment files
$deploymentChoice = Read-Host "Which deployment do you want to keep? [1=Railway, 2=General, 3=Both]"

if ($deploymentChoice -eq "1") {
    # Keep Railway, remove general
    if (Test-Path -Path ".\deploy.ps1") { Remove-Item -Path ".\deploy.ps1" -Force -ErrorAction SilentlyContinue }
    if (Test-Path -Path ".\deploy.sh") { Remove-Item -Path ".\deploy.sh" -Force -ErrorAction SilentlyContinue }
    Write-Host "Removed general deployment files" -ForegroundColor Gray
}
elseif ($deploymentChoice -eq "2") {
    # Keep general, remove Railway
    Get-ChildItem -Path . -Filter "railway*" -File | ForEach-Object {
        Remove-Item -Path $_.FullName -Force -ErrorAction SilentlyContinue
        Write-Host "Removed: $($_.Name)" -ForegroundColor Gray
    }
    if (Test-Path -Path ".\RAILWAY_DEPLOYMENT.md") { 
        Remove-Item -Path ".\RAILWAY_DEPLOYMENT.md" -Force -ErrorAction SilentlyContinue 
        Write-Host "Removed: RAILWAY_DEPLOYMENT.md" -ForegroundColor Gray
    }
}

# 4. Script standardization
$scriptChoice = Read-Host "Which script type to keep? [1=PowerShell, 2=Bash, 3=Both]"

if ($scriptChoice -eq "1") {
    # Remove bash scripts except this cleanup
    Get-ChildItem -Path . -Filter "*.sh" -File | ForEach-Object {
        if ($_.Name -ne "cleanup.sh") {
            Remove-Item -Path $_.FullName -Force -ErrorAction SilentlyContinue
            Write-Host "Removed: $($_.Name)" -ForegroundColor Gray
        }
    }
}
elseif ($scriptChoice -eq "2") {
    # Remove PowerShell scripts except this cleanup
    Get-ChildItem -Path . -Filter "*.ps1" -File | ForEach-Object {
        if ($_.Name -ne "cleanup-simple.ps1") {
            Remove-Item -Path $_.FullName -Force -ErrorAction SilentlyContinue
            Write-Host "Removed: $($_.Name)" -ForegroundColor Gray
        }
    }
}

Write-Host "`nCleanup completed!" -ForegroundColor Green