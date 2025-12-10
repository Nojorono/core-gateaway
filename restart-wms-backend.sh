#!/bin/bash
# Script to fully restart backend-wms container with comprehensive cleanup

echo "🛑 Stopping backend-wms..."
docker-compose stop backend-wms

echo "🗑️  Removing backend-wms container..."
docker-compose rm -f backend-wms

echo "🧹 Cleaning up Docker images for backend-wms..."
docker images | grep "core-gateaway_backend-wms" | awk '{print $3}' | xargs -r docker rmi -f

echo "🧽 Pruning unused Docker resources..."
docker system prune -f

echo "📦 Pruning unused Docker volumes..."
docker volume prune -f

echo "🏗️  Rebuilding and starting backend-wms..."
docker-compose up -d --build backend-wms

echo "📊 Checking container status..."
docker-compose ps backend-wms

echo "📋 Showing recent logs..."
docker-compose logs --tail=20 backend-wms

echo "✅ Done! backend-wms has been fully restarted with cleanup."
