#!/bin/bash
# Cleanup Script for AI Customer Support Chatbot
# Removes unnecessary files and directories from the project

echo "==== AI Customer Support Chatbot Cleanup ===="
echo ""

# Step 1: Remove build artifacts and cache files
echo "Removing build artifacts and cache files..."

# Remove node_modules (comment out if you're actively developing the frontend)
if [ -d "./frontend/node_modules" ]; then
    echo "Removing frontend/node_modules directory..."
    rm -rf ./frontend/node_modules
    echo "✅ Removed frontend/node_modules"
else
    echo "✓ frontend/node_modules already removed"
fi

# Remove root node_modules (if exists)
if [ -d "./node_modules" ]; then
    echo "Removing root node_modules directory..."
    rm -rf ./node_modules
    echo "✅ Removed root node_modules"
else
    echo "✓ Root node_modules already removed"
fi

# Remove Python cache files
if [ -d "./backend-python/app/__pycache__" ]; then
    echo "Removing Python __pycache__ directories..."
    find ./backend-python -name __pycache__ -type d -exec rm -rf {} +
    echo "✅ Removed Python __pycache__ directories"
else
    echo "✓ Python __pycache__ directories already removed"
fi

# Remove Java build artifacts
if [ -d "./backend-java/target" ]; then
    echo "Removing Java target directory..."
    rm -rf ./backend-java/target
    echo "✅ Removed backend-java/target"
else
    echo "✓ Java target directory already removed"
fi

# Step 2: Remove redundant deployment files (if you're standardizing on Railway deployment)
echo ""
echo "Removing redundant deployment files..."

# Prompt user about which deployment platform to keep
read -p "Which deployment platform do you want to keep? [1=Railway (default), 2=General, 3=Keep All] " deploymentChoice
if [ "$deploymentChoice" = "2" ]; then
    # Keep general deployment, remove Railway specific
    if [ -f "./railway.json" ]; then
        echo "Removing Railway specific files..."
        rm -f ./railway*.json
        rm -f ./railway-*.ps1
        rm -f ./railway-*.sh
        rm -f ./railway-*.md
        rm -f ./RAILWAY_DEPLOYMENT.md
        rm -f ./.env.railway
        echo "✅ Removed Railway specific files"
    fi
elif [ "$deploymentChoice" = "1" ] || [ "$deploymentChoice" = "" ]; then
    # Keep Railway, remove general deployment
    echo "Keeping Railway deployment files, removing general deployment..."
    if [ -f "./deploy.ps1" ]; then rm -f ./deploy.ps1; fi
    if [ -f "./deploy.sh" ]; then rm -f ./deploy.sh; fi
    echo "✅ Removed general deployment scripts"
fi
# Option 3 - Keep all, do nothing

# Step 3: Standardize on PowerShell or Bash scripts based on user preference
read -p "Which script type do you want to keep? [1=PowerShell, 2=Bash (default), 3=Keep Both] " scriptChoice
if [ "$scriptChoice" = "1" ]; then
    # Keep PowerShell, remove Bash
    echo "Keeping PowerShell scripts, removing Bash scripts..."
    find . -name "*.sh" -type f -delete
    echo "✅ Removed Bash scripts"
elif [ "$scriptChoice" = "2" ] || [ "$scriptChoice" = "" ]; then
    # Keep Bash, remove PowerShell
    echo "Keeping Bash scripts, removing PowerShell scripts..."
    # Don't remove this cleanup script itself
    find . -name "*.ps1" -type f -delete
    echo "✅ Removed PowerShell scripts"
fi
# Option 3 - Keep all, do nothing

# Step 4: Remove test files
read -p "Do you want to remove test scripts? [Y/N] (default: N) " testChoice
if [ "$testChoice" = "Y" ] || [ "$testChoice" = "y" ]; then
    echo "Removing test scripts..."
    if [ -f "./e2e-test.ps1" ]; then rm -f ./e2e-test.ps1; fi
    if [ -f "./test-frontend-api.ps1" ]; then rm -f ./test-frontend-api.ps1; fi
    echo "✅ Removed test scripts"
else
    echo "✓ Keeping test scripts"
fi

# Step 5: Remove unnecessary environment files
read -p "Which environment template to keep? [1=.env.railway (default), 2=.env.sample, 3=Keep All] " envChoice
if [ "$envChoice" = "1" ] || [ "$envChoice" = "" ]; then
    # Keep .env.railway, remove .env.sample
    if [ -f "./.env.sample" ]; then
        rm -f ./.env.sample
        echo "✅ Removed .env.sample"
    fi
elif [ "$envChoice" = "2" ]; then
    # Keep .env.sample, remove .env.railway
    if [ -f "./.env.railway" ]; then
        rm -f ./.env.railway
        echo "✅ Removed .env.railway"
    fi
fi
# Option 3 - Keep all, do nothing

echo ""
echo "✅ Cleanup complete!"
echo "Project size reduced and optimized for deployment."