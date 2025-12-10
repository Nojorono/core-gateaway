#!/bin/bash
# Shortcut script untuk clean restart docker-compose
# Usage: ./clean-restart.sh [service-name]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$SCRIPT_DIR/scripts/docker-compose-clean-restart.sh" "$@"

