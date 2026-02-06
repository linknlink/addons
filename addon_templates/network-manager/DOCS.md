# Network Manager

Network Manager 是一个 Docker 容器应用，旨在为 Ubuntu Server 系统（特别是鲁班猫设备）提供 WiFi 网络管理功能。该容器通过 NetworkManager 的 `nmcli` 命令行工具，实现对 WiFi 连接的扫描、连接、配置和管理。

## 功能

- ✅ **WiFi 网络扫描**：扫描并列出可用的 WiFi 网络
- ✅ **WiFi 连接管理**：连接、断开、重连 WiFi 网络
- ✅ **IP 地址配置**：支持 DHCP 自动分配和静态 IP 配置
- ✅ **网络连接状态监控**：实时监控网络连接状态
- ✅ **网络配置持久化**：配置自动保存，重启后保持
- ✅ **自动重连**：支持连接断开时自动重连

## 系统要求

- Ubuntu Server（推荐 22.04 或更高版本）
- Docker 和 Docker Compose
- NetworkManager（通常已预装）
- WiFi 设备（wlan0, wlan1 等）

## 快速开始

### 使用 Docker Compose

1. 克隆或下载项目后，进入 `addons/network-manager` 目录

2. 编辑 `docker-compose.yml`，配置 WiFi 连接信息（可选）：

```yaml
environment:
  - INITIAL_WIFI_SSID=YourWiFiName
  - INITIAL_WIFI_PASSWORD=YourPassword
  - DEFAULT_IP_METHOD=dhcp  # 或 static
```

3. 启动容器：

```bash
docker-compose up -d
```

### 使用 Docker 命令

```bash
docker run -d \
  --name network-manager \
  --network host \
  --privileged \
  -e INITIAL_WIFI_SSID=YourWiFiName \
  -e INITIAL_WIFI_PASSWORD=YourPassword \
  -e DEFAULT_IP_METHOD=dhcp \
  -e AUTO_RECONNECT=true \
  -e LOG_LEVEL=info \
  ghcr.io/linknlink/network_manager:latest
```

## 配置

### 环境变量

| 变量名 | 说明 | 默认值 | 示例 |
|--------|------|--------|------|
| `WIFI_SCAN_INTERVAL` | WiFi 扫描间隔（秒） | `30` | `60` |
| `AUTO_RECONNECT` | 是否自动重连 | `true` | `true` / `false` |
| `DEFAULT_IP_METHOD` | 默认 IP 配置方法 | `dhcp` | `dhcp` / `static` |
| `LOG_LEVEL` | 日志级别 | `info` | `debug` / `info` / `warning` / `error` |
| `INITIAL_WIFI_SSID` | 初始连接的 WiFi 名称 | - | `MyWiFi` |
| `INITIAL_WIFI_PASSWORD` | WiFi 密码 | - | `mypassword` |
| `INITIAL_WIFI_IP_ADDRESS` | 静态 IP 地址（CIDR 格式） | - | `192.168.1.100/24` |
| `INITIAL_WIFI_GATEWAY` | 网关地址 | - | `192.168.1.1` |
| `INITIAL_WIFI_DNS` | DNS 服务器 | - | `8.8.8.8 8.8.4.4` |

### 静态 IP 配置示例

```yaml
environment:
  - INITIAL_WIFI_SSID=MyWiFi
  - INITIAL_WIFI_PASSWORD=mypassword
  - DEFAULT_IP_METHOD=static
  - INITIAL_WIFI_IP_ADDRESS=192.168.1.100/24
  - INITIAL_WIFI_GATEWAY=192.168.1.1
  - INITIAL_WIFI_DNS=8.8.8.8 8.8.4.4
```

## 使用

### 在容器内执行命令

进入容器：

```bash
docker exec -it network-manager bash
```

### 扫描 WiFi 网络

```bash
/app/network-manager.sh scan
```

### 连接 WiFi（DHCP）

```bash
/app/network-manager.sh connect \
  --ssid "MyWiFi" \
  --password "mypassword" \
  --ip-method dhcp
```

### 连接 WiFi（静态 IP）

```bash
/app/network-manager.sh connect \
  --ssid "MyWiFi" \
  --password "mypassword" \
  --ip-method static \
  --ip-address "192.168.1.100/24" \
  --gateway "192.168.1.1" \
  --dns "8.8.8.8 8.8.4.4"
```

### 查看网络状态

```bash
/app/network-manager.sh status
```

### 列出所有连接

```bash
/app/network-manager.sh list
```

### 断开连接

```bash
/app/network-manager.sh disconnect [连接名称]
```

### 配置 IP 地址

```bash
# 切换到 DHCP
/app/network-manager.sh configure "MyWiFi" dhcp

# 切换到静态 IP
/app/network-manager.sh configure "MyWiFi" static \
  192.168.1.100/24 \
  192.168.1.1 \
  "8.8.8.8 8.8.4.4"
```

### 删除连接

```bash
/app/network-manager.sh delete "MyWiFi"
```

## 构建

### 本地构建

```bash
cd addons/network-manager
docker build -t network-manager:local -f common/Dockerfile common/
```

### 使用构建脚本

```bash
./scripts/build-addon.sh network-manager
```

### 发布（通过 workflow）

创建 Git tag 触发自动构建：

```bash
git tag network-manager-v0.0.1
git push origin network-manager-v0.0.1
```

## 注意事项

1. **网络模式**：容器必须使用 `host` 网络模式才能访问主机的网络设备
2. **权限要求**：需要 `privileged` 模式和 `NET_ADMIN`、`SYS_ADMIN` capabilities
3. **NetworkManager 服务**：确保主机上的 NetworkManager 服务正在运行
4. **WiFi 设备**：确保 WiFi 设备可用且未被其他服务占用

## 故障排查

### 检查 NetworkManager 服务

```bash
sudo systemctl status NetworkManager
```

### 查看容器日志

```bash
docker logs network-manager
```

### 检查 WiFi 设备

```bash
docker exec network-manager nmcli device status
```

### 查看详细日志

设置 `LOG_LEVEL=debug` 环境变量以获取更详细的日志信息。

## 文档

- [设计方案](./docs/设计方案.md)
- [配置指南](./docs/配置指南.md)

## 许可证

MIT
