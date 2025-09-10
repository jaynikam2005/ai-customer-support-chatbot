# Secure Properties Configuration

This document provides instructions for managing secure properties in production.

## JWT Secret

The JWT secret has been automatically generated and stored in:
src/main/resources/application-production.properties

## Important Security Notes

1. **NEVER commit the application-production.properties file to version control**
2. Consider using environment variables instead of properties file:

   `properties
   # In application-production.properties
   jwt.secret=\
   `
   
   Then set the JWT_SECRET_ENV environment variable on your server.

3. For cloud platforms, use their secrets management:
   - AWS: AWS Secrets Manager
   - Azure: Azure Key Vault
   - GCP: Google Secret Manager
   - Heroku: Config Vars

## Database Credentials

Replace these placeholder values with your actual secure database credentials:

`properties
spring.datasource.url=jdbc:postgresql://your-db-host:5432/chatbot?ssl=true&sslmode=require
spring.datasource.username=chatbot_production_user
spring.datasource.password=your_secure_password
`

## Enabling Production Profile

To run with the production profile:

`ash
java -jar -Dspring.profiles.active=production app.jar
`

Or set the environment variable:

`ash
export SPRING_PROFILES_ACTIVE=production
java -jar app.jar
`
