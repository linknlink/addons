#!/bin/bash
set -e

# 日志颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO] $1${NC}"; }
log_warn() { echo -e "${YELLOW}[WARN] $1${NC}"; }
log_error() { echo -e "${RED}[ERROR] $1${NC}"; }

HA_CONFIG_PATH="${HA_CONFIG_PATH:-/homeassistant}"
CUSTOM_COMPONENTS_DIR="$HA_CONFIG_PATH/custom_components"
HACS_DIR="$CUSTOM_COMPONENTS_DIR/hacs"
DOWNLOAD_URL="https://github.com/hacs/integration/releases/latest/download/hacs.zip"
DOWNLOAD_PATH="/tmp/hacs.zip"

log_info "Starting HACS installation process..."
log_info "Home Assistant config directory: $HA_CONFIG_PATH"

# 1. 检查配置目录是否存在
if [ ! -d "$HA_CONFIG_PATH" ]; then
    log_warn "Home Assistant config directory not found: $HA_CONFIG_PATH"
    log_warn "Attempting to create directory (this should generally not happen unless in a test environment)..."
    mkdir -p "$HA_CONFIG_PATH"
    if [ ! -d "$HA_CONFIG_PATH" ]; then
        log_error "Unable to create or access config directory, please check mount path configuration."
        exit 1
    fi
fi

# 2. 检查网络连接
log_info "Checking network connection..."
if ! curl -Is https://github.com -o /dev/null --connect-timeout 5; then
    log_error "Unable to connect to GitHub, please check network settings or proxy configuration."
    exit 1
fi

# 3. 准备 custom_components 目录
if [ ! -d "$CUSTOM_COMPONENTS_DIR" ]; then
    log_info "Creating custom_components directory..."
    mkdir -p "$CUSTOM_COMPONENTS_DIR"
fi

# 4. 清理旧安装
if [ -d "$HACS_DIR" ]; then
    log_warn "Found old HACS version, removing..."
    rm -rf "$HACS_DIR"
fi

# 5. 下载 HACS
log_info "Downloading HACS..."
if curl -L -o "$DOWNLOAD_PATH" "$DOWNLOAD_URL"; then
    log_info "Download complete."
else
    log_error "Download failed, please check network connection."
    rm -f "$DOWNLOAD_PATH"
    exit 1
fi

# 6. 验证下载文件
if [ ! -s "$DOWNLOAD_PATH" ]; then
    log_error "Downloaded file is empty."
    rm -f "$DOWNLOAD_PATH"
    exit 1
fi

# 7. 解压安装
log_info "Unzipping and installing..."
mkdir -p "$HACS_DIR"
if unzip -q "$DOWNLOAD_PATH" -d "$HACS_DIR"; then
    log_info "Unzip complete."
else
    log_error "Unzip failed."
    rm -f "$DOWNLOAD_PATH"
    rm -rf "$HACS_DIR"
    exit 1
fi

# 8. 清理临时文件
rm -f "$DOWNLOAD_PATH"

log_info "HACS installed successfully!"
log_info "Please restart Home Assistant to make changes take effect."
exit 0
