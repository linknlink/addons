#!/bin/bash
set -e

echo "=========================================="
echo "  DeviceHub Addon 启动"
echo "=========================================="

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
