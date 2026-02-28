#!/bin/bash
set -e

echo "=========================================="
echo "  DeviceHub Addon 启动"
echo "=========================================="

# 获取本地首选的物理网卡 MAC 地址
# 返回的 MAC 地址格式为标准的冒号分隔的小写十六进制字符串，例如：00:11:22:33:44:55
get_physical_mac() {
    local eth_mac=""
    local wlan_mac=""

    for iface_path in /sys/class/net/*; do
        [ -e "$iface_path" ] || continue
        local iface=$(basename "$iface_path")

        # 1. 过滤 loopback, point-to-point 和常见虚拟网卡 (docker, veth, br 等)
        if [[ "$iface" == "lo" || "$iface" == docker* || "$iface" == veth* || "$iface" == br-* || "$iface" == ppp* || "$iface" == tun* || "$iface" == tap* ]]; then
            continue
        fi

        local mac=""
        if [ -f "$iface_path/address" ]; then
            mac=$(cat "$iface_path/address" | tr -d '\n')
        fi

        # 忽略空的或无效的 MAC
        if [[ -z "$mac" || "$mac" == "00:00:00:00:00:00" ]]; then
            continue
        fi

        # 2. 优先返回以太网卡 (eth, en 开头)
        if [[ "$iface" == eth* || "$iface" == en* ]]; then
            if [ -z "$eth_mac" ]; then
                eth_mac="$mac"
            fi
        # 3. 其次返回无线网卡 (wlan, wl 开头)
        elif [[ "$iface" == wlan* || "$iface" == wl* ]]; then
            if [ -z "$wlan_mac" ]; then
                wlan_mac="$mac"
            fi
        fi
    done

    # 4. 获取不到则返回空字符串
    if [ -n "$eth_mac" ]; then
        echo "$eth_mac"
    elif [ -n "$wlan_mac" ]; then
        echo "$wlan_mac"
    else
        echo ""
    fi
}

export HOST_MAC=$(get_physical_mac)
echo "  [INFO] 获取到宿主机 MAC 地址: ${HOST_MAC:-空}"

echo "[0/4] 加载预置的平台架构二进制文件..."
cp /app/bin/iegcloudaccess /etc/iegcloudaccess/iegcloudaccess
cp /app/bin/ha2devicehub /etc/ha2devicehub/ha2devicehub
cp /app/bin/linknlinkedge /etc/linknlinkedge/linknlinkedge

chmod +x /etc/iegcloudaccess/iegcloudaccess
chmod +x /etc/ha2devicehub/ha2devicehub
chmod +x /etc/linknlinkedge/linknlinkedge

# ---- 1. 初始化 MySQL 数据目录 ----
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "[1/4] 初始化 MariaDB 数据目录..."
    mysql_install_db --user=mysql --datadir=/var/lib/mysql > /dev/null 2>&1
    echo "      MariaDB 数据目录初始化完成"
else
    echo "[1/4] MariaDB 数据目录已存在，跳过初始化"
fi

# ---- 2. 启动 MariaDB 并初始化数据库 ----
echo "[2/4] 启动 MariaDB 临时实例..."
mysqld_safe --skip-networking &
MYSQL_PID=$!

# 等待 MariaDB 就绪
echo "      等待 MariaDB 就绪..."
for i in $(seq 1 30); do
    if mysqladmin ping --silent 2>/dev/null; then
        echo "      MariaDB 已就绪"
        break
    fi
    if [ $i -eq 30 ]; then
        echo "      错误：MariaDB 启动超时"
        exit 1
    fi
    sleep 1
done

# 设置初始化标记
if [ ! -f "/var/lib/mysql/.db_initialized" ]; then
    echo "[3/4] 初始化数据库..."
    
    # 执行数据库初始化脚本
    bash /app/init-db.sh
    
    # 写入初始化标记
    touch /var/lib/mysql/.db_initialized
    echo "      数据库初始化完成"
else
    echo "[3/4] 数据库已初始化，跳过"
fi

# 停止临时 MariaDB 实例
echo "      停止 MariaDB 临时实例..."
mysqladmin -uroot shutdown 2>/dev/null || kill $MYSQL_PID 2>/dev/null || true
sleep 2

# ---- 3. 启动 supervisord ----
echo "[4/4] 启动 supervisord（管理所有服务）..."
echo "=========================================="
echo "  服务端口："
echo "    mosquitto:      1883"
echo "    mariadb:        3306"
echo "    iegcloudaccess: 1692"
echo "    ha2devicehub:   1691"
echo "    linknlinkedge:  1696"
echo "=========================================="

exec /usr/bin/supervisord -n -c /app/supervisord.conf
