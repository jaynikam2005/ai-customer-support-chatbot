# Production Security Configuration Guide

This document provides best practices and instructions for securing your AI Customer Support Chatbot deployment in production environments.

## Table of Contents

1. [API Keys and Secrets](#api-keys-and-secrets)
2. [Database Security](#database-security)
3. [Network Security](#network-security)
4. [JWT Security](#jwt-security)
5. [CORS Configuration](#cors-configuration)
6. [Input Validation](#input-validation)
7. [Content Security Policy](#content-security-policy)
8. [Regular Updates](#regular-updates)
9. [Monitoring and Logging](#monitoring-and-logging)

## API Keys and Secrets

### Google Gemini API Key

1. Create a separate API key for each environment (dev, staging, production)
2. Set usage quotas to prevent unexpected charges
3. Restrict API key usage to specific domains and IP addresses
4. Store API keys in environment variables or a secure secrets manager
5. Rotate API keys periodically

### JWT Secret

1. Generate a strong random secret for production:

```bash
# Generate a secure random string
openssl rand -base64 64
```

2. Store the JWT secret in environment variables
3. Use different secrets for different environments
4. Consider using asymmetric keys (RS256) instead of symmetric keys (HS256) for larger deployments

## Database Security

### Connection Security

1. Enable SSL/TLS for database connections
2. Update the JDBC URL to use SSL:

```
jdbc:postgresql://hostname:5432/chatbot?ssl=true&sslmode=require
```

3. For managed PostgreSQL services, follow their specific SSL configuration guidelines

### Credentials

1. Create a dedicated database user for each environment
2. Grant only the minimum required permissions:

```sql
-- Create a dedicated user with a strong password
CREATE USER chatbot_production_user WITH PASSWORD 'strong-random-password';

-- Grant limited privileges
GRANT CONNECT ON DATABASE chatbot TO chatbot_production_user;
GRANT USAGE ON SCHEMA public TO chatbot_production_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO chatbot_production_user;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO chatbot_production_user;

-- Make sure new tables will have the same grants
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO chatbot_production_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT USAGE, SELECT ON SEQUENCES TO chatbot_production_user;
```

3. Do not use the default postgres user or other admin users for your application
4. Store database credentials in environment variables, never in code

### Network Access

1. Restrict database access to only required IP addresses or networks
2. For cloud-managed databases, use private networking when possible
3. Consider using a VPC or similar private network for your services
4. Enable IP allow-listing if supported by your database provider

## Network Security

### HTTPS Configuration

1. Enable HTTPS for all services
2. Use strong TLS configuration (TLS 1.2+ only, strong cipher suites)
3. Set up HTTP to HTTPS redirection
4. Configure HSTS (HTTP Strict Transport Security)

Example nginx configuration for the frontend:

```nginx
server {
    listen 80;
    server_name your-domain.com;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl http2;
    server_name your-domain.com;
    
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers 'ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384';
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    
    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### Load Balancing and Rate Limiting

1. Use a CDN or load balancer in front of your services
2. Implement rate limiting to prevent abuse
3. Configure request timeouts appropriately

Example rate limiting with nginx:

```nginx
http {
    limit_req_zone $binary_remote_addr zone=api:10m rate=5r/s;
    
    server {
        # other configuration...
        
        location /api/ {
            limit_req zone=api burst=10 nodelay;
            proxy_pass http://backend_servers;
        }
    }
}
```

## JWT Security

1. Update the JWT configuration in Java backend:

```properties
# application-production.properties

# Use a strong secret (store in environment variable)
jwt.secret=${JWT_SECRET:defaultsecretfordevonly}

# Reduce token lifetime for production
jwt.expiration=1800000  # 30 minutes

# Enable secure and http-only flags for cookies
jwt.cookie.secure=true
jwt.cookie.httpOnly=true
```

2. Implement token refresh mechanism for longer sessions
3. Include token validation checks in critical endpoints
4. Add claims validation and audience verification

## CORS Configuration

1. Restrict CORS to specific domains for production:

Java Backend (application-production.properties):
```properties
# Strict CORS configuration for production
app.cors.allowed-origins=https://your-domain.com
app.cors.allowed-methods=GET,POST,PUT,DELETE
app.cors.allow-credentials=true
```

Python Backend (.env.production):
```
# CORS settings for production
ALLOWED_ORIGINS=https://your-domain.com
```

2. Don't use wildcard (*) origins in production
3. Enable credentials only for trusted origins
4. Verify that preflight requests are handled correctly

## Input Validation

1. Implement strict input validation for all API endpoints
2. Sanitize user inputs to prevent XSS and injection attacks
3. Set appropriate request size limits

Java Backend:
```properties
# Limit request sizes
spring.servlet.multipart.max-file-size=1MB
spring.servlet.multipart.max-request-size=10MB
```

Python Backend:
```python
# Add to FastAPI app configuration
app = FastAPI(
    # ... existing configuration
    max_request_size=1024 * 1024  # 1 MB
)
```

## Content Security Policy

Add Content Security Policy headers to frontend responses:

```javascript
// Add to frontend server or as response headers
const cspHeaders = {
    'Content-Security-Policy': 
        "default-src 'self'; " +
        "script-src 'self'; " +
        "style-src 'self' 'unsafe-inline'; " +
        "img-src 'self' data:; " +
        "connect-src 'self' https://your-api-domain.com; " +
        "font-src 'self'; " +
        "object-src 'none'; " +
        "media-src 'self'; " +
        "frame-src 'none'; " +
        "base-uri 'self'; " +
        "form-action 'self';"
};

// Apply headers to responses
```

## Regular Updates

1. Set up a process to regularly update dependencies
2. Use tools like Dependabot or Snyk to automate security updates
3. Stay informed about security advisories for your dependencies

## Monitoring and Logging

1. Implement centralized logging
2. Set up monitoring for suspicious activities
3. Configure alerts for unusual patterns
4. Use log levels appropriately

Java Backend:
```properties
# Logging configuration
logging.level.root=WARN
logging.level.com.example.chatbot=INFO
logging.level.org.springframework.web=ERROR
logging.level.org.springframework.security=WARN

# Centralized logging (example for ELK stack)
logging.logstash.enabled=true
logging.logstash.host=your-logstash-host
logging.logstash.port=5000
```

Python Backend:
```python
# Configure logging
import logging
from pythonjsonlogger import jsonlogger

logger = logging.getLogger()
logHandler = logging.StreamHandler()
formatter = jsonlogger.JsonFormatter('%(timestamp)s %(level)s %(name)s %(message)s')
logHandler.setFormatter(formatter)
logger.addHandler(logHandler)
logger.setLevel(logging.INFO)
```

---

**Important:** This document provides general security guidelines. Adapt them to your specific deployment environment and requirements. Consider engaging a security professional to review your production deployment.