#!/bin/bash

# 配置验证脚本

source /app/utils.sh

# 验证 IP 地址格式
validate_ip() {
    local ip=$1
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        # 验证每个段是否在 0-255 范围内
        IFS='.' read -ra ADDR <<< "$ip"
        for i in "${ADDR[@]}"; do
            if [ "$i" -gt 255 ] || [ "$i" -lt 0 ]; then
                return 1
            fi
        done
        return 0
    fi
    return 1
}

# 验证 CIDR 格式
validate_cidr() {
    local cidr=$1
    if [[ $cidr =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/[0-9]{1,2}$ ]]; then
        local ip=$(echo "$cidr" | cut -d'/' -f1)
        local prefix=$(echo "$cidr" | cut -d'/' -f2)
        
        if ! validate_ip "$ip"; then
            return 1
        fi
        
        if [ "$prefix" -gt 32 ] || [ "$prefix" -lt 0 ]; then
            return 1
        fi
        
        return 0
    fi
    return 1
}

# 验证配置
validate_config() {
    local errors=0
    
    # 验证 WIFI_SCAN_INTERVAL
    if [ -n "$WIFI_SCAN_INTERVAL" ]; then
        if ! [[ "$WIFI_SCAN_INTERVAL" =~ ^[0-9]+$ ]] || [ "$WIFI_SCAN_INTERVAL" -lt 1 ]; then
            log ERROR "WIFI_SCAN_INTERVAL 必须是正整数"
            errors=$((errors + 1))
        fi
    fi
    
    # 验证 DEFAULT_IP_METHOD
    if [ -n "$DEFAULT_IP_METHOD" ]; then
        if [ "$DEFAULT_IP_METHOD" != "dhcp" ] && [ "$DEFAULT_IP_METHOD" != "static" ]; then
            log ERROR "DEFAULT_IP_METHOD 必须是 'dhcp' 或 'static'"
            errors=$((errors + 1))
        fi
    fi
    
    # 验证静态 IP 配置（如果使用静态 IP）
    if [ "$DEFAULT_IP_METHOD" = "static" ] || [ -n "$INITIAL_WIFI_IP_ADDRESS" ]; then
        if [ -n "$INITIAL_WIFI_IP_ADDRESS" ]; then
            if ! validate_cidr "$INITIAL_WIFI_IP_ADDRESS"; then
                log ERROR "INITIAL_WIFI_IP_ADDRESS 格式无效，应为 CIDR 格式 (例如: 192.168.1.100/24)"
                errors=$((errors + 1))
            fi
        else
            log ERROR "使用静态 IP 模式时，必须设置 INITIAL_WIFI_IP_ADDRESS"
            errors=$((errors + 1))
        fi
        
        if [ -n "$INITIAL_WIFI_GATEWAY" ]; then
            if ! validate_ip "$INITIAL_WIFI_GATEWAY"; then
                log ERROR "INITIAL_WIFI_GATEWAY 格式无效"
                errors=$((errors + 1))
            fi
        fi
        
        if [ -n "$INITIAL_WIFI_DNS" ]; then
            # DNS 可以是多个，用空格分隔
            IFS=' ' read -ra DNS_ARRAY <<< "$INITIAL_WIFI_DNS"
            for dns in "${DNS_ARRAY[@]}"; do
                if ! validate_ip "$dns"; then
                    log ERROR "DNS 服务器地址格式无效: $dns"
                    errors=$((errors + 1))
                fi
            done
        fi
    fi
    
    # 验证 LOG_LEVEL
    if [ -n "$LOG_LEVEL" ]; then
        case "$LOG_LEVEL" in
            debug|info|warning|error)
                ;;
            *)
                log ERROR "LOG_LEVEL 必须是: debug, info, warning, error"
                errors=$((errors + 1))
                ;;
        esac
    fi
    
    if [ $errors -gt 0 ]; then
        log ERROR "配置验证失败，发现 $errors 个错误"
        return 1
    fi
    
    log INFO "配置验证通过"
    return 0
}

# 主函数
main() {
    log INFO "开始验证配置..."
    validate_config
    exit $?
}

# 如果直接执行此脚本
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
