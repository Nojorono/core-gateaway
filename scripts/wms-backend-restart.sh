#!/bin/bash
# filepath: d:\belajar\api_gateway\core-gateaway\wms-backend-restart.sh

echo "🔄 Restarting Backend-WMS Clean..."

# Stop backend-wms container
echo "⏹️ Stopping backend-wms container..."
docker-compose stop backend-wms

# Remove backend-wms container
echo "🗑️ Removing backend-wms container..."
docker-compose rm -f backend-wms

# Remove backend-wms image (optional - uncomment if needed)
# echo "🗑️ Removing backend-wms image..."
# docker rmi core-gateaway_backend-wms 2>/dev/null || echo "Image not found, skipping..."

# Clean up dangling images
echo "🧹 Cleaning up dangling images..."
docker image prune -f

# Pull latest image (if using external image)
echo "📥 Pulling latest images..."
docker-compose pull backend-wms

# Rebuild backend-wms (if building from Dockerfile)
echo "🔨 Rebuilding backend-wms..."
docker-compose build --no-cache backend-wms

# Start backend-wms with fresh container
echo "🚀 Starting backend-wms..."
docker-compose up -d backend-wms

# Wait for container to be ready
echo "⏳ Waiting for backend-wms to be ready..."
sleep 10

# Check container status
echo "📊 Checking container status..."
docker-compose ps backend-wms

# Show logs
echo "📋 Showing recent logs..."
docker-compose logs --tail=50 backend-wms

echo "✅ Backend-WMS restart completed!"
echo "🔍 Monitor logs with: docker-compose logs -f backend-wms"