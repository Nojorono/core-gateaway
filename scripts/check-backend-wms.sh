#!/bin/bash
# Script untuk check status backend-wms dan troubleshoot

echo "=========================================="
echo "🔍 Backend-WMS Diagnostic Check"
echo "=========================================="
echo ""

# Check container status
echo "1️⃣ Container Status:"
docker ps | grep backend-wms || echo "❌ Container not running"
echo ""

# Check port mapping
echo "2️⃣ Port Mapping:"
docker port backend-wms 2>/dev/null || echo "❌ Cannot get port mapping"
echo ""

# Check if port is listening inside container
echo "3️⃣ Port Listening Inside Container:"
docker exec backend-wms netstat -tlnp 2>/dev/null | grep -E "3000|9004" || docker exec backend-wms ss -tlnp 2>/dev/null | grep -E "3000|9004" || echo "⚠️  Cannot check port (netstat/ss not available)"
echo ""

# Check environment variables
echo "4️⃣ Environment Variables:"
docker exec backend-wms env | grep -E "PORT|NODE_ENV" || echo "⚠️  Cannot get env vars"
echo ""

# Check logs
echo "5️⃣ Recent Logs (last 20 lines):"
docker logs --tail=20 backend-wms 2>&1 | tail -20
echo ""

# Test from inside container
echo "6️⃣ Test from Inside Container:"
docker exec backend-wms wget -qO- http://localhost:3000/api 2>/dev/null | head -5 || docker exec backend-wms curl -s http://localhost:3000/api | head -5 || echo "❌ Cannot connect from inside container"
echo ""

# Test from host
echo "7️⃣ Test from Host (localhost:9004):"
curl -I http://localhost:9004/api 2>&1 | head -10 || echo "❌ Cannot connect from host"
echo ""

# Check docker-compose config
echo "8️⃣ Docker Compose Port Config:"
grep -A 5 "backend-wms:" docker-compose.yml | grep -E "ports:|9004" || echo "⚠️  Cannot find port config"
echo ""

echo "=========================================="
echo "✅ Diagnostic complete!"
echo "=========================================="

