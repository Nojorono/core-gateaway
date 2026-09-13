#!/bin/bash
# Script untuk check status Kong Gateway

echo "=========================================="
echo "🔍 Kong Gateway Diagnostic Check"
echo "=========================================="
echo ""

# Check if Kong container is running
echo "1️⃣ Container Status:"
if docker ps | grep -q kong; then
    docker ps | grep kong
    echo "✅ Kong container is running"
else
    echo "❌ Kong container is NOT running"
    echo ""
    echo "Checking stopped containers..."
    docker ps -a | grep kong || echo "No Kong container found"
    exit 1
fi
echo ""

# Check port mapping
echo "2️⃣ Port Mapping:"
docker port kong 2>/dev/null || echo "❌ Cannot get port mapping"
echo ""

# Check if ports are listening
echo "3️⃣ Port Listening on Host:"
netstat -tlnp 2>/dev/null | grep -E "8000|8001" || ss -tlnp 2>/dev/null | grep -E "8000|8001" || echo "⚠️  Cannot check ports (netstat/ss not available)"
echo ""

# Test Kong Admin API from inside container
echo "4️⃣ Test Kong Admin API from Inside Container:"
docker exec kong curl -s http://localhost:8001/status 2>/dev/null | head -10 || echo "❌ Cannot connect to Kong Admin API from inside container"
echo ""

# Test Kong Admin API from host
echo "5️⃣ Test Kong Admin API from Host (localhost:8001):"
curl -s http://localhost:8001/status 2>&1 | head -10 || echo "❌ Cannot connect to Kong Admin API from host"
echo ""

# Test Kong Proxy from host
echo "6️⃣ Test Kong Proxy from Host (localhost:8000):"
curl -s -I http://localhost:8000/ 2>&1 | head -10 || echo "❌ Cannot connect to Kong Proxy from host"
echo ""

# Check Kong logs
echo "7️⃣ Recent Kong Logs (last 20 lines):"
docker logs --tail=20 kong 2>&1 | tail -20
echo ""

# Check docker-compose config
echo "8️⃣ Docker Compose Kong Config:"
grep -A 15 "kong:" docker-compose.yml | grep -E "ports:|KONG_" || echo "⚠️  Cannot find Kong config"
echo ""

echo "=========================================="
echo "✅ Diagnostic complete!"
echo "=========================================="

