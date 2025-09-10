# PowerShell script to generate and update JWT secrets for production

# Colors for PowerShell
$Green = @{ForegroundColor = "Green"}
$Yellow = @{ForegroundColor = "Yellow"}
$Red = @{ForegroundColor = "Red"}

Write-Host "Generating secure JWT secret for production..." @Yellow

# Generate a secure random JWT secret
try {
    # Try to generate using .NET crypto API
    $randomBytes = New-Object byte[] 48  # 48 bytes for a 64-character base64 string
    $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    $rng.GetBytes($randomBytes)
    $JWT_SECRET = [Convert]::ToBase64String($randomBytes)
}
catch {
    Write-Host "Failed to generate JWT secret using .NET crypto API." @Red
    Write-Host "Falling back to simpler method..." @Yellow
    
    # Fallback to simpler method
    $JWT_SECRET = -join ((65..90) + (97..122) + (48..57) + (33,35,36,37,38,42,43,45,46,58,63) | Get-Random -Count 64 | ForEach-Object {[char]$_})
}

Write-Host "JWT secret generated successfully." @Green

# Create a production properties file if it doesn't exist
$PROPERTIES_FILE = "backend-java/src/main/resources/application-production.properties"
if (-not (Test-Path $PROPERTIES_FILE)) {
    Write-Host "Creating production properties file: $PROPERTIES_FILE" @Yellow
    
    # Create the file with base settings
    @"
# Production configuration
spring.profiles.active=production

# Database Configuration
spring.datasource.url=jdbc:postgresql://postgres:5432/chatbot?ssl=true&sslmode=require
spring.datasource.username=chatbot_production_user
spring.datasource.password=change_this_to_secure_password

# JPA Configuration
spring.jpa.hibernate.ddl-auto=validate

# JWT Configuration
jwt.secret=$JWT_SECRET
jwt.expiration=1800000  # 30 minutes

# JWT Cookie settings
jwt.cookie.secure=true
jwt.cookie.httpOnly=true

# Strict CORS configuration
app.cors.allowed-origins=https://your-domain.com
app.cors.allowed-methods=GET,POST,PUT,DELETE
app.cors.allow-credentials=true

# Python AI Service Configuration
ai.service.url=https://your-ai-service-url
ai.service.analyze-endpoint=/analyze

# Logging Configuration
logging.level.root=WARN
logging.level.com.example.chatbot=INFO
logging.level.org.springframework.web=ERROR
logging.level.org.springframework.security=WARN

# Request limits
spring.servlet.multipart.max-file-size=1MB
spring.servlet.multipart.max-request-size=10MB

# Response Cache Configuration
cache.response.enabled=true
cache.response.ttl-minutes=60
cache.response.max-size=500
chat.response.cache-enabled=true
"@ | Out-File -FilePath $PROPERTIES_FILE -Encoding utf8

    Write-Host "Created production properties file with secure JWT secret." @Green
    Write-Host "WARNING: Please update other properties in $PROPERTIES_FILE before deploying to production." @Yellow
}
else {
    Write-Host "Updating JWT secret in existing properties file..." @Yellow
    
    # Read the file content
    $content = Get-Content -Path $PROPERTIES_FILE -Raw
    
    # Check if the file contains jwt.secret
    if ($content -match "jwt\.secret=") {
        # Update the existing jwt.secret property
        $content = $content -replace "jwt\.secret=.*", "jwt.secret=$JWT_SECRET"
        $content | Set-Content -Path $PROPERTIES_FILE -Encoding utf8
        Write-Host "JWT secret updated successfully." @Green
    }
    else {
        # Append jwt.secret property to the file
        Add-Content -Path $PROPERTIES_FILE -Value ""
        Add-Content -Path $PROPERTIES_FILE -Value "# JWT Configuration"
        Add-Content -Path $PROPERTIES_FILE -Value "jwt.secret=$JWT_SECRET"
        Write-Host "JWT secret added successfully." @Green
    }
}

# Create a secure properties instructions file
$INSTRUCTIONS_FILE = "backend-java/SECURE_PROPERTIES.md"
@"
# Secure Properties Configuration

This document provides instructions for managing secure properties in production.

## JWT Secret

The JWT secret has been automatically generated and stored in:
`src/main/resources/application-production.properties`

## Important Security Notes

1. **NEVER commit the application-production.properties file to version control**
2. Consider using environment variables instead of properties file:

   ```properties
   # In application-production.properties
   jwt.secret=\${JWT_SECRET_ENV:default_dev_only_secret}
   ```
   
   Then set the JWT_SECRET_ENV environment variable on your server.

3. For cloud platforms, use their secrets management:
   - AWS: AWS Secrets Manager
   - Azure: Azure Key Vault
   - GCP: Google Secret Manager
   - Heroku: Config Vars

## Database Credentials

Replace these placeholder values with your actual secure database credentials:

```properties
spring.datasource.url=jdbc:postgresql://your-db-host:5432/chatbot?ssl=true&sslmode=require
spring.datasource.username=chatbot_production_user
spring.datasource.password=your_secure_password
```

## Enabling Production Profile

To run with the production profile:

```bash
java -jar -Dspring.profiles.active=production app.jar
```

Or set the environment variable:

```bash
export SPRING_PROFILES_ACTIVE=production
java -jar app.jar
```
"@ | Out-File -FilePath $INSTRUCTIONS_FILE -Encoding utf8

Write-Host "Created secure properties instructions in: $INSTRUCTIONS_FILE" @Green
Write-Host "IMPORTANT: Read $INSTRUCTIONS_FILE for security best practices." @Yellow