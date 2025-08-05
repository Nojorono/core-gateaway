#!/bin/bash
# filepath: d:\belajar\api_gateway\core-gateaway\restart-backend-md.sh

echo "🔄 Restarting Backend-md Clean..."

# Stop backend-md container
echo "⏹️ Stopping backend-md container..."
docker-compose stop backend-md

# Remove backend-md container
echo "🗑️ Removing backend-md container..."
docker-compose rm -f backend-md

# Remove backend-md image (optional - uncomment if needed)
# echo "🗑️ Removing backend-md image..."
# docker rmi core-gateaway_backend-md 2>/dev/null || echo "Image not found, skipping..."

# Clean up dangling images
echo "🧹 Cleaning up dangling images..."
docker image prune -f

# Pull latest image (if using external image)
echo "📥 Pulling latest images..."
docker-compose pull backend-md

# Rebuild backend-md (if building from Dockerfile)
echo "🔨 Rebuilding backend-md..."
docker-compose build --no-cache backend-md

# Start backend-md with fresh container
echo "🚀 Starting backend-md..."
docker-compose up -d backend-md

# Wait for container to be ready
echo "⏳ Waiting for backend-md to be ready..."
sleep 10

# Check container status
echo "📊 Checking container status..."
docker-compose ps backend-md

# Show logs
echo "📋 Showing recent logs..."
docker-compose logs --tail=50 backend-md

echo "✅ Backend-md restart completed!"
echo "🔍 Monitor logs with: docker-compose logs -f backend-md"