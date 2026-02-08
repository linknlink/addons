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

log_info "开始 HACS 安装流程..."
log_info "Home Assistant 配置目录: $HA_CONFIG_PATH"

# 1. 检查配置目录是否存在
if [ ! -d "$HA_CONFIG_PATH" ]; then
    log_warn "未找到 Home Assistant 配置目录: $HA_CONFIG_PATH"
    log_warn "尝试创建目录 (这通常不应该发生，除非是测试环境)..."
    mkdir -p "$HA_CONFIG_PATH"
    if [ ! -d "$HA_CONFIG_PATH" ]; then
        log_error "无法创建或访问配置目录，请检查挂载路径配置。"
        exit 1
    fi
fi

# 2. 检查网络连接
log_info "检查网络连接..."
if ! curl -Is https://github.com -o /dev/null --connect-timeout 5; then
    log_error "无法连接到 GitHub，请检查网络设置或代理配置。"
    exit 1
fi

# 3. 准备 custom_components 目录
if [ ! -d "$CUSTOM_COMPONENTS_DIR" ]; then
    log_info "创建 custom_components 目录..."
    mkdir -p "$CUSTOM_COMPONENTS_DIR"
fi

# 4. 清理旧安装
if [ -d "$HACS_DIR" ]; then
    log_warn "发现旧版 HACS，正在移除..."
    rm -rf "$HACS_DIR"
fi

# 5. 下载 HACS
log_info "正在下载 HACS..."
if curl -L -o "$DOWNLOAD_PATH" "$DOWNLOAD_URL"; then
    log_info "下载完成。"
else
    log_error "下载失败，请检查网络连接。"
    rm -f "$DOWNLOAD_PATH"
    exit 1
fi

# 6. 验证下载文件
if [ ! -s "$DOWNLOAD_PATH" ]; then
    log_error "下载文件为空。"
    rm -f "$DOWNLOAD_PATH"
    exit 1
fi

# 7. 解压安装
log_info "正在解压安装..."
mkdir -p "$HACS_DIR"
if unzip -q "$DOWNLOAD_PATH" -d "$HACS_DIR"; then
    log_info "解压完成。"
else
    log_error "解压失败。"
    rm -f "$DOWNLOAD_PATH"
    rm -rf "$HACS_DIR"
    exit 1
fi

# 8. 清理临时文件
rm -f "$DOWNLOAD_PATH"

log_info "HACS 安装成功！"
log_info "请务必重启 Home Assistant 以使更改生效。"
exit 0
