#!/bin/bash
# filepath: d:\belajar\api_gateway\core-gateaway\restart-backend-ryo.sh

echo "🔄 Restarting Backend-RYO Clean..."

# Stop backend-ryo container
echo "⏹️ Stopping backend-ryo container..."
docker-compose stop backend-ryo

# Remove backend-ryo container
echo "🗑️ Removing backend-ryo container..."
docker-compose rm -f backend-ryo

# Remove backend-ryo image (optional - uncomment if needed)
# echo "🗑️ Removing backend-ryo image..."
# docker rmi core-gateaway_backend-ryo 2>/dev/null || echo "Image not found, skipping..."

# Clean up dangling images
echo "🧹 Cleaning up dangling images..."
docker image prune -f

# Pull latest image (if using external image)
echo "📥 Pulling latest images..."
docker-compose pull backend-ryo

# Rebuild backend-ryo (if building from Dockerfile)
echo "🔨 Rebuilding backend-ryo..."
docker-compose build --no-cache backend-ryo

# Start backend-ryo with fresh container
echo "🚀 Starting backend-ryo..."
docker-compose up -d backend-ryo

# Wait for container to be ready
echo "⏳ Waiting for backend-ryo to be ready..."
sleep 10

# Check container status
echo "📊 Checking container status..."
docker-compose ps backend-ryo

# Show logs
echo "📋 Showing recent logs..."
docker-compose logs --tail=50 backend-ryo

echo "✅ Backend-RYO restart completed!"
echo "🔍 Monitor logs with: docker-compose logs -f backend-ryo"