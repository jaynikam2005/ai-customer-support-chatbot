FROM node:18-alpine

WORKDIR /app

# Install curl for healthcheck
RUN apk add --no-cache curl

# Copy package files
COPY package*.json ./

# Handle different package managers
RUN if [ -f bun.lockb ]; then \
    npm install -g bun && bun install; \
  else \
    npm install; \
  fi

# Copy source code
COPY . .

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=60s --timeout=30s --start-period=120s --retries=3 \
  CMD curl -f http://localhost:3000 || exit 1

# Start development server
CMD ["npm", "run", "dev", "--", "--host", "0.0.0.0", "--port", "3000"]