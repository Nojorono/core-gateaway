#!/bin/bash
# Skrip setup Kong Gateway untuk arsitektur sesuai diagram (hybrid auth + plugin best practice + monitoring)

KONG_ADMIN_URL="http://localhost:8001"

# Aktifkan plugin prometheus secara global
echo "Aktifkan plugin prometheus..."
curl -i -X POST $KONG_ADMIN_URL/plugins --data "name=prometheus"

# Tambah Service
curl -i -X POST $KONG_ADMIN_URL/services \
  --data name=wms-backend-api \
  --data url='http://wms-backend:80'

curl -i -X POST $KONG_ADMIN_URL/services \
  --data name=sofia-backend-api \
  --data url='http://sofia-backend:80'

curl -i -X POST $KONG_ADMIN_URL/services \
  --data name=md-backend-api \
  --data url='http://md-backend:80'

# Tambah Route
curl -i -X POST $KONG_ADMIN_URL/services/wms-backend-api/routes \
  --data 'paths[]=/wms-backend-api'

curl -i -X POST $KONG_ADMIN_URL/services/sofia-backend-api/routes \
  --data 'paths[]=/sofia-backend-api'
api.kcsi/services/md-backend-api
curl -i -X POST $KONG_ADMIN_URL/services/md-backend-api/routes \
  --data 'paths[]=/md-backend-api'

# Plugin untuk sofia-backend-api (JWT, rate-limiting, cors, request-size-limiting)
curl -i -X POST $KONG_ADMIN_URL/services/sofia-backend-api/plugins --data "name=jwt"
curl -i -X POST $KONG_ADMIN_URL/services/sofia-backend-api/plugins --data "name=prometheus"
curl -i -X POST $KONG_ADMIN_URL/services/sofia-backend-api/plugins --data "name=rate-limiting" --data "config.minute=60"
curl -i -X POST $KONG_ADMIN_URL/services/sofia-backend-api/plugins --data "name=cors"
curl -i -X POST $KONG_ADMIN_URL/services/sofia-backend-api/plugins --data "name=request-size-limiting" --data "config.allowed_payload_size=128"

# Plugin untuk wms-backend-api (rate-limiting, cors, request-size-limiting)
curl -i -X POST $KONG_ADMIN_URL/services/wms-backend-api/plugins --data "name=prometheus"
curl -i -X POST $KONG_ADMIN_URL/services/wms-backend-api/plugins --data "name=rate-limiting" --data "config.minute=60"
curl -i -X POST $KONG_ADMIN_URL/services/wms-backend-api/plugins --data "name=cors"
curl -i -X POST $KONG_ADMIN_URL/services/wms-backend-api/plugins --data "name=request-size-limiting" --data "config.allowed_payload_size=128"

# Plugin untuk md-backend-api (rate-limiting, cors, request-size-limiting)
curl -i -X POST $KONG_ADMIN_URL/services/md-backend-api/plugins --data "name=prometheus"
curl -i -X POST $KONG_ADMIN_URL/services/md-backend-api/plugins --data "name=rate-limiting" --data "config.minute=60"
curl -i -X POST $KONG_ADMIN_URL/services/md-backend-api/plugins --data "name=cors"
curl -i -X POST $KONG_ADMIN_URL/services/md-backend-api/plugins --data "name=request-size-limiting" --data "config.allowed_payload_size=128"

echo "Kong setup selesai: JWT hanya di sofia-backend-api, plugin best practice aktif di semua service, monitoring Prometheus siap!" 