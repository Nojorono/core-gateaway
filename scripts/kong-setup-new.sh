#!/bin/bash
# filepath: d:\belajar\api_gateway\core-gateaway\scripts\kong-setup-new.sh

echo "🔧 Setting up Kong services and routes..."

KONG_ADMIN_URL="http://localhost:8001"

# Wait for Kong to be ready
echo "Waiting for Kong to be ready..."
until $(curl --output /dev/null --silent --head --fail $KONG_ADMIN_URL); do
    printf '.'
    sleep 5
done
echo ""
echo "Kong is ready!"

# Function to safely delete existing resources
cleanup_existing() {
    echo "🧹 Cleaning up existing Kong configuration..."
    
    # Delete existing routes first (dependencies)
    echo "Deleting existing routes..."
    ROUTES=$(curl -s $KONG_ADMIN_URL/routes | grep -o '"id":"[^"]*"' | sed 's/"id":"//g' | sed 's/"//g')
    for route_id in $ROUTES; do
        curl -s -X DELETE $KONG_ADMIN_URL/routes/$route_id
    done
    
    # Delete existing plugins
    echo "Deleting existing plugins..."
    PLUGINS=$(curl -s $KONG_ADMIN_URL/plugins | grep -o '"id":"[^"]*"' | sed 's/"id":"//g' | sed 's/"//g')
    for plugin_id in $PLUGINS; do
        curl -s -X DELETE $KONG_ADMIN_URL/plugins/$plugin_id
    done
    
    # Delete existing services
    echo "Deleting existing services..."
    curl -s -X DELETE $KONG_ADMIN_URL/services/backend-ryo 2>/dev/null
    curl -s -X DELETE $KONG_ADMIN_URL/services/backend-md 2>/dev/null
    
    sleep 2
    echo "Cleanup completed!"
}

# Cleanup existing configuration
cleanup_existing

# Create backend-ryo service
echo "📦 Creating backend-ryo service..."
RESPONSE=$(curl -s -X POST $KONG_ADMIN_URL/services/ \
  --data "name=backend-ryo" \
  --data "url=http://backend-ryo:9002" \
  --data "connect_timeout=60000" \
  --data "write_timeout=60000" \
  --data "read_timeout=60000")

if echo "$RESPONSE" | grep -q '"id"'; then
    echo "✅ Backend-ryo service created successfully"
else
    echo "❌ Failed to create backend-ryo service: $RESPONSE"
fi

# Create route for backend-ryo
echo "🛣️ Creating backend-ryo route..."
RESPONSE=$(curl -s -X POST $KONG_ADMIN_URL/services/backend-ryo/routes \
  --data "paths[]=/ryo-api" \
  --data "strip_path=false" \
  --data "preserve_host=false")

if echo "$RESPONSE" | grep -q '"id"'; then
    echo "✅ Backend-ryo route created successfully"
else
    echo "❌ Failed to create backend-ryo route: $RESPONSE"
fi

# Create backend-md service
echo "📦 Creating backend-md service..."
RESPONSE=$(curl -s -X POST $KONG_ADMIN_URL/services/ \
  --data "name=backend-md" \
  --data "url=http://backend-md:9001" \
  --data "connect_timeout=60000" \
  --data "write_timeout=60000" \
  --data "read_timeout=60000")

if echo "$RESPONSE" | grep -q '"id"'; then
    echo "✅ Backend-md service created successfully"
else
    echo "❌ Failed to create backend-md service: $RESPONSE"
fi

# Create route for backend-md
echo "🛣️ Creating backend-md route..."
RESPONSE=$(curl -s -X POST $KONG_ADMIN_URL/services/backend-md/routes \
  --data "paths[]=/md-api" \
  --data "strip_path=true" \
  --data "preserve_host=false")

if echo "$RESPONSE" | grep -q '"id"'; then
    echo "✅ Backend-md route created successfully"
else
    echo "❌ Failed to create backend-md route: $RESPONSE"
fi

# Add rate limiting plugin
echo "⚡ Adding rate limiting plugin..."
RESPONSE=$(curl -s -X POST $KONG_ADMIN_URL/plugins/ \
  --data "name=rate-limiting" \
  --data "config.minute=1000" \
  --data "config.hour=10000" \
  --data "config.policy=local")

if echo "$RESPONSE" | grep -q '"id"'; then
    echo "✅ Rate limiting plugin added successfully"
else
    echo "❌ Failed to add rate limiting plugin: $RESPONSE"
fi

# Add CORS plugin with correct syntax
echo "🌐 Adding CORS plugin..."
RESPONSE=$(curl -s -X POST $KONG_ADMIN_URL/plugins/ \
  --data "name=cors" \
  --data "config.origins=*" \
  --data "config.methods=GET,POST,PUT,DELETE,OPTIONS,HEAD,PATCH" \
  --data "config.headers=Accept,Accept-Version,Content-Length,Content-MD5,Content-Type,Date,X-Auth-Token,Authorization,X-Forwarded-For,X-Forwarded-Proto,X-Forwarded-Prefix,X-Script-Name" \
  --data "config.credentials=true" \
  --data "config.max_age=3600")

if echo "$RESPONSE" | grep -q '"id"'; then
    echo "✅ CORS plugin added successfully"
else
    echo "❌ Failed to add CORS plugin: $RESPONSE"
fi

# Verify configuration
echo ""
echo "🔍 Verifying Kong configuration..."
echo "Services:"
curl -s $KONG_ADMIN_URL/services | jq '.data[] | {name: .name, url: .url}' 2>/dev/null || \
curl -s $KONG_ADMIN_URL/services | grep -o '"name":"[^"]*"' | sed 's/"name":"//g' | sed 's/"//g'

echo ""
echo "Routes:"
curl -s $KONG_ADMIN_URL/routes | jq '.data[] | {paths: .paths, strip_path: .strip_path}' 2>/dev/null || \
curl -s $KONG_ADMIN_URL/routes | grep -o '"paths":\["[^"]*"\]'

echo ""
echo "Plugins:"
curl -s $KONG_ADMIN_URL/plugins | jq '.data[] | {name: .name}' 2>/dev/null || \
curl -s $KONG_ADMIN_URL/plugins | grep -o '"name":"[^"]*"'

echo ""
echo "✅ Kong services and routes configured!"
echo ""
echo "📋 Available endpoints:"
echo "- http://localhost:8000/ryo-api/health/ → Backend-RYO Health"
echo "- http://localhost:8000/ryo-api/api/docs/ → Backend-RYO API Docs"
echo "- http://localhost:8000/md-api/ → Backend-MD"
echo "- http://api.kcsi.id/ryo-api/api/docs/ → Through Nginx"
echo ""
echo "🧪 Test commands:"
echo "curl -I http://localhost:8000/ryo-api/health/"
echo "curl -I http://localhost:8000/md-api/"
echo "curl -s http://localhost:8001/services | jq '.'"