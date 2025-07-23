#!/bin/bash
# setup-static-files.sh

echo "Setting up static files directories..."

# Create directories if they don't exist
sudo mkdir -p /opt/backend-ryo/staticfiles
sudo mkdir -p /opt/backend-ryo/media

# Set permissions
sudo chown -R www-data:www-data /opt/backend-ryo/
sudo chmod -R 755 /opt/backend-ryo/

echo "Static files directories created!"

# Copy static files from container (run this after container is up)
echo "Collecting static files from Django..."
docker exec backend-ryo python manage.py collectstatic --noinput

# Copy static files to host
echo "Copying static files to host..."
docker cp backend-ryo:/app/staticfiles/. /opt/backend-ryo/staticfiles/
docker cp backend-ryo:/app/media/. /opt/backend-ryo/media/

# Set correct permissions again
sudo chown -R www-data:www-data /opt/backend-ryo/
sudo chmod -R 755 /opt/backend-ryo/

echo "Static files setup complete!"
