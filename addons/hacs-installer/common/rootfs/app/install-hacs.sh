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

fail() {
    log_error "$1"
    exit 1
}

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
    mkdir -p "$HA_CONFIG_PATH" || fail "Unable to create Home Assistant config directory. Please check the mounted path and write permission."
    [ -d "$HA_CONFIG_PATH" ] || fail "Unable to access Home Assistant config directory after creation. Please check mount path configuration."
fi

# 2. 检查必要命令
command -v curl >/dev/null 2>&1 || fail "curl is not installed in the container."
command -v unzip >/dev/null 2>&1 || fail "unzip is not installed in the container."

# 3. 检查网络连接
log_info "Checking network connection..."
if ! curl -Is https://github.com -o /dev/null --connect-timeout 5; then
    fail "Unable to connect to GitHub. Please check network settings, DNS, or proxy configuration."
fi

# 4. 准备 custom_components 目录
if [ ! -d "$CUSTOM_COMPONENTS_DIR" ]; then
    log_info "Creating custom_components directory..."
    mkdir -p "$CUSTOM_COMPONENTS_DIR" || fail "Unable to create custom_components directory. Please check write permission of Home Assistant config path."
fi

# 5. 清理旧安装
if [ -d "$HACS_DIR" ]; then
    log_warn "Found old HACS version, removing..."
    rm -rf "$HACS_DIR" || fail "Unable to remove old HACS directory. Please check file permissions."
fi

# 6. 下载 HACS
log_info "Downloading HACS..."
if curl -fsSL -o "$DOWNLOAD_PATH" "$DOWNLOAD_URL"; then
    log_info "Download complete."
else
    rm -f "$DOWNLOAD_PATH"
    fail "Download failed. Please check network connectivity to GitHub releases."
fi

# 7. 验证下载文件
[ -s "$DOWNLOAD_PATH" ] || { rm -f "$DOWNLOAD_PATH"; fail "Downloaded file is empty. Please retry later."; }

# 8. 解压安装
log_info "Unzipping and installing..."
mkdir -p "$HACS_DIR" || fail "Unable to create HACS target directory. Please check write permission."
if unzip -q "$DOWNLOAD_PATH" -d "$HACS_DIR"; then
    log_info "Unzip complete."
else
    rm -f "$DOWNLOAD_PATH"
    rm -rf "$HACS_DIR"
    fail "Unzip failed. The downloaded package may be corrupted."
fi

# 9. 安装结果校验
[ -f "$HACS_DIR/__init__.py" ] || {
    rm -f "$DOWNLOAD_PATH"
    fail "Installation completed but HACS core files were not found. Please check the package content or try again."
}

# 10. 清理临时文件
rm -f "$DOWNLOAD_PATH"

log_info "HACS installed successfully!"
log_info "Please restart Home Assistant to make changes take effect."
exit 0
