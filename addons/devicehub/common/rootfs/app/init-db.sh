#!/bin/bash
# DeviceHub 数据库初始化脚本

set -e

echo "=== 初始化 iegcloudaccess 数据库 ==="
mysql -uroot -e "
CREATE DATABASE IF NOT EXISTS iegcloudaccess DEFAULT CHARACTER SET UTF8;
CREATE USER IF NOT EXISTS 'iegcloudaccess'@'127.0.0.1' IDENTIFIED WITH mysql_native_password BY 'iegcloudaccesspwd';
ALTER USER IF EXISTS 'iegcloudaccess'@'127.0.0.1' IDENTIFIED WITH mysql_native_password BY 'iegcloudaccesspwd';
GRANT ALL PRIVILEGES ON iegcloudaccess.* TO 'iegcloudaccess'@'127.0.0.1';
ALTER USER 'iegcloudaccess'@'127.0.0.1' WITH MAX_USER_CONNECTIONS 128;
"
echo "    iegcloudaccess 数据库初始化完成"

echo "=== 初始化 ha2devicehub 数据库 ==="
mysql -uroot -e "
CREATE DATABASE IF NOT EXISTS ha2devicehub DEFAULT CHARACTER SET UTF8;
CREATE USER IF NOT EXISTS 'ha2devicehub'@'127.0.0.1' IDENTIFIED WITH mysql_native_password BY 'ha2devicehubpwd';
ALTER USER IF EXISTS 'ha2devicehub'@'127.0.0.1' IDENTIFIED WITH mysql_native_password BY 'ha2devicehubpwd';
GRANT ALL PRIVILEGES ON ha2devicehub.* TO 'ha2devicehub'@'127.0.0.1';
ALTER USER 'ha2devicehub'@'127.0.0.1' WITH MAX_USER_CONNECTIONS 128;
"
echo "    ha2devicehub 数据库初始化完成"

echo "=== 初始化 linknlink_edge 数据库 ==="
mysql -uroot -e "
CREATE DATABASE IF NOT EXISTS linknlink_edge CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'linknlink'@'localhost' IDENTIFIED BY 'a1b2c3d4';
GRANT ALL PRIVILEGES ON linknlink_edge.* TO 'linknlink'@'localhost';
FLUSH PRIVILEGES;
"

# 执行 linknlinkedge 建表脚本
mysql -uroot linknlink_edge < /app/database_init.sql
echo "    linknlink_edge 数据库及表结构初始化完成"

echo "=== 所有数据库初始化完成 ==="
