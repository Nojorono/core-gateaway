#!/bin/bash
# filepath: d:\belajar\api_gateway\core-gateaway\test-auth-endpoints.sh

echo "🧪 Testing Authentication Endpoints..."

BASE_URL="http://api.localhost/ryo-api"

echo "1. Health Check:"
curl -s "$BASE_URL/health/" | jq '.' || echo "Failed"

echo ""
echo "2. API Documentation:"
curl -I "$BASE_URL/docs/" | grep "HTTP"

echo ""
echo "3. Auth Token Endpoint (correct path):"
curl -I "$BASE_URL/token/" | grep "HTTP"

echo ""
echo "4. Auth Token Endpoint (old path for comparison):"
curl -I "$BASE_URL/auth/token/" | grep "HTTP"

echo ""
echo "5. Test Token Request:"
curl -X POST "$BASE_URL/token/" \
  -H "Content-Type: application/json" \
  -d '{"username": "admin", "password": "test123"}' \
  -s | jq '.' || echo "Failed - check credentials"

echo ""
echo "6. Direct Container Test:"
curl -I "http://localhost:9002/token/" | grep "HTTP"

echo ""
echo "7. Through Kong Gateway:"
curl -I "http://localhost:8000/ryo-api/token/" | grep "HTTP"

echo ""
echo "✅ Test completed!"
echo ""
echo "📋 Correct endpoints:"
echo "- Auth Token: $BASE_URL/token/"
echo "- Token Refresh: $BASE_URL/token/refresh/"
echo "- API Docs: $BASE_URL/docs/"
echo "- Login: $BASE_URL/login/"