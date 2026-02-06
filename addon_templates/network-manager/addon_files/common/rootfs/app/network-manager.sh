#!/bin/bash

# Network Manager 核心管理脚本

source /app/utils.sh

# WiFi 扫描
wifi_scan() {
    log INFO "扫描 WiFi 网络..."
    
    if ! check_network_manager; then
        return 1
    fi
    
    if ! check_wifi_device; then
        return 1
    fi
    
    # 使用 JSON 格式输出
    if command -v jq >/dev/null 2>&1; then
        nmcli device wifi list --format json 2>/dev/null | jq '.' || {
            # 如果 JSON 解析失败，使用表格格式
            nmcli device wifi list
        }
    else
        nmcli device wifi list
    fi
}

# WiFi 连接
wifi_connect() {
    local ssid=""
    local password=""
    local ip_method="dhcp"
    local ip_address=""
    local gateway=""
    local dns=""
    
    # 解析参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            --ssid)
                ssid="$2"
                shift 2
                ;;
            --password)
                password="$2"
                shift 2
                ;;
            --ip-method)
                ip_method="$2"
                shift 2
                ;;
            --ip-address)
                ip_address="$2"
                shift 2
                ;;
            --gateway)
                gateway="$2"
                shift 2
                ;;
            --dns)
                dns="$2"
                shift 2
                ;;
            *)
                log ERROR "未知参数: $1"
                return 1
                ;;
        esac
    done
    
    # 验证必需参数
    if [ -z "$ssid" ]; then
        log ERROR "必须提供 SSID"
        return 1
    fi
    
    log INFO "连接到 WiFi: $ssid"
    
    if ! check_network_manager; then
        return 1
    fi
    
    if ! check_wifi_device; then
        return 1
    fi
    
    # 构建连接命令
    local cmd="nmcli device wifi connect \"$ssid\""
    
    if [ -n "$password" ]; then
        cmd="$cmd password \"$password\""
    fi
    
    # 配置 IP 方法
    if [ "$ip_method" = "static" ]; then
        if [ -z "$ip_address" ]; then
            log ERROR "静态 IP 模式需要提供 IP 地址"
            return 1
        fi
        
        cmd="$cmd ipv4.method manual ipv4.addresses \"$ip_address\""
        
        if [ -n "$gateway" ]; then
            cmd="$cmd ipv4.gateway \"$gateway\""
        fi
        
        if [ -n "$dns" ]; then
            cmd="$cmd ipv4.dns \"$dns\""
        fi
    else
        cmd="$cmd ipv4.method auto"
    fi
    
    log DEBUG "执行命令: $cmd"
    
    # 执行连接
    if eval "$cmd"; then
        log INFO "成功连接到 $ssid"
        return 0
    else
        log ERROR "连接失败"
        return 1
    fi
}

# 断开连接
wifi_disconnect() {
    local connection_name="$1"
    
    if [ -z "$connection_name" ]; then
        # 如果没有指定连接名，断开当前活动的 WiFi 连接
        connection_name=$(nmcli connection show --active | grep -i wifi | head -n1 | awk '{print $1}')
        
        if [ -z "$connection_name" ]; then
            log WARNING "没有活动的 WiFi 连接"
            return 1
        fi
    fi
    
    log INFO "断开连接: $connection_name"
    
    if nmcli connection down "$connection_name"; then
        log INFO "成功断开连接"
        return 0
    else
        log ERROR "断开连接失败"
        return 1
    fi
}

# 查看状态
get_status() {
    log INFO "获取网络状态..."
    
    if ! check_network_manager; then
        return 1
    fi
    
    echo "=== 设备状态 ==="
    nmcli device status
    
    echo ""
    echo "=== 活动连接 ==="
    nmcli connection show --active
    
    echo ""
    echo "=== 设备详细信息 ==="
    nmcli device show
    
    # JSON 格式输出（如果支持）
    if command -v jq >/dev/null 2>&1; then
        echo ""
        echo "=== JSON 格式 ==="
        nmcli device status --format json 2>/dev/null | jq '.' || true
    fi
}

