# Enhanced Project Cleanup Script
# Usage: .\cleanup-enhanced.ps1
# Description: Removes cache files, build artifacts, and other unnecessary files

Write-Host "Starting project cleanup..." -ForegroundColor Cyan

# Function to safely remove directories and files
function Remove-SafeItem {
    param (
        [string]$Path,
        [string]$Description
    )
    
    if (Test-Path $Path) {
        Write-Host "  Removing $Description at: $Path" -ForegroundColor Yellow
        try {
            if ((Get-Item $Path).PSIsContainer) {
                Remove-Item -Path $Path -Recurse -Force -ErrorAction Stop
            } else {
                Remove-Item -Path $Path -Force -ErrorAction Stop
            }
            Write-Host "  Removed successfully." -ForegroundColor Green
        } catch {
            Write-Host "  ⚠️ Error removing $Path : $_" -ForegroundColor Red
        }
    }
}

# Create a list of unnecessary files and directories to clean up
$itemsToClean = @(
    # Python cache files
    @{Path="**/__pycache__"; Description="Python cache directories"},
    @{Path="**/*.pyc"; Description="Python compiled files"},
    @{Path="**/*.pyo"; Description="Python optimized files"},
    @{Path="**/*.pyd"; Description="Python binary files"},
    
    # Java build artifacts
    @{Path="**/target"; Description="Maven build directory"},
    @{Path="**/*.class"; Description="Java compiled classes"},
    @{Path="**/build"; Description="Java/Gradle build directory"},
    
    # JavaScript/Node.js artifacts
    @{Path="node_modules"; Description="Node.js dependencies"},
    @{Path="**/dist"; Description="JavaScript distribution files"},
    @{Path="**/.cache"; Description="Frontend build cache"},
    @{Path="**/.parcel-cache"; Description="Parcel cache"},
    
    # IDE and editor files
    @{Path="**/.idea"; Description="JetBrains IDE files"},
    @{Path="**/*.iml"; Description="IntelliJ project files"},
    @{Path="**/.vs"; Description="Visual Studio files"},
    @{Path="**/*.suo"; Description="Visual Studio user options"},
    @{Path="**/*.user"; Description="User-specific files"},
    
    # Logs and temporary files
    @{Path="**/logs"; Description="Log directories"},
    @{Path="**/*.log"; Description="Log files"},
    @{Path="**/tmp"; Description="Temporary directories"},
    @{Path="**/*.tmp"; Description="Temporary files"},
    @{Path="**/*.temp"; Description="Temporary files"},
    @{Path="**/thumbs.db"; Description="Windows thumbnail cache"},
    @{Path="**/.DS_Store"; Description="macOS folder attributes"},
    
    # Duplicate files
    @{Path="README_new.md"; Description="Duplicate README file"},
    
    # Other unnecessary files
    @{Path="**/*.bak"; Description="Backup files"},
    @{Path="**/*~"; Description="Temporary editor files"}
)

# Cleaning redundant files
Write-Host "🔍 Looking for redundant and temporary files..." -ForegroundColor Cyan

# Remove specific files identified as unnecessary
$specificFiles = @(
    @{Path="cleanup-simple.ps1"; Description="Simple cleanup script (replaced by enhanced version)"},
    @{Path="cleanup.ps1"; Description="Original cleanup script (replaced by enhanced version)"},
    @{Path="cleanup.sh"; Description="Shell cleanup script (replaced by enhanced PowerShell version)"},
    @{Path="README_new.md"; Description="Draft README file (content merged to README.md)"}
)

foreach ($item in $specificFiles) {
    Remove-SafeItem -Path $item.Path -Description $item.Description
}

# Recursive cleaning using file patterns
Write-Host "🔍 Scanning for cache files and build artifacts..." -ForegroundColor Cyan
foreach ($item in $itemsToClean) {
    $matchingItems = Get-ChildItem -Path $item.Path -ErrorAction SilentlyContinue -Force
    
    if ($matchingItems) {
        foreach ($match in $matchingItems) {
            Remove-SafeItem -Path $match.FullName -Description "$($item.Description) ($($match.Name))"
        }
    }
}

# Create .gitignore if it doesn't exist
if (-not (Test-Path ".gitignore")) {
    Write-Host "Creating .gitignore file..." -ForegroundColor Cyan
    
    $gitignoreContent = @'
# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
*.egg-info/
.installed.cfg
*.egg
venv/
env/
ENV/

# Java
target/
*.class
*.jar
*.war
*.ear
*.log
hs_err_pid*
.classpath
.project
.settings/
bin/
build/

# Node.js
node_modules/
npm-debug.log*
yarn-debug.log*
yarn-error.log*
.pnp/
.pnp.js
dist/
build/
coverage/
.cache/
.parcel-cache/
.env.local
.env.development.local
.env.test.local
.env.production.local

# IDE and Editor files
.idea/
*.iml
.vscode/
*.swp
*.swo
.vs/
*.suo
*.user
*.userosscache
*.sln.docstates
*~
.project
.classpath
.settings/

# Logs and temporary files
logs/
*.log
npm-debug.log*
yarn-debug.log*
yarn-error.log*
pids
*.pid
*.seed
*.pid.lock
tmp/
temp/
.sass-cache/

# OS files
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db
'@
    
    Set-Content -Path ".gitignore" -Value $gitignoreContent
    Write-Host ".gitignore file created successfully." -ForegroundColor Green
}

Write-Host "Project cleanup complete!" -ForegroundColor Green
Write-Host "Note: Some files may still be in use by running processes. Close all related applications and run again if needed." -ForegroundColor Yellow