#!/bin/bash
set -e

echo "Starting HACS Installer..."

# 启动 Web 服务
exec python3 /app/web/app.py
