#!/bin/bash
# Quick fix untuk Kong permission issue

echo "🔧 Quick Fix Kong Permission..."

# Fix permission
chmod 644 kong.yml

# Stop and remove Kong
docker-compose stop kong 2>/dev/null
docker-compose rm -f kong 2>/dev/null

# Start Kong
docker-compose up -d kong

echo "⏳ Waiting 10 seconds..."
sleep 10

# Check status
if curl -s http://localhost:8001/status > /dev/null 2>&1; then
    echo "✅ Kong is running!"
    curl -s http://localhost:8001/status | head -5
else
    echo "⚠️  Kong may still be starting. Check logs:"
    docker logs kong --tail=20
fi

