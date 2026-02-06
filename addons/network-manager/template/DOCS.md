# Network Manager 使用说明

本文档详细介绍如何在生产环境中使用 Network Manager Addon。此文档会显示在 Haddons Web 界面的"文档"标签页中，面向最终用户（ToC 产品用户）。

## 快速开始

### 安装和启动

1. 在 Haddons Web 界面中找到 Network Manager
2. 点击"安装"按钮安装 Addon
3. 安装完成后，在"配置"标签页中配置必要的选项（如需要）
4. 点击"保存"保存配置
5. 点击"启动"按钮启动 Addon

### 首次配置

首次使用时，建议在"配置"标签页中设置以下选项：

- **initial_wifi_ssid**：WiFi 网络名称（SSID），用于首次连接
- **initial_wifi_password**：WiFi 密码，用于首次连接
- **default_ip_method**：IP 配置方法，`dhcp`（自动）或 `static`（静态）
- **wifi_scan_interval**：WiFi 扫描间隔（秒），默认 30 秒
- **auto_reconnect**：是否自动重连，默认 `true`

## 配置说明

### 配置选项说明

在 Haddons Web 界面的"配置"标签页中，您可以配置以下选项：

| 配置项 | 类型 | 说明 | 默认值 | 必填 |
|--------|------|------|--------|------|
| `wifi_scan_interval` | int | WiFi 扫描间隔（秒） | `30` | 否 |
| `auto_reconnect` | bool | 是否自动重连 | `true` | 否 |
| `default_ip_method` | str | 默认 IP 配置方法（`dhcp` 或 `static`） | `dhcp` | 否 |
| `log_level` | str | 日志级别（`info`、`debug` 等） | `info` | 否 |
| `initial_wifi_ssid` | str | 初始连接的 WiFi 名称（SSID） | - | 否 |
| `initial_wifi_password` | str | WiFi 密码 | - | 否 |
| `initial_wifi_ip_address` | str | 静态 IP 地址（CIDR 格式，如 `192.168.1.100/24`） | - | 否 |
| `initial_wifi_gateway` | str | 网关地址（使用静态 IP 时必填） | - | 否 |
| `initial_wifi_dns` | str | DNS 服务器（使用静态 IP 时可选，多个用空格分隔） | - | 否 |

### 配置示例

**示例 1：基本配置（DHCP）**

```json
{
  "initial_wifi_ssid": "MyWiFi",
  "initial_wifi_password": "mypassword",
  "default_ip_method": "dhcp",
  "wifi_scan_interval": 30,
  "auto_reconnect": true,
  "log_level": "info"
}
```

**示例 2：静态 IP 配置**

```json
{
  "initial_wifi_ssid": "MyWiFi",
  "initial_wifi_password": "mypassword",
  "default_ip_method": "static",
  "initial_wifi_ip_address": "192.168.1.100/24",
  "initial_wifi_gateway": "192.168.1.1",
  "initial_wifi_dns": "8.8.8.8 8.8.4.4",
  "wifi_scan_interval": 30,
  "auto_reconnect": true,
  "log_level": "info"
}
```

## 使用指南

### 基本操作

#### 查看状态

在 Haddons Web 界面的"信息"标签页中，您可以查看 Addon 的运行状态、版本信息等。

#### 查看日志

在 Haddons Web 界面的"日志"标签页中，您可以实时查看 Addon 的运行日志，帮助排查问题。

#### 重启服务

如果需要重启 Addon，可以在"信息"标签页中点击"重启"按钮。

### 常见使用场景

#### 场景 1：首次连接 WiFi 网络

1. 在"配置"标签页中设置 `initial_wifi_ssid` 和 `initial_wifi_password`
2. 设置 `default_ip_method` 为 `dhcp`（自动获取 IP）或 `static`（静态 IP）
3. 如果使用静态 IP，还需要设置 `initial_wifi_ip_address`、`initial_wifi_gateway` 和 `initial_wifi_dns`
4. 点击"保存"保存配置
5. 点击"启动"启动 Addon，Addon 会自动连接到指定的 WiFi 网络

#### 场景 2：监控和管理 WiFi 连接

1. Addon 启动后会自动扫描可用的 WiFi 网络
2. 可以通过日志查看扫描结果和连接状态
3. 如果连接断开，Addon 会自动重连（如果 `auto_reconnect` 设置为 `true`）

## 注意事项

### 使用前检查

- ✅ 确保系统满足 Addon 的运行要求（Ubuntu Server，NetworkManager 服务运行中）
- ✅ 检查 WiFi 设备是否可用且未被其他服务占用
- ✅ 确认网络连接正常（如需要）
- ✅ 确保容器有足够的权限（需要 `privileged` 模式和 `NET_ADMIN`、`SYS_ADMIN` capabilities）

### 重要提醒

- **权限要求**：容器必须使用 `privileged` 模式和 `host` 网络模式才能访问主机的网络设备
- **资源占用**：Addon 资源占用较低，主要依赖 NetworkManager 服务
- **数据安全**：WiFi 密码等敏感信息会存储在配置中，请妥善保管
- **网络模式**：必须使用 `host` 网络模式，不能使用桥接网络

## 故障排查

### 常见问题

#### 问题 1：Addon 无法启动

**可能原因**：
- NetworkManager 服务未运行
- WiFi 设备不可用或被占用
- 权限不足
- 配置错误

**解决方法**：
1. 检查主机上的 NetworkManager 服务是否运行：`sudo systemctl status NetworkManager`
2. 检查"配置"标签页中的配置是否正确
3. 查看"日志"标签页中的错误信息
4. 确认容器有足够的权限（`privileged` 模式和 `NET_ADMIN`、`SYS_ADMIN` capabilities）

#### 问题 2：无法连接到 WiFi

**可能原因**：
- WiFi 密码错误
- WiFi 信号弱
- 网络配置不正确（静态 IP 配置错误）
- WiFi 设备问题

**解决方法**：
1. 检查 WiFi 密码是否正确
2. 检查 WiFi 信号强度
3. 如果使用静态 IP，检查 IP 地址、网关和 DNS 配置是否正确
4. 查看日志获取详细错误信息
5. 检查 WiFi 设备是否正常工作

#### 问题 3：连接频繁断开

**可能原因**：
- WiFi 信号不稳定
- 网络配置问题
- 自动重连配置未启用

**解决方法**：
1. 检查 WiFi 信号强度
2. 确保 `auto_reconnect` 设置为 `true`
3. 检查网络配置是否正确
4. 查看日志了解断开原因

### 获取帮助

如果遇到问题无法解决，可以：

1. 查看"日志"标签页获取详细错误信息
2. 检查配置是否正确
3. 确认 NetworkManager 服务状态
4. 联系技术支持

## 更新和维护

### 更新 Addon

当有新版本可用时，Haddons 会在"信息"标签页中提示更新。点击"更新"按钮即可升级到最新版本。

### 备份配置

建议定期备份"配置"标签页中的配置信息，以便在需要时快速恢复。

## 许可证

MIT