# 配置 IP
configure_ip() {
    local connection_name="$1"
    local ip_method="$2"
    local ip_address="$3"
    local gateway="$4"
    local dns="$5"
    
    if [ -z "$connection_name" ]; then
        log ERROR "必须提供连接名称"
        return 1
    fi
    
    if [ -z "$ip_method" ]; then
        log ERROR "必须提供 IP 方法 (dhcp 或 static)"
        return 1
    fi
    
    log INFO "配置连接 $connection_name 的 IP 设置 (方法: $ip_method)"
    
    if ! check_network_manager; then
        return 1
    fi
    
    # 检查连接是否存在
    if ! nmcli connection show "$connection_name" >/dev/null 2>&1; then
        log ERROR "连接不存在: $connection_name"
        return 1
    fi
    
    # 构建修改命令
    local cmd="nmcli connection modify \"$connection_name\""
    
    if [ "$ip_method" = "static" ]; then
        if [ -z "$ip_address" ]; then
            log ERROR "静态 IP 模式需要提供 IP 地址"
            return 1
        fi
        
        cmd="$cmd ipv4.method manual ipv4.addresses \"$ip_address\""
        
        if [ -n "$gateway" ]; then
            cmd="$cmd ipv4.gateway \"$gateway\""
        fi
        
        if [ -n "$dns" ]; then
            cmd="$cmd ipv4.dns \"$dns\""
        fi
    else
        cmd="$cmd ipv4.method auto"
    fi
    
    log DEBUG "执行命令: $cmd"
    
    # 执行修改
    if eval "$cmd"; then
        log INFO "配置已更新，重新激活连接..."
        
        # 重新激活连接
        nmcli connection down "$connection_name"
        if nmcli connection up "$connection_name"; then
            log INFO "连接已重新激活"
            return 0
        else
            log ERROR "重新激活连接失败"
            return 1
        fi
    else
        log ERROR "配置更新失败"
        return 1
    fi
}

# 列出所有连接
list_connections() {
    log INFO "列出所有连接..."
    
    if ! check_network_manager; then
        return 1
    fi
    
    nmcli connection show
    
    # JSON 格式输出（如果支持）
    if command -v jq >/dev/null 2>&1; then
        echo ""
        echo "=== JSON 格式 ==="
        nmcli connection show --format json 2>/dev/null | jq '.' || true
    fi
}

# 删除连接
delete_connection() {
    local connection_name="$1"
    
    if [ -z "$connection_name" ]; then
        log ERROR "必须提供连接名称"
        return 1
    fi
    
    log INFO "删除连接: $connection_name"
    
    if ! check_network_manager; then
        return 1
    fi
    
    if nmcli connection delete "$connection_name"; then
        log INFO "成功删除连接"
        return 0
    else
        log ERROR "删除连接失败"
        return 1
    fi
}

# 监控连接
monitor() {
    log INFO "开始监控网络连接..."
    
    if ! check_network_manager; then
        return 1
    fi
    
    local scan_interval=${WIFI_SCAN_INTERVAL:-30}
    local last_status=""
    
    while true; do
        local current_status=$(nmcli device status | grep -i wifi | head -n1 | awk '{print $3}')
        
        if [ "$current_status" != "$last_status" ]; then
            log INFO "连接状态变化: $last_status -> $current_status"
            last_status="$current_status"
        fi
        
        # 检查是否需要自动重连
        if [ "$AUTO_RECONNECT" = "true" ] && [ "$current_status" != "connected" ]; then
            if [ -n "$INITIAL_WIFI_SSID" ]; then
                log INFO "检测到连接断开，尝试重新连接..."
                wifi_connect \
                    --ssid "$INITIAL_WIFI_SSID" \
                    --password "${INITIAL_WIFI_PASSWORD:-}" \
                    --ip-method "${DEFAULT_IP_METHOD:-dhcp}" \
                    --ip-address "${INITIAL_WIFI_IP_ADDRESS:-}" \
                    --gateway "${INITIAL_WIFI_GATEWAY:-}" \
                    --dns "${INITIAL_WIFI_DNS:-}"
            fi
        fi
        
        sleep "$scan_interval"
    done
}

# 主函数
main() {
    local command="${1:-}"
    shift || true
    
    case "$command" in
        scan)
            wifi_scan "$@"
            ;;
        connect)
            wifi_connect "$@"
            ;;
        disconnect)
            wifi_disconnect "$@"
            ;;
        status)
            get_status "$@"
            ;;
        configure)
            configure_ip "$@"
            ;;
        list)
            list_connections "$@"
            ;;
        delete)
            delete_connection "$@"
            ;;
        monitor)
            monitor "$@"
            ;;
        *)
            echo "使用方法: $0 <command> [options]"
            echo ""
            echo "命令:"
            echo "  scan                    - 扫描 WiFi 网络"
            echo "  connect                 - 连接 WiFi"
            echo "    --ssid <ssid>         - WiFi 名称（必需）"
            echo "    --password <pass>     - WiFi 密码"
            echo "    --ip-method <method>  - IP 方法 (dhcp|static)"
            echo "    --ip-address <addr>   - IP 地址 (CIDR 格式)"
            echo "    --gateway <gateway>   - 网关地址"
            echo "    --dns <dns>           - DNS 服务器"
            echo "  disconnect [name]      - 断开连接"
            echo "  status                 - 查看网络状态"
            echo "  configure <name> <method> [ip] [gateway] [dns] - 配置 IP"
            echo "  list                   - 列出所有连接"
            echo "  delete <name>          - 删除连接"
            echo "  monitor                - 监控连接状态"
            exit 1
            ;;
    esac
}

# 如果直接执行此脚本
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
