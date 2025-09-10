#!/bin/bash
# Script to generate and update JWT secrets for production

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Generating secure JWT secret for production...${NC}"

# Generate a secure random JWT secret
JWT_SECRET=$(openssl rand -base64 64)
if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to generate JWT secret. Make sure OpenSSL is installed.${NC}"
    exit 1
fi

echo -e "${GREEN}JWT secret generated successfully.${NC}"

# Create a production properties file if it doesn't exist
PROPERTIES_FILE="backend-java/src/main/resources/application-production.properties"
if [ ! -f "$PROPERTIES_FILE" ]; then
    echo -e "${YELLOW}Creating production properties file: $PROPERTIES_FILE${NC}"
    
    # Create the file with base settings
    cat > "$PROPERTIES_FILE" << EOF
# Production configuration
spring.profiles.active=production

# Database Configuration
spring.datasource.url=jdbc:postgresql://postgres:5432/chatbot?ssl=true&sslmode=require
spring.datasource.username=chatbot_production_user
spring.datasource.password=change_this_to_secure_password

# JPA Configuration
spring.jpa.hibernate.ddl-auto=validate

# JWT Configuration
jwt.secret=${JWT_SECRET}
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
EOF

    echo -e "${GREEN}Created production properties file with secure JWT secret.${NC}"
    echo -e "${YELLOW}WARNING: Please update other properties in $PROPERTIES_FILE before deploying to production.${NC}"
else
    echo -e "${YELLOW}Updating JWT secret in existing properties file...${NC}"
    
    # Check if the file contains jwt.secret
    if grep -q "jwt.secret" "$PROPERTIES_FILE"; then
        # Update the existing jwt.secret property
        sed -i "s/jwt.secret=.*/jwt.secret=${JWT_SECRET}/" "$PROPERTIES_FILE"
        echo -e "${GREEN}JWT secret updated successfully.${NC}"
    else
        # Append jwt.secret property to the file
        echo "" >> "$PROPERTIES_FILE"
        echo "# JWT Configuration" >> "$PROPERTIES_FILE"
        echo "jwt.secret=${JWT_SECRET}" >> "$PROPERTIES_FILE"
        echo -e "${GREEN}JWT secret added successfully.${NC}"
    fi
fi

# Create a secure properties instructions file
INSTRUCTIONS_FILE="backend-java/SECURE_PROPERTIES.md"
cat > "$INSTRUCTIONS_FILE" << EOF
# Secure Properties Configuration

This document provides instructions for managing secure properties in production.

## JWT Secret

The JWT secret has been automatically generated and stored in:
\`src/main/resources/application-production.properties\`

## Important Security Notes

1. **NEVER commit the application-production.properties file to version control**
2. Consider using environment variables instead of properties file:

   ```properties
   # In application-production.properties
   jwt.secret=${JWT_SECRET_ENV:default_dev_only_secret}
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
EOF

echo -e "${GREEN}Created secure properties instructions in: $INSTRUCTIONS_FILE${NC}"
echo -e "${YELLOW}IMPORTANT: Read $INSTRUCTIONS_FILE for security best practices.${NC}"