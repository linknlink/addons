#!/bin/bash
set -e

HA_CONFIG_PATH="${HA_CONFIG_PATH:-/homeassistant}"
CUSTOM_COMPONENTS_DIR="$HA_CONFIG_PATH/custom_components"
HACS_DIR="$CUSTOM_COMPONENTS_DIR/hacs"

echo "Checking Home Assistant configuration directory: $HA_CONFIG_PATH"

if [ ! -d "$HA_CONFIG_PATH" ]; then
    echo "Error: Home Assistant configuration directory not found at $HA_CONFIG_PATH"
    exit 1
fi

echo "Creating custom_components directory if it doesn't exist..."
mkdir -p "$CUSTOM_COMPONENTS_DIR"

if [ -d "$HACS_DIR" ]; then
    echo "HACS directory already exists. Removing old version..."
    rm -rf "$HACS_DIR"
fi

echo "Downloading HACS..."
HACS_DOWNLOAD_URL="https://github.com/hacs/integration/releases/latest/download/hacs.zip"
curl -L -o /tmp/hacs.zip "$HACS_DOWNLOAD_URL"

echo "Extracting HACS..."
unzip /tmp/hacs.zip -d "$HACS_DIR"
rm /tmp/hacs.zip

echo "HACS installed successfully to $HACS_DIR"
