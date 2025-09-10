#!/bin/bash

# Build script for Render deployment
echo "Building frontend for production deployment..."

# Install dependencies
npm ci

# Build the application
npm run build

# Setup serve for production hosting
npm install -g serve

echo "Frontend build completed successfully!"