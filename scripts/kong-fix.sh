#!/bin/bash
# Script untuk fix dan restart Kong Gateway

echo "=========================================="
echo "🔧 Kong Gateway Fix & Restart"
echo "=========================================="
echo ""

# Check if Kong container exists
echo "1️⃣ Checking Kong container..."
if docker ps -a | grep -q kong; then
    echo "✅ Kong container found"
    docker ps -a | grep kong
else
    echo "❌ Kong container not found"
    echo "Starting Kong with docker-compose..."
    docker-compose up -d kong
    exit 0
fi
echo ""

# Stop Kong
echo "2️⃣ Stopping Kong..."
docker-compose stop kong
sleep 2
echo ""

# Remove Kong container
echo "3️⃣ Removing Kong container..."
docker-compose rm -f kong
echo ""

# Check Kong dependencies
echo "4️⃣ Checking Kong dependencies..."
if ! docker ps | grep -q kong-database; then
    echo "⚠️  Kong database not running, starting it..."
    docker-compose up -d kong-database
    sleep 5
fi

if ! docker ps | grep -q kong-migrations; then
    echo "ℹ️  Kong migrations will run on next start"
fi
echo ""

# Start Kong
echo "5️⃣ Starting Kong..."
docker-compose up -d kong

# Wait for Kong to be ready
echo "⏳ Waiting for Kong to initialize..."
sleep 10

# Check Kong status
echo ""
echo "6️⃣ Checking Kong status..."
MAX_RETRIES=10
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if curl -s -f http://localhost:8001/status > /dev/null 2>&1; then
        echo "✅ Kong is healthy and ready!"
        break
    else
        RETRY_COUNT=$((RETRY_COUNT + 1))
        echo "⏳ Waiting for Kong... ($RETRY_COUNT/$MAX_RETRIES)"
        sleep 3
    fi
done

if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
    echo "⚠️  Kong may not be fully ready yet"
fi
echo ""

# Show Kong info
echo "7️⃣ Kong Information:"
echo "Container Status:"
docker ps | grep kong || echo "❌ Kong not running"
echo ""

echo "Port Mapping:"
docker port kong 2>/dev/null || echo "⚠️  Cannot get port info"
echo ""

echo "Kong Status (from Admin API):"
curl -s http://localhost:8001/status 2>/dev/null | head -5 || echo "⚠️  Cannot connect to Admin API"
echo ""

echo "Kong Services:"
curl -s http://localhost:8001/services 2>/dev/null | grep -E '"name"|"url"' | head -10 || echo "⚠️  Cannot fetch services"
echo ""

# Show logs if there are errors
echo "8️⃣ Recent Kong Logs (checking for errors):"
docker logs --tail=30 kong 2>&1 | grep -i error | tail -10 || echo "✅ No errors found in recent logs"
echo ""

echo "=========================================="
echo "✅ Kong fix completed!"
echo "=========================================="
echo ""
echo "📝 Test commands:"
echo "   curl http://localhost:8001/status"
echo "   curl http://localhost:8001/services"
echo "   curl -I http://localhost:8000/service-wms/api"

