#!/bin/bash
# Script untuk fix permission kong.yml dan restart Kong

echo "=========================================="
echo "🔧 Fix Kong Permission & Restart"
echo "=========================================="
echo ""

# Check current permission
echo "1️⃣ Current kong.yml permission:"
ls -la kong.yml
echo ""

# Fix permission
echo "2️⃣ Fixing kong.yml permission..."
chmod 644 kong.yml
echo "✅ Permission updated"
ls -la kong.yml
echo ""

# Validate kong.yml syntax
echo "3️⃣ Validating kong.yml syntax..."
docker run --rm \
    -v "$(pwd)/kong.yml:/kong.yml:ro" \
    kong:3.5.0 kong config -c /kong.yml parse 2>&1

if [ $? -eq 0 ]; then
    echo "✅ kong.yml syntax is valid"
else
    echo "❌ kong.yml has syntax errors!"
    exit 1
fi
echo ""

# Stop Kong
echo "4️⃣ Stopping Kong..."
docker-compose stop kong
docker-compose rm -f kong
echo ""

# Start Kong
echo "5️⃣ Starting Kong..."
docker-compose up -d kong

# Wait for Kong
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
echo ""

# Show Kong info
echo "7️⃣ Kong Information:"
echo "Container Status:"
docker ps | grep kong
echo ""

echo "Kong Status:"
curl -s http://localhost:8001/status 2>/dev/null | head -10 || echo "⚠️  Cannot connect yet"
echo ""

echo "Kong Services:"
curl -s http://localhost:8001/services 2>/dev/null | grep -E '"name"|"url"' | head -10 || echo "⚠️  Cannot fetch services yet"
echo ""

# Show recent logs
echo "8️⃣ Recent Kong Logs:"
docker logs --tail=20 kong 2>&1 | tail -20
echo ""

echo "=========================================="
echo "✅ Kong permission fix completed!"
echo "=========================================="

