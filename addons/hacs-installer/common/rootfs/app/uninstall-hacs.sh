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

log_info "开始 HACS 卸载流程..."
log_info "Home Assistant 配置目录: $HA_CONFIG_PATH"

# 1. 检查配置目录是否存在
if [ ! -d "$HA_CONFIG_PATH" ]; then
    log_error "未找到 Home Assistant 配置目录: $HA_CONFIG_PATH"
    exit 1
fi

# 2. 检查 HACS 是否存在
if [ ! -d "$HACS_DIR" ]; then
    log_warn "未检测到 HACS 安装，无需卸载。"
    exit 0
fi

# 3. 执行卸载
log_info "正在移除 HACS 目录..."
if rm -rf "$HACS_DIR"; then
    log_info "HACS 目录已移除。"
else
    log_error "移除失败，请检查权限。"
    exit 1
fi

log_info "HACS 卸载成功！"
log_info "请重启 Home Assistant 清除残留配置。"
exit 0
