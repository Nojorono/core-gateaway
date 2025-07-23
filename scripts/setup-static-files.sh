#!/bin/bash
# setup-static-files.sh

set -e

echo "Setting up static files directories..."

# Create directories if they don't exist
sudo mkdir -p /opt/backend-ryo/staticfiles
sudo mkdir -p /opt/backend-ryo/media

# Set permissions
sudo chown -R www-data:www-data /opt/backend-ryo/
sudo chmod -R 755 /opt/backend-ryo/

echo "Static files directories created!"

# Check if backend-ryo container is running
if ! docker ps | grep -q backend-ryo; then
    echo "❌ backend-ryo container is not running!"
    echo "Please start containers first: docker-compose up -d"
    exit 1
fi

# Copy static files from container (run this after container is up)
echo "Collecting static files from Django..."
if docker exec backend-ryo python manage.py collectstatic --noinput; then
    echo "✅ Static files collected successfully"
else
    echo "⚠️  Failed to collect static files, continuing anyway..."
fi

# Copy static files to host
echo "Copying static files to host..."
docker cp backend-ryo:/app/staticfiles/. /opt/backend-ryo/staticfiles/ 2>/dev/null || echo "⚠️  No staticfiles to copy"
docker cp backend-ryo:/app/media/. /opt/backend-ryo/media/ 2>/dev/null || echo "⚠️  No media files to copy"

# Set correct permissions again
sudo chown -R www-data:www-data /opt/backend-ryo/
sudo chmod -R 755 /opt/backend-ryo/

echo "✅ Static files setup complete!"
