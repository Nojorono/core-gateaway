#!/bin/bash
# Script untuk reload Kong configuration setelah update kong.yml

echo "🔄 Reloading Kong Configuration..."
echo ""

# Check if Kong container is running
if ! docker ps | grep -q kong; then
    echo "❌ Kong container is not running!"
    exit 1
fi

# Method 1: Restart Kong container (recommended for declarative config)
echo "1️⃣ Restarting Kong container..."
docker-compose restart kong

# Wait for Kong to be ready
echo "⏳ Waiting for Kong to be ready..."
sleep 5

# Check Kong health
echo "2️⃣ Checking Kong health..."
KONG_ADMIN="http://localhost:8001"
if curl -s -f "$KONG_ADMIN/status" > /dev/null; then
    echo "✅ Kong is healthy!"
else
    echo "⚠️  Kong health check failed, but container is running"
fi

# Show Kong services
echo ""
echo "3️⃣ Current Kong Services:"
curl -s "$KONG_ADMIN/services" | grep -E '"name"|"url"' | head -20 || echo "⚠️  Cannot fetch services"

echo ""
echo "✅ Kong reload completed!"
echo ""
echo "📝 Test your endpoint:"
echo "   curl -I http://localhost:8000/service-wms/api"

