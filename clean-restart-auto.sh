#!/bin/bash
# Shortcut script untuk clean restart docker-compose (non-interactive)
# Usage: ./clean-restart-auto.sh [service-name]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$SCRIPT_DIR/scripts/docker-compose-clean-restart-auto.sh" "$@"

