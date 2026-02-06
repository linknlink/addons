# Network Manager 使用说明

本文档详细介绍如何使用 Network Manager Addon。

## 关于 Haddons

本 Addon 专为 **Haddons** 服务设计。Haddons 是一个参照 Home Assistant Add-on 管理实现的一套 Addon 管理系统，允许用户通过 Web 界面浏览、安装、配置、监控和管理基于 Docker Compose 的应用程序。

## 快速开始

### 使用 Haddons 服务

1. 确保 Haddons 服务正在运行
2. 将本 Addon 目录复制到 Haddons 的 `addons/` 目录
3. 在 Haddons Web 界面中刷新 Addon 列表
4. 点击"安装"按钮安装 Addon
5. 在"配置"标签页中配置 WiFi 连接信息（可选）：

   - `initial_wifi_ssid`: WiFi 网络名称
   - `initial_wifi_password`: WiFi 密码
   - `default_ip_method`: IP 配置方法（`dhcp` 或 `static`）
   - `wifi_scan_interval`: WiFi 扫描间隔（秒）
   - `auto_reconnect`: 是否自动重连
   - `log_level`: 日志级别

6. 点击"保存"保存配置
7. 点击"启动"按钮启动 Addon

### 使用 Docker Compose（开发/测试）

编辑 `docker-compose.yml`，配置必要的环境变量和挂载卷：

```yaml
environment:
  - INITIAL_WIFI_SSID=YourWiFiName
  - INITIAL_WIFI_PASSWORD=YourPassword
  - DEFAULT_IP_METHOD=dhcp
  - WIFI_SCAN_INTERVAL=30
  - AUTO_RECONNECT=true
  - LOG_LEVEL=info
```

启动容器：

```bash
docker-compose up -d
```

### 使用 Docker 命令

```bash
docker run -d \
  --name network_manager \
  --network host \
  --privileged \
  --restart unless-stopped \
  -e INITIAL_WIFI_SSID=YourWiFiName \
  -e INITIAL_WIFI_PASSWORD=YourPassword \
  -e DEFAULT_IP_METHOD=dhcp \
  -e AUTO_RECONNECT=true \
  -e LOG_LEVEL=info \
  ghcr.io/linknlink/network_manager:0.0.3
```

## 配置说明

请根据实际需求修改 `config.json` 中的配置项和 `docker-compose.yml` 中的环境变量。

### config.json 配置

`config.json` 是 Haddons 服务必需的配置文件，定义了 Addon 的元数据、配置选项和 Schema。

**主要配置选项**：

| 选项名 | 类型 | 说明 | 默认值 |
| ------ | ---- | ---- | ------ |
| `wifi_scan_interval` | int | WiFi 扫描间隔（秒） | `30` |
| `auto_reconnect` | bool | 是否自动重连 | `true` |
| `default_ip_method` | str | 默认 IP 配置方法 | `dhcp` |
| `log_level` | str | 日志级别 | `info` |
| `initial_wifi_ssid` | str | 初始连接的 WiFi 名称 | - |
| `initial_wifi_password` | str | WiFi 密码 | - |
| `initial_wifi_ip_address` | str | 静态 IP 地址（CIDR 格式） | - |
| `initial_wifi_gateway` | str | 网关地址 | - |
| `initial_wifi_dns` | str | DNS 服务器 | - |

**静态 IP 配置示例**：

在 Haddons Web 界面的"配置"标签页中设置：

```json
{
  "initial_wifi_ssid": "MyWiFi",
  "initial_wifi_password": "mypassword",
  "default_ip_method": "static",
  "initial_wifi_ip_address": "192.168.1.100/24",
  "initial_wifi_gateway": "192.168.1.1",
  "initial_wifi_dns": "8.8.8.8 8.8.4.4"
}
```

### docker-compose.yml 配置

`docker-compose.yml` 定义了容器的编排配置，包括镜像、环境变量、挂载卷等。

**重要配置**：

- `network_mode: host`：必须使用 host 网络模式才能访问主机的网络设备
- `privileged: true`：需要特权模式
- `cap_add: [NET_ADMIN, SYS_ADMIN]`：需要网络和管理权限

**环境变量映射**：

Haddons 服务会将 `config.json` 中的配置项映射为环境变量：

- `wifi_scan_interval` → `WIFI_SCAN_INTERVAL`
- `auto_reconnect` → `AUTO_RECONNECT`
- `default_ip_method` → `DEFAULT_IP_METHOD`
- `log_level` → `LOG_LEVEL`
- `initial_wifi_ssid` → `INITIAL_WIFI_SSID`
- `initial_wifi_password` → `INITIAL_WIFI_PASSWORD`
- `initial_wifi_ip_address` → `INITIAL_WIFI_IP_ADDRESS`
- `initial_wifi_gateway` → `INITIAL_WIFI_GATEWAY`
- `initial_wifi_dns` → `INITIAL_WIFI_DNS`

## 使用

### 在容器内执行命令

进入容器：

```bash
docker exec -it network_manager bash
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

## 注意事项

- **网络模式**：容器必须使用 `host` 网络模式才能访问主机的网络设备
- **权限要求**：需要 `privileged` 模式和 `NET_ADMIN`、`SYS_ADMIN` capabilities
- **NetworkManager 服务**：确保主机上的 NetworkManager 服务正在运行
- **WiFi 设备**：确保 WiFi 设备可用且未被其他服务占用
- **config.json 格式**：确保 `config.json` 格式正确，否则 Haddons 服务无法识别

## 故障排查

### 检查 NetworkManager 服务

```bash
sudo systemctl status NetworkManager
```

### 查看容器日志

在 Haddons Web 界面的"日志"标签页查看，或使用命令：

```bash
docker logs network_manager
```

### 检查 WiFi 设备

```bash
docker exec network_manager nmcli device status
```

### 查看详细日志

在 Haddons Web 界面的"配置"标签页中设置 `log_level` 为 `debug`，或在环境变量中设置 `LOG_LEVEL=debug`。

## 许可证

MIT
