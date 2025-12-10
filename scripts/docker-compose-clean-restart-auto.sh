#!/bin/bash
# Script untuk clean restart semua services di docker-compose (Non-interactive)
# Usage: ./scripts/docker-compose-clean-restart-auto.sh [service-name]

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored messages
print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Get service name from argument (optional)
SERVICE_NAME=${1:-""}
SKIP_VOLUMES=${2:-"true"}  # Default: skip volume prune for safety

echo "=========================================="
echo "🚀 Docker Compose Clean Restart (Auto)"
echo "=========================================="
echo ""

if [ -n "$SERVICE_NAME" ]; then
    print_info "Target service: $SERVICE_NAME"
else
    print_info "Target: All services"
fi
echo ""

# Step 1: Stop services
print_info "Step 1/7: Stopping services..."
if [ -n "$SERVICE_NAME" ]; then
    docker-compose stop "$SERVICE_NAME" 2>/dev/null || true
else
    docker-compose stop 2>/dev/null || true
fi
print_success "Services stopped"
echo ""

# Step 2: Remove containers
print_info "Step 2/7: Removing containers..."
if [ -n "$SERVICE_NAME" ]; then
    docker-compose rm -f "$SERVICE_NAME" 2>/dev/null || true
else
    docker-compose rm -f 2>/dev/null || true
fi
print_success "Containers removed"
echo ""

# Step 3: Remove images for built services
print_info "Step 3/7: Cleaning up Docker images..."
if [ -n "$SERVICE_NAME" ]; then
    IMAGE_NAME="core-gateaway_${SERVICE_NAME}"
    docker images | grep "$IMAGE_NAME" | awk '{print $3}' | xargs -r docker rmi -f 2>/dev/null || true
else
    docker images | grep "core-gateaway_" | awk '{print $3}' | xargs -r docker rmi -f 2>/dev/null || true
fi
print_success "Images cleaned up"
echo ""

# Step 4: Prune unused Docker resources
print_info "Step 4/7: Pruning unused Docker resources..."
docker system prune -f
print_success "Unused resources pruned"
echo ""

# Step 5: Prune unused volumes (optional)
if [ "$SKIP_VOLUMES" != "true" ]; then
    print_info "Step 5/7: Pruning unused Docker volumes..."
    docker volume prune -f
    print_success "Unused volumes pruned"
else
    print_info "Step 5/7: Skipping volume prune (preserving volumes)"
fi
echo ""

# Step 6: Pull latest images
print_info "Step 6/7: Pulling latest images..."
if [ -n "$SERVICE_NAME" ]; then
    docker-compose pull "$SERVICE_NAME" 2>/dev/null || true
else
    docker-compose pull 2>/dev/null || true
fi
print_success "Images pulled"
echo ""

# Step 7: Rebuild and start services
print_info "Step 7/7: Rebuilding and starting services..."
if [ -n "$SERVICE_NAME" ]; then
    docker-compose up -d --build --force-recreate "$SERVICE_NAME"
else
    docker-compose up -d --build --force-recreate
fi
print_success "Services rebuilt and started"
echo ""

# Wait for services
print_info "Waiting for services to initialize..."
sleep 5

# Show status
echo "=========================================="
print_info "Container Status:"
echo "=========================================="
if [ -n "$SERVICE_NAME" ]; then
    docker-compose ps "$SERVICE_NAME"
else
    docker-compose ps
fi
echo ""

print_success "Clean restart completed!"
echo ""

