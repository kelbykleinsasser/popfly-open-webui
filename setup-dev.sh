#!/bin/bash

# Open WebUI Development Setup Script
# This script clones the Open WebUI source code and sets up a development environment

set -e  # Exit on error

echo "=== Open WebUI Development Setup ==="
echo

# Clone the repository
echo "Cloning Open WebUI repository..."
git clone https://github.com/open-webui/open-webui.git src
cd src

# Create Python virtual environment
echo
echo "Creating Python 3.11 virtual environment..."
python3.11 -m venv venv

# Activate virtual environment
source venv/bin/activate

# Upgrade pip
echo
echo "Upgrading pip..."
pip install --upgrade pip

# Install in development mode
echo
echo "Installing Open WebUI in development mode..."
pip install -e .

# Create a development start script
cat > start-dev.sh << 'EOF'
#!/bin/bash
# Start Open WebUI in development mode

source venv/bin/activate

# Export development environment variables
export WEBUI_PORT=8081
export ENV=dev

echo "Starting Open WebUI in development mode on port 8081..."
python -m open_webui serve --host 0.0.0.0 --port 8081
EOF

chmod +x start-dev.sh

echo
echo "=== Setup Complete ==="
echo
echo "Open WebUI has been cloned and set up for development."
echo "The server will run on http://localhost:8081"