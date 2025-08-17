#!/bin/bash
# Script to fully restart service-meta container with comprehensive cleanup

echo "🛑 Stopping service-meta..."
docker-compose stop service-meta

echo "🗑️  Removing service-meta container..."
docker-compose rm -f service-meta

echo "🧹 Cleaning up Docker images for service-meta..."
docker images | grep "core-gateaway_service-meta" | awk '{print $3}' | xargs -r docker rmi -f

echo "🧽 Pruning unused Docker resources..."
docker system prune -f

echo "📦 Pruning unused Docker volumes..."
docker volume prune -f

echo "🏗️  Rebuilding and starting service-meta..."
docker-compose up -d --build service-meta

echo "📊 Checking container status..."
docker-compose ps service-meta

echo "📋 Showing recent logs..."
docker-compose logs --tail=20 service-meta

echo "✅ Done! Service-meta has been fully restarted with cleanup."
