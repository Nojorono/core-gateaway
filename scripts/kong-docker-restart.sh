#!/bin/bash
# filepath: d:\belajar\api_gateway\core-gateaway\scripts\clean-restart-kong.sh

echo "🔄 Clean Restart Kong Gateway..."

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🛑 Step 1: Stopping Kong services...${NC}"
docker-compose stop kong
docker-compose stop kong-database

echo -e "${RED}🗑️ Step 2: Removing Kong containers...${NC}"
docker-compose rm -f kong
docker-compose rm -f kong-database

echo -e "${RED}🗑️ Step 3: Removing Kong volumes...${NC}"
docker volume rm core-gateaway_kong-vol 2>/dev/null || echo "Kong volume not found, skipping..."

echo -e "${YELLOW}🧹 Step 4: Cleaning up Kong images...${NC}"
docker image prune -f

echo -e "${BLUE}📥 Step 5: Pulling latest Kong images...${NC}"
docker-compose pull kong kong-database

echo -e "${YELLOW}🔨 Step 6: Rebuilding Kong containers...${NC}"
docker-compose build --no-cache kong kong-database

echo -e "${GREEN}🚀 Step 7: Starting Kong database...${NC}"
docker-compose up -d kong-database

echo -e "${YELLOW}⏳ Step 8: Waiting for database to be ready...${NC}"
sleep 15

# Check if database is ready
echo -e "${BLUE}🔍 Checking database connection...${NC}"
until docker exec kong-database pg_isready -U kong >/dev/null 2>&1; do
    echo "Waiting for database..."
    sleep 3
done
echo -e "${GREEN}✅ Database is ready!${NC}"

echo -e "${BLUE}🔧 Step 9: Running Kong migrations...${NC}"
docker-compose run --rm kong kong migrations bootstrap

echo -e "${GREEN}🚀 Step 10: Starting Kong gateway...${NC}"
docker-compose up -d kong

echo -e "${YELLOW}⏳ Step 11: Waiting for Kong to be ready...${NC}"
sleep 10

# Wait for Kong Admin API to be available
KONG_ADMIN_URL="http://localhost:8001"
echo -e "${BLUE}🔍 Checking Kong Admin API...${NC}"
until $(curl --output /dev/null --silent --head --fail $KONG_ADMIN_URL); do
    printf '.'
    sleep 3
done
echo ""
echo -e "${GREEN}✅ Kong Admin API is ready!${NC}"

echo -e "${BLUE}📊 Step 12: Checking Kong status...${NC}"
docker-compose ps kong kong-database

echo -e "${BLUE}🔧 Step 13: Setting up Kong services and routes...${NC}"
if [ -f "./scripts/kong-setup-new.sh" ]; then
    chmod +x ./scripts/kong-setup-new.sh
    ./scripts/kong-setup-new.sh
else
    echo -e "${YELLOW}⚠️ Kong setup script not found. Creating basic setup...${NC}"
    
    # Basic Kong setup
    echo "Creating backend-ryo service..."
    curl -s -X POST $KONG_ADMIN_URL/services/ \
        --data "name=backend-ryo" \
        --data "url=http://backend-ryo:9002"
    
    echo ""
    echo "Creating backend-ryo route..."
    curl -s -X POST $KONG_ADMIN_URL/services/backend-ryo/routes \
        --data "paths[]=/ryo-api" \
        --data "strip_path=false"
    
    echo ""
    echo "Creating backend-md service..."
    curl -s -X POST $KONG_ADMIN_URL/services/ \
        --data "name=backend-md" \
        --data "url=http://backend-md:9001"
    
    echo ""
    echo "Creating backend-md route..."
    curl -s -X POST $KONG_ADMIN_URL/services/backend-md/routes \
        --data "paths[]=/md-api" \
        --data "strip_path=true"
fi

echo -e "${GREEN}🔍 Step 14: Verifying Kong configuration...${NC}"
echo "Services:"
curl -s $KONG_ADMIN_URL/services | jq '.data[] | {name: .name, url: .url}' 2>/dev/null || curl -s $KONG_ADMIN_URL/services

echo ""
echo "Routes:"
curl -s $KONG_ADMIN_URL/routes | jq '.data[] | {name: .name, paths: .paths}' 2>/dev/null || curl -s $KONG_ADMIN_URL/routes

echo ""
echo -e "${GREEN}✅ Kong clean restart completed successfully!${NC}"
echo ""
echo -e "${BLUE}📋 Kong endpoints:${NC}"
echo "• Kong Gateway: http://localhost:8000"
echo "• Kong Admin API: http://localhost:8001"
echo "• Backend-RYO: http://localhost:8000/ryo-api/"
echo "• Backend-MD: http://localhost:8000/md-api/"
echo ""
echo -e "${YELLOW}🧪 Test with:${NC}"
echo "curl -I http://localhost:8000/ryo-api/health/"
echo "curl -I http://localhost:8000/md-api/health/"