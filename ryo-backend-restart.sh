#!/bin/bash

# Docker Cleanup and Restart Script for RYO
echo "🧹 BACKEND RYO Docker Cleanup & Restart"
echo "==============================="

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }

# Stop and remove only backend containers
print_status "Stopping backend containers..."
docker-compose stop backend-ryo || true
docker-compose rm -f backend-ryo || true

# Remove backend images
#docker rmi -f $(docker images -q ryo_app_backend) 2>/dev/null || true

# Build and start only backend
print_status "Building and starting backend containers..."
docker-compose build --no-cache backend-ryo && docker-compose up -d backend-ryo

# Wait a moment
sleep 5

# Check status
print_status "Checking container status..."
docker-compose ps
docker-compose logs backend-ryo 

print_success "Cleanup and restart completed!"
