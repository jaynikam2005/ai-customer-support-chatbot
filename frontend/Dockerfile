FROM node:18-alpine as builder

WORKDIR /app

# Install curl for healthcheck
RUN apk add --no-cache curl

# Copy package files
COPY package*.json ./
COPY bun.lockb* ./

# Handle different package managers
RUN if [ -f bun.lockb ]; then \
    npm install -g bun && bun install; \
  else \
    npm install; \
  fi

# Copy source code
COPY . .

# Set environment variable for build if needed
ARG VITE_API_URL
ENV VITE_API_URL=${VITE_API_URL}

# Build the application for production
RUN npm run build

# Production stage
FROM node:18-alpine as production

WORKDIR /app

# Install required packages
RUN apk add --no-cache curl

# Install a simple static file server
RUN npm install -g serve

# Copy the built application
COPY --from=builder /app/dist /app/dist

# Expose port
EXPOSE 3000
ENV PORT=3000

# Health check using dynamic port
HEALTHCHECK --interval=60s --timeout=30s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:${PORT:-3000} || exit 1

# Create a startup script
RUN echo '#!/bin/sh\n\
PORT=${PORT:-3000}\n\
exec serve -s dist -l $PORT' > /app/start.sh && \
    chmod +x /app/start.sh

# Start server (using production build)
CMD ["/app/start.sh"]