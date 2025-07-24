#!/bin/bash
# kong-setup-new.sh

echo "🔧 Setting up Kong services and routes..."

KONG_ADMIN_URL="http://localhost:8001"

# Wait for Kong to be ready
echo "Waiting for Kong to be ready..."
until $(curl --output /dev/null --silent --head --fail $KONG_ADMIN_URL); do
    printf '.'
    sleep 5
done
echo "Kong is ready!"

# ✅ FIX: Create backend-ryo service dengan strip_path=false
echo "Creating backend-ryo service..."
curl -i -X POST $KONG_ADMIN_URL/services/ \
  --data "name=backend-ryo" \
  --data "url=http://backend-ryo:9002"

# Create route for backend-ryo (matches Django's FORCE_SCRIPT_NAME)
echo "Creating backend-ryo route..."
curl -i -X POST $KONG_ADMIN_URL/services/backend-ryo/routes \
  --data "paths[]=/ryo-api" \
  --data "strip_path=false"

# Create backend-md service
echo "Creating backend-md service..."
curl -i -X POST $KONG_ADMIN_URL/services/ \
  --data "name=backend-md" \
  --data "url=http://backend-md:9001"

# Create route for backend-md
echo "Creating backend-md route..."
curl -i -X POST $KONG_ADMIN_URL/services/backend-md/routes \
  --data "paths[]=/md-api" \
  --data "strip_path=true"

# Add rate limiting plugin (optional)
echo "Adding rate limiting..."
curl -i -X POST $KONG_ADMIN_URL/plugins/ \
  --data "name=rate-limiting" \
  --data "config.minute=1000" \
  --data "config.hour=10000"

# Add CORS plugin
echo "Adding CORS plugin..."
curl -i -X POST $KONG_ADMIN_URL/plugins/ \
  --data "name=cors" \
  --data "config.origins=https://api.kcsi.id,https://ryo.kcsi.id,https://apiryo.kcsi.id" \
  --data "config.methods=GET,POST,PUT,DELETE,OPTIONS" \
  --data "config.headers=Accept,Accept-Version,Content-Length,Content-MD5,Content-Type,Date,X-Auth-Token,Authorization"

echo "✅ Kong services and routes configured!"
echo ""
echo "Available endpoints:"
echo "- http://api.kcsi.id/ryo-api/api/docs/ → Backend-RYO"
echo "- http://api.kcsi.id/md-api/ → Backend-MD"
echo "- http://api.kcsi.id/grafana/ → Grafana"
echo "- http://api.kcsi.id/prometheus/ → Prometheus"
echo "- http://api.kcsi.id/kong-admin/ → Kong Admin API"
