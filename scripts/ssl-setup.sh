#!/bin/bash
# ssl-setup.sh

set -e

echo "🔒 Setting up SSL certificate..."

# Check if nginx is running
if ! systemctl is-active --quiet nginx; then
    echo "❌ Nginx is not running. Please start nginx first."
    exit 1
fi

# Check if domain resolves to this server
echo "🔍 Checking domain resolution..."
DOMAIN_IP=$(dig +short api.kcsi.id | head -n1)
SERVER_IP=$(curl -s -4 ifconfig.me)
echo "Domain IP: $DOMAIN_IP"
echo "Server IP: $SERVER_IP"

# Install certbot if not installed
if ! command -v certbot &> /dev/null; then
    echo "Installing Certbot..."
    sudo apt update
    sudo apt install -y certbot python3-certbot-nginx
fi

# Test ACME challenge first
echo "🧪 Testing ACME challenge..."
echo "test" | sudo tee /var/www/html/.well-known/acme-challenge/test > /dev/null
if curl -f http://api.kcsi.id/.well-known/acme-challenge/test > /dev/null 2>&1; then
    echo "✅ ACME challenge working"
    sudo rm -f /var/www/html/.well-known/acme-challenge/test
else
    echo "❌ ACME challenge failed. Check nginx configuration and domain pointing."
    exit 1
fi

# Get SSL certificate
echo "Getting SSL certificate for api.kcsi.id..."
if sudo certbot --nginx -d api.kcsi.id \
    --email banyu.aji@kcsi-id.com \
    --agree-tos \
    --non-interactive; then
    
    echo "✅ SSL certificate obtained successfully!"
else
    echo "❌ Failed to get SSL certificate. Trying webroot method..."
    sudo certbot certonly --webroot \
        -w /var/www/html \
        -d api.kcsi.id \
        --email banyu.aji@kcsi-d.com \
        --agree-tos \
        --non-interactive
fi

# Test auto-renewal
echo "Testing certificate auto-renewal..."
if sudo certbot renew --dry-run; then
    echo "✅ Auto-renewal test passed!"
else
    echo "⚠️  Auto-renewal test failed, but certificate may still work"
fi

# Test HTTPS
echo "🔍 Testing HTTPS..."
if curl -I https://api.kcsi.id/health > /dev/null 2>&1; then
    echo "✅ HTTPS working!"
    curl -I https://api.kcsi.id/health
else
    echo "⚠️  HTTPS test failed, but certificate may be installed"
fi

echo "✅ SSL setup completed!"