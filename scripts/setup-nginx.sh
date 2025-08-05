#!/bin/bash

# Nginx Configuration Deployment Script for Ubuntu Server
# This script deploys both frontend and backend Nginx configurations

set -e

echo "🚀 API Nginx Configuration Deployment Script"
echo "=============================================="

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root or with sudo
if [[ $EUID -eq 0 ]]; then
    print_warning "Running as root"
    SUDO=""
else
    print_status "Running with sudo privileges"
    SUDO="sudo"
fi

# Check if Nginx is installed
if ! command -v nginx &> /dev/null; then
    print_error "Nginx is not installed. Please install Nginx first:"
    echo "sudo apt update && sudo apt install nginx -y"
    exit 1
fi

print_status "Nginx is installed ✓"

# Create sites-available directory if it doesn't exist
$SUDO mkdir -p /etc/nginx/sites-available
$SUDO mkdir -p /etc/nginx/sites-enabled

# Backup existing configurations if they exist
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
if [ -f "/etc/nginx/sites-available/api.kcsi.id.conf" ]; then
    print_warning "Backing up existing api.kcsi.id configuration"
    $SUDO cp /etc/nginx/sites-available/api.kcsi.id.conf /etc/nginx/sites-available/api.kcsi.id.conf.backup.$TIMESTAMP
fi

# Copy configuration files
print_status "Deploying api.kcsi.id.conf configuration..."
if [ ! -f "./nginx/api.kcsi.id.conf" ]; then
    print_error "Configuration file ./nginx/api.kcsi.id.conf not found!"
    exit 1
fi
$SUDO cp ./nginx/api.kcsi.id.conf /etc/nginx/sites-available/api.kcsi.id.conf

# Set proper permissions
$SUDO chmod 644 /etc/nginx/sites-available/api.kcsi.id.conf

print_success "Configuration files deployed successfully"

# Create necessary directories
print_status "Creating necessary directories..."
$SUDO mkdir -p /var/www/html/.well-known/acme-challenge
$SUDO mkdir -p /opt/backend-ryo/{staticfiles,media}
$SUDO chown -R www-data:www-data /var/www/html
$SUDO chown -R www-data:www-data /opt/backend-ryo
$SUDO chmod -R 755 /var/www/html
$SUDO chmod -R 755 /opt/backend-ryo

# Enable sites by creating symlinks
print_status "Enabling api.kcsi.id site..."
$SUDO ln -sf /etc/nginx/sites-available/api.kcsi.id.conf /etc/nginx/sites-enabled/

# Disable default Nginx site if it exists
if [ -f "/etc/nginx/sites-enabled/default" ]; then
    print_warning "Disabling default Nginx site"
    $SUDO rm -f /etc/nginx/sites-enabled/default
fi

# Test Nginx configuration
print_status "Testing Nginx configuration..."
if $SUDO nginx -t; then
    print_success "Nginx configuration test passed ✓"
else
    print_error "Nginx configuration test failed ✗"
    print_error "Please check the configuration files for syntax errors"
    exit 1
fi

# Reload Nginx
print_status "Reloading Nginx..."
if $SUDO systemctl reload nginx; then
    print_success "Nginx reloaded successfully ✓"
else
    print_error "Failed to reload Nginx ✗"
    print_status "Trying to restart Nginx..."
    if $SUDO systemctl restart nginx; then
        print_success "Nginx restarted successfully ✓"
    else
        print_error "Failed to restart Nginx ✗"
        exit 1
    fi
fi

# Check Nginx status
print_status "Checking Nginx status..."
if $SUDO systemctl is-active --quiet nginx; then
    print_success "Nginx is running ✓"
else
    print_error "Nginx is not running ✗"
    print_status "Starting Nginx..."
    $SUDO systemctl start nginx
fi

echo ""
echo "🎉 Deployment completed successfully!"
echo ""
echo "📝 Next steps:"
echo "1. Start your Docker containers:"
echo "   cd /home/ubuntu/core-gateaway && docker-compose up -d"
echo ""
echo "2. Setup Kong services:"
echo "   chmod +x scripts/kong-setup-new.sh && ./scripts/kong-setup-new.sh"
echo ""
echo "3. Setup static files:"
echo "   chmod +x scripts/setup-static-files.sh && ./scripts/setup-static-files.sh"
echo ""
echo "4. Get SSL certificate:"
echo "   chmod +x scripts/ssl-setup.sh && ./scripts/ssl-setup.sh"
echo ""
echo "5. Test the deployment:"
echo "   curl -I http://api.kcsi.id/health"
echo "   curl -I https://api.kcsi.id/health (after SSL setup)"
echo ""
echo "📁 Configuration files location:"
echo "   - API Gateway: /etc/nginx/sites-available/api.kcsi.id"
echo ""
echo "📊 Log files location:"
echo "   - access: /var/log/nginx/api.kcsi.id-access.log"
echo "   - error: /var/log/nginx/api.kcsi.id-error.log"
echo ""
print_success "API deployment is ready! 🚀"
