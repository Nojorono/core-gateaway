#!/bin/bash
# Skrip setup Kong Gateway untuk arsitektur sesuai diagram (hybrid auth + plugin best practice + monitoring)

KONG_ADMIN_URL="http://localhost:8001"

# Enable prometheus plugin globally
curl -i -X POST $KONG_ADMIN_URL/plugins --data "name=prometheus"

# Add backend-md service
curl -i -X POST $KONG_ADMIN_URL/services \
  --data name=backend-md-api \
  --data url='http://backend-md:9001'

# Add backend-ryo service
curl -i -X POST $KONG_ADMIN_URL/services \
  --data name=backend-ryo-api \
  --data url='http://backend-ryo:9002'

# Add meta service
curl -i -X POST $KONG_ADMIN_URL/services \
  --data name=service-meta \
  --data url='http://service-meta:9003'

# Add wms service
curl -i -X POST $KONG_ADMIN_URL/services \
  --data name=service-wms \
  --data url='http://service-wms:9004'

# Add prefixed route for backend-md
curl -i -X POST $KONG_ADMIN_URL/services/backend-md-api/routes \
  --data 'paths[]=/md-backend-api' \
  --data 'strip_path=true'

# Add prefixed route for backend-ryo
curl -i -X POST $KONG_ADMIN_URL/services/backend-ryo-api/routes \
  --data 'paths[]=/ryo-backend-api' \
  --data 'strip_path=true'

# Add prefixed route for meta service
curl -i -X POST $KONG_ADMIN_URL/services/meta-api/routes \
  --data 'paths[]=/meta-api' \
  --data 'strip_path=true'

# Add prefixed route for wms service
curl -i -X POST $KONG_ADMIN_URL/services/wms-api/routes \
  --data 'paths[]=/wms-api' \
  --data 'strip_path=true'

# Plugins for backend-md
curl -i -X POST $KONG_ADMIN_URL/services/backend-md-api/plugins --data "name=prometheus"
curl -i -X POST $KONG_ADMIN_URL/services/backend-md-api/plugins --data "name=rate-limiting" --data "config.minute=60"
curl -i -X POST $KONG_ADMIN_URL/services/backend-md-api/plugins --data "name=cors"
curl -i -X POST $KONG_ADMIN_URL/services/backend-md-api/plugins --data "name=request-size-limiting" --data "config.allowed_payload_size=128"

# Plugins for backend-ryo
curl -i -X POST $KONG_ADMIN_URL/services/backend-ryo-api/plugins --data "name=prometheus"
curl -i -X POST $KONG_ADMIN_URL/services/backend-ryo-api/plugins --data "name=rate-limiting" --data "config.minute=60"
curl -i -X POST $KONG_ADMIN_URL/services/backend-ryo-api/plugins --data "name=cors"
curl -i -X POST $KONG_ADMIN_URL/services/backend-ryo-api/plugins --data "name=request-size-limiting" --data "config.allowed_payload_size=128"

# Plugins for wms service
curl -i -X POST $KONG_ADMIN_URL/services/wms-api/plugins --data "name=prometheus"
curl -i -X POST $KONG_ADMIN_URL/services/wms-api/plugins --data "name=rate-limiting" --data "config.minute=60"
curl -i -X POST $KONG_ADMIN_URL/services/wms-api/plugins --data "name=cors"
curl -i -X POST $KONG_ADMIN_URL/services/wms-api/plugins --data "name=request-size-limiting" --data "config.allowed_payload_size=128"

# Plugins for meta service
curl -i -X POST $KONG_ADMIN_URL/services/meta-api/plugins --data "name=prometheus"
curl -i -X POST $KONG_ADMIN_URL/services/meta-api/plugins --data "name=rate-limiting" --data "config.minute=60"
curl -i -X POST $KONG_ADMIN_URL/services/meta-api/plugins --data "name=cors"
curl -i -X POST $KONG_ADMIN_URL/services/meta-api/plugins --data "name=request-size-limiting" --data "config.allowed_payload_size=128"

echo "Kong setup selesai: Semua service menggunakan prefiks unik, plugin best practice aktif, monitoring Prometheus siap!" 