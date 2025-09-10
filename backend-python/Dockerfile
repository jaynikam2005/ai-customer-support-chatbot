FROM python:3.13-slim

WORKDIR /workspace

# Install system dependencies including curl for healthcheck
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy .env file
COPY .env .

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

# Start the application
CMD ["python", "-m", "uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "5000"]