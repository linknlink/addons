#!/bin/bash
set -e

# 加载工具函数
source /app/utils.sh

log INFO "启动 Network Manager 容器..."

# 加载配置
load_config

# 验证配置
if ! /app/config-validator.sh; then
    log ERROR "配置验证失败，容器退出"
    exit 1
fi

# 检查 NetworkManager（通过 nmcli 连接到宿主机的 NetworkManager）
# 注意：NetworkManager 服务在宿主机上运行，容器只需要 nmcli 客户端
if ! check_network_manager; then
    log ERROR "无法连接到宿主机的 NetworkManager，请确保："
    log ERROR "1. 宿主机上 NetworkManager 服务正在运行"
    log ERROR "2. D-Bus socket 已正确挂载"
    log ERROR "3. 容器有足够的权限访问 D-Bus"
    exit 1
fi

# 等待 NetworkManager 就绪（通过 nmcli 检查）
wait_for_network_manager

# 检查 WiFi 设备
if ! check_wifi_device; then
    log WARNING "未找到 WiFi 设备，某些功能可能不可用"
fi

# 执行初始化配置
if [ -n "$INITIAL_WIFI_SSID" ]; then
    log INFO "执行初始化 WiFi 连接..."
    
    /app/network-manager.sh connect \
        --ssid "$INITIAL_WIFI_SSID" \
        --password "${INITIAL_WIFI_PASSWORD:-}" \
        --ip-method "${DEFAULT_IP_METHOD:-dhcp}" \
        --ip-address "${INITIAL_WIFI_IP_ADDRESS:-}" \
        --gateway "${INITIAL_WIFI_GATEWAY:-}" \
        --dns "${INITIAL_WIFI_DNS:-}" || {
        log WARNING "初始化 WiFi 连接失败，继续运行..."
    }
fi

# 启动监控服务（如果启用）
if [ "$AUTO_RECONNECT" = "true" ]; then
    log INFO "启动自动重连监控服务..."
    /app/network-manager.sh monitor &
    MONITOR_PID=$!
    log DEBUG "监控服务 PID: $MONITOR_PID"
fi

log INFO "Network Manager 启动完成"

# 启动 Web 管理界面
log INFO "启动 Web 管理界面 (Port 8201)..."
python3 /app/web/app.py &
WEB_PID=$!
log DEBUG "Web 服务 PID: $WEB_PID"

# 如果提供了命令，执行它；否则保持容器运行
if [ $# -eq 0 ]; then
    # 没有提供命令，保持容器运行
    log INFO "容器保持运行中..."
    # 等待所有后台进程
    wait
else
    # 执行提供的命令
    exec "$@"
fi
