#!/bin/bash
# Start Open WebUI in development mode

source venv/bin/activate

# Export development environment variables
export WEBUI_PORT=8081
export ENV=dev

echo "Starting Open WebUI in development mode on port 8081..."
python -m open_webui serve --host 0.0.0.0 --port 8081
