FROM python:3.13-slim

WORKDIR /workspace

# Install system dependencies including curl for healthcheck
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install python-dotenv first to handle environment variables
RUN pip install --no-cache-dir python-dotenv

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy .env file if it exists, otherwise use .env.sample
COPY .env* ./
RUN if [ ! -f .env ] && [ -f .env.sample ]; then \
      cp .env.sample .env; \
    fi

# Copy application code
COPY app/ ./app/

# Create __init__.py files
RUN touch app/__init__.py

# Expose port
EXPOSE 5000

# Set environment variables
ENV PYTHONPATH="/workspace"
ENV PYTHONUNBUFFERED=1

# Health check
HEALTHCHECK --interval=60s --timeout=30s --start-period=120s --retries=5 \
  CMD curl -f http://localhost:5000/health || exit 1

# Create a startup script that reads environment variables
RUN echo '#!/bin/sh\n\
HOST=${HOST:-0.0.0.0}\n\
PORT=${PORT:-5000}\n\
exec python -m uvicorn app.main:app --host $HOST --port $PORT' > /workspace/start.sh && \
    chmod +x /workspace/start.sh

# Start the application
CMD ["/workspace/start.sh"]