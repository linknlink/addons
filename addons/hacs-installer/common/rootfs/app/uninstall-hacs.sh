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

log_info "Starting HACS uninstallation process..."
log_info "Home Assistant config directory: $HA_CONFIG_PATH"

# 1. 检查配置目录是否存在
if [ ! -d "$HA_CONFIG_PATH" ]; then
    log_error "Home Assistant config directory not found: $HA_CONFIG_PATH"
    exit 1
fi

# 2. 检查 HACS 是否存在
if [ ! -d "$HACS_DIR" ]; then
    log_warn "HACS installation not detected, no need to uninstall."
    exit 0
fi

# 3. 执行卸载
log_info "Removing HACS directory..."
if rm -rf "$HACS_DIR"; then
    log_info "HACS directory removed."
else
    log_error "Removal failed, please check permissions."
    exit 1
fi

log_info "HACS uninstalled successfully!"
log_info "Please restart Home Assistant to clear residual configuration."
exit 0
