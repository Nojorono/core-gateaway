#!/bin/bash
# filepath: d:\belajar\api_gateway\core-gateaway\scripts\kong-force-cleanup.sh

echo "🧹 Force cleanup Kong configuration..."

KONG_ADMIN_URL="http://localhost:8001"

# Delete all routes
echo "Deleting all routes..."
curl -s $KONG_ADMIN_URL/routes | jq -r '.data[].id' 2>/dev/null | while read route_id; do
    curl -s -X DELETE $KONG_ADMIN_URL/routes/$route_id
    echo "Deleted route: $route_id"
done

# Delete all plugins
echo "Deleting all plugins..."
curl -s $KONG_ADMIN_URL/plugins | jq -r '.data[].id' 2>/dev/null | while read plugin_id; do
    curl -s -X DELETE $KONG_ADMIN_URL/plugins/$plugin_id
    echo "Deleted plugin: $plugin_id"
done

# Delete all services
echo "Deleting all services..."
curl -s $KONG_ADMIN_URL/services | jq -r '.data[].id' 2>/dev/null | while read service_id; do
    curl -s -X DELETE $KONG_ADMIN_URL/services/$service_id
    echo "Deleted service: $service_id"
done

echo "✅ Force cleanup completed!"