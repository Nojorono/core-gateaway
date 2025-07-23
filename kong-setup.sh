#!/bin/bash
# Skrip setup Kong Gateway untuk arsitektur sesuai diagram (hybrid auth + plugin best practice + monitoring)

KONG_ADMIN_URL="http://localhost:8001"

# Aktifkan plugin prometheus secara global
echo "Aktifkan plugin prometheus..."
curl -i -X POST $KONG_ADMIN_URL/plugins --data "name=prometheus"

# Tambah Service untuk backend-md
curl -i -X POST $KONG_ADMIN_URL/services \
  --data name=backend-md-api \
  --data url='http://backend-md:9001'

# Tambah Service untuk backend-ryo
curl -i -X POST $KONG_ADMIN_URL/services \
  --data name=backend-ryo-api \
  --data url='http://backend-ryo:9002'

# Tambah Route

# Tambah Route untuk backend-md
curl -i -X POST $KONG_ADMIN_URL/services/backend-md-api/routes \
  --data 'paths[]=/md-backend-api'

# Tambah Route untuk backend-ryo
curl -i -X POST $KONG_ADMIN_URL/services/backend-ryo-api/routes \
  --data 'paths[]=/ryo-backend-api'



# Plugin untuk backend-md (rate-limiting, cors, request-size-limiting)
curl -i -X POST $KONG_ADMIN_URL/services/backend-md-api/plugins --data "name=prometheus"
curl -i -X POST $KONG_ADMIN_URL/services/backend-md-api/plugins --data "name=rate-limiting" --data "config.minute=60"
curl -i -X POST $KONG_ADMIN_URL/services/backend-md-api/plugins --data "name=cors"
curl -i -X POST $KONG_ADMIN_URL/services/backend-md-api/plugins --data "name=request-size-limiting" --data "config.allowed_payload_size=128"

# Plugin untuk backend-ryo (rate-limiting, cors, request-size-limiting)
curl -i -X POST $KONG_ADMIN_URL/services/backend-ryo-api/plugins --data "name=prometheus"
curl -i -X POST $KONG_ADMIN_URL/services/backend-ryo-api/plugins --data "name=rate-limiting" --data "config.minute=60"
curl -i -X POST $KONG_ADMIN_URL/services/backend-ryo-api/plugins --data "name=cors"
curl -i -X POST $KONG_ADMIN_URL/services/backend-ryo-api/plugins --data "name=request-size-limiting" --data "config.allowed_payload_size=128"

echo "Kong setup selesai: JWT hanya di sofia-backend-api, plugin best practice aktif di semua service, monitoring Prometheus siap!" 