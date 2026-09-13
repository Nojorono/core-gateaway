#!/bin/bash
# Skrip setup Kong Gateway untuk arsitektur sesuai diagram (hybrid auth + plugin best practice + monitoring)

KONG_ADMIN_URL="http://localhost:8001"

# Function to delete duplicate routes for a given service and path
# Requires jq to be installed
delete_duplicate_routes() {
  local service_name=$1
  local route_path=$2
  route_ids=$(curl -s $KONG_ADMIN_URL/services/$service_name/routes | jq -r --arg path "$route_path" '.data[] | select(.paths[] == $path) | .id')
  first=1
  for id in $route_ids; do
    if [ $first -eq 1 ]; then
      first=0
      continue
    fi
    echo "Deleting duplicate route $id for $service_name ($route_path)"
    curl -s -X DELETE $KONG_ADMIN_URL/routes/$id
  done
}

# Enable prometheus plugin globally (check if exists)
if ! curl -s $KONG_ADMIN_URL/plugins | grep -q '"name":"prometheus"'; then
  curl -i -X POST $KONG_ADMIN_URL/plugins --data "name=prometheus"
fi

# Add backend-md service if not exists
if ! curl -s $KONG_ADMIN_URL/services | grep -q '"name":"backend-md-api"'; then
  curl -i -X POST $KONG_ADMIN_URL/services \
    --data name=backend-md-api \
    --data url='http://backend-md:9001'
fi

# Add backend-ryo service if not exists
if ! curl -s $KONG_ADMIN_URL/services | grep -q '"name":"backend-ryo-api"'; then
  curl -i -X POST $KONG_ADMIN_URL/services \
    --data name=backend-ryo-api \
    --data url='http://backend-ryo:9002'
fi

# Clean up duplicate routes before creating new ones
delete_duplicate_routes "backend-md-api" "/md-backend-api"
delete_duplicate_routes "backend-ryo-api" "/ryo-backend-api"

# Add prefixed route for backend-md if not exists
if ! curl -s $KONG_ADMIN_URL/services/backend-md-api/routes | grep -q '/md-backend-api'; then
  curl -i -X POST $KONG_ADMIN_URL/services/backend-md-api/routes \
    --data 'paths[]=/md-backend-api' \
    --data 'strip_path=true'
fi

# Add prefixed route for backend-ryo if not exists
if ! curl -s $KONG_ADMIN_URL/services/backend-ryo-api/routes | grep -q '/ryo-backend-api'; then
  curl -i -X POST $KONG_ADMIN_URL/services/backend-ryo-api/routes \
    --data 'paths[]=/ryo-backend-api' \
    --data 'strip_path=true'
fi

# Plugins for backend-md (check each before adding)
for plugin in prometheus rate-limiting cors request-size-limiting; do
  if ! curl -s $KONG_ADMIN_URL/services/backend-md-api/plugins | grep -q "\"name\":\"$plugin\""; then
    if [ "$plugin" = "rate-limiting" ]; then
      curl -i -X POST $KONG_ADMIN_URL/services/backend-md-api/plugins --data "name=rate-limiting" --data "config.minute=60"
    elif [ "$plugin" = "request-size-limiting" ]; then
      curl -i -X POST $KONG_ADMIN_URL/services/backend-md-api/plugins --data "name=request-size-limiting" --data "config.allowed_payload_size=128"
    else
      curl -i -X POST $KONG_ADMIN_URL/services/backend-md-api/plugins --data "name=$plugin"
    fi
  fi
done

# Plugins for backend-ryo (check each before adding)
for plugin in prometheus rate-limiting cors request-size-limiting; do
  if ! curl -s $KONG_ADMIN_URL/services/backend-ryo-api/plugins | grep -q "\"name\":\"$plugin\""; then
    if [ "$plugin" = "rate-limiting" ]; then
      curl -i -X POST $KONG_ADMIN_URL/services/backend-ryo-api/plugins --data "name=rate-limiting" --data "config.minute=60"
    elif [ "$plugin" = "request-size-limiting" ]; then
      curl -i -X POST $KONG_ADMIN_URL/services/backend-ryo-api/plugins --data "name=request-size-limiting" --data "config.allowed_payload_size=128"
    else
      curl -i -X POST $KONG_ADMIN_URL/services/backend-ryo-api/plugins --data "name=$plugin"
    fi
  fi
done

echo "Kong setup selesai: Semua service menggunakan prefiks unik, plugin best practice aktif, monitoring Prometheus siap!" 
