#!/bin/bash

# 工具函数库

# 日志函数
log() {
    local level=$1
    shift
    local message="$@"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case "$level" in
        DEBUG)
            if [ "${LOG_LEVEL:-info}" = "debug" ]; then
                echo "[$timestamp] [DEBUG] $message" >&2
            fi
            ;;
        INFO)
            echo "[$timestamp] [INFO] $message"
            ;;
        WARNING)
            echo "[$timestamp] [WARNING] $message" >&2
            ;;
        ERROR)
            echo "[$timestamp] [ERROR] $message" >&2
            ;;
    esac
}

# 加载配置
load_config() {
    # 设置默认值
    export WIFI_SCAN_INTERVAL=${WIFI_SCAN_INTERVAL:-30}
    export AUTO_RECONNECT=${AUTO_RECONNECT:-true}
    export DEFAULT_IP_METHOD=${DEFAULT_IP_METHOD:-dhcp}
    export LOG_LEVEL=${LOG_LEVEL:-info}
    
    log INFO "配置加载完成"
    log DEBUG "WIFI_SCAN_INTERVAL: $WIFI_SCAN_INTERVAL"
    log DEBUG "AUTO_RECONNECT: $AUTO_RECONNECT"
    log DEBUG "DEFAULT_IP_METHOD: $DEFAULT_IP_METHOD"
    log DEBUG "LOG_LEVEL: $LOG_LEVEL"
}

# 等待 NetworkManager 就绪（通过 nmcli 检查宿主机的 NetworkManager）
wait_for_network_manager() {
    local max_attempts=30
    local attempt=0
    
    log INFO "等待连接到宿主机的 NetworkManager..."
    
    while [ $attempt -lt $max_attempts ]; do
        # 使用 nmcli 检查是否可以连接到宿主机的 NetworkManager
        if nmcli general status >/dev/null 2>&1; then
            log INFO "已成功连接到宿主机的 NetworkManager"
            return 0
        fi
        
        attempt=$((attempt + 1))
        sleep 1
    done
    
    log WARNING "无法连接到宿主机的 NetworkManager，继续尝试..."
    return 0
}

# 检查 NetworkManager 是否可用
check_network_manager() {
    if ! command -v nmcli >/dev/null 2>&1; then
        log ERROR "nmcli 命令不可用"
        return 1
    fi
    
    if ! nmcli general status >/dev/null 2>&1; then
        log ERROR "NetworkManager 服务不可用"
        return 1
    fi
    
    return 0
}

# 检查 WiFi 设备
check_wifi_device() {
    local device=$(nmcli device status | grep -i wifi | head -n1 | awk '{print $1}')
    
    if [ -z "$device" ]; then
        log WARNING "未找到 WiFi 设备"
        return 1
    fi
    
    log DEBUG "找到 WiFi 设备: $device"
    return 0
}
