#!/bin/bash
# Script untuk clean restart semua services di docker-compose
# Usage: ./scripts/docker-compose-clean-restart.sh [service-name]

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

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if docker-compose is available
if ! command -v docker-compose &> /dev/null; then
    print_error "docker-compose not found. Please install docker-compose."
    exit 1
fi

# Get service name from argument (optional)
SERVICE_NAME=${1:-""}

echo "=========================================="
echo "🚀 Docker Compose Clean Restart"
echo "=========================================="
echo ""

if [ -n "$SERVICE_NAME" ]; then
    print_info "Target service: $SERVICE_NAME"
else
    print_info "Target: All services"
fi
echo ""

# Step 1: Stop services
print_info "Step 1/8: Stopping services..."
if [ -n "$SERVICE_NAME" ]; then
    docker-compose stop "$SERVICE_NAME" || print_warning "Service $SERVICE_NAME not running"
else
    docker-compose stop || print_warning "Some services may not be running"
fi
print_success "Services stopped"
echo ""

# Step 2: Remove containers
print_info "Step 2/8: Removing containers..."
if [ -n "$SERVICE_NAME" ]; then
    docker-compose rm -f "$SERVICE_NAME" || print_warning "Container $SERVICE_NAME not found"
else
    docker-compose rm -f || print_warning "Some containers may not exist"
fi
print_success "Containers removed"
echo ""

# Step 3: Remove images for built services
print_info "Step 3/8: Cleaning up Docker images..."
if [ -n "$SERVICE_NAME" ]; then
    IMAGE_NAME="core-gateaway_${SERVICE_NAME}"
    docker images | grep "$IMAGE_NAME" | awk '{print $3}' | xargs -r docker rmi -f || print_warning "No images found for $SERVICE_NAME"
else
    # Remove images for all built services
    docker images | grep "core-gateaway_" | awk '{print $3}' | xargs -r docker rmi -f || print_warning "No custom images found"
fi
print_success "Images cleaned up"
echo ""

# Step 4: Prune unused Docker resources
print_info "Step 4/8: Pruning unused Docker resources..."
docker system prune -f
print_success "Unused resources pruned"
echo ""

# Step 5: Prune unused volumes (optional - be careful!)
print_info "Step 5/8: Pruning unused Docker volumes..."
read -p "⚠️  Do you want to remove unused volumes? (y/N): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    docker volume prune -f
    print_success "Unused volumes pruned"
else
    print_info "Skipping volume prune (keeping volumes)"
fi
echo ""

# Step 6: Pull latest images (if using external images)
print_info "Step 6/8: Pulling latest images..."
if [ -n "$SERVICE_NAME" ]; then
    docker-compose pull "$SERVICE_NAME" || print_warning "Service $SERVICE_NAME may not use external image"
else
    docker-compose pull || print_warning "Some services may not use external images"
fi
print_success "Images pulled"
echo ""

# Step 7: Rebuild and start services
print_info "Step 7/8: Rebuilding and starting services..."
if [ -n "$SERVICE_NAME" ]; then
    docker-compose up -d --build --force-recreate "$SERVICE_NAME"
else
    docker-compose up -d --build --force-recreate
fi
print_success "Services rebuilt and started"
echo ""

# Step 8: Wait for services to be ready
print_info "Step 8/8: Waiting for services to be ready..."
sleep 5
print_success "Wait completed"
echo ""

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

# Show recent logs
echo "=========================================="
print_info "Recent Logs (last 30 lines):"
echo "=========================================="
if [ -n "$SERVICE_NAME" ]; then
    docker-compose logs --tail=30 "$SERVICE_NAME"
else
    docker-compose logs --tail=30
fi
echo ""

# Health check summary
echo "=========================================="
print_info "Health Check Summary:"
echo "=========================================="
docker ps --format "table {{.Names}}\t{{.Status}}" | grep -E "NAMES|backend-|service-|kong"
echo ""

print_success "Clean restart completed!"
echo ""
print_info "Useful commands:"
echo "  📋 View logs: docker-compose logs -f [service-name]"
echo "  📊 Check status: docker-compose ps"
echo "  🔍 Inspect service: docker-compose logs [service-name]"
echo "  🛑 Stop all: docker-compose stop"
echo ""

