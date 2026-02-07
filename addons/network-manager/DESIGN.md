# Network Manager Web Interface Design

## 概述

本设计旨在为 `network-manager` 插件添加一个独立于 Home Assistant 配置文件的 Web 管理界面。
允许用户通过浏览器扫描、选择并连接 WiFi 网络，支持 DHCP 和静态 IP 配置。

## 架构设计

### 1. 后端 (Python Flask)

-   **框架**: Flask
-   **端口**: 8201 (通过 Ingress 暴露)
-   **核心功能**:
    -   调用 `nmcli` 命令行工具执行网络操作。
    -   提供 RESTful API 供前端调用。

#### API 接口

| Method | Endpoint | Description | Parameters |
| :--- | :--- | :--- | :--- |
| `GET` | `/api/wifi/scan` | 扫描并返回 WiFi 列表 | None |
| `POST` | `/api/wifi/connect` | 连接指定 WiFi | `ssid`, `password`, `method` (auto/manual), `ip`, `gateway`, `dns` |
| `GET` | `/api/status` | 获取网络接口状态 | None |

### 2. 前端 (HTML/CSS/JS)

-   **技术栈**: 原生 HTML5, CSS3, JavaScript (ES6+)。
-   **界面组成**:
    -   **状态栏**: 显示当前网络连接状态（接口、IP、连接状态）。
    -   **WiFi 列表**: 展示扫描到的 WiFi 热点、信号强度、加密状态。
    -   **连接弹窗**:
        -   密码输入框。
        -   **IP 分配方式选择**: "自动 (DHCP)" 或 "手动 (Static)"。
        -   **静态 IP 配置**: IP 地址、网关、DNS 输入框（仅在手动模式下显示）。

### 3. 集成 (Ingress)

-   在 `config.json` 中启用 `ingress: true`。
-   配置 `ingress_port: 8201`。
-   Home Assistant 将通过 Ingress 代理访问该端口。

## 详细配置

### config.json

```json
{
  "name": "Network Manager",
  "version": "0.0.3",
  "slug": "network-manager",
  "description": "...",
  "startup": "application",
  "boot": "manual",
  "ingress": true,
  "ingress_port": 8201,
  "options": { ... },
  "schema": { ... }
}
```

### Docker 容器

-   基于 `debian:bookworm-slim`。
-   安装 `network-manager`, `nmcli` 以及 `python3`, `python3-flask`。
-   启动脚本 `docker-entrypoint.sh` 在后台启动 Python Web 服务。

## 交互流程

1.  **启动**: 容器启动，Web 服务监听 8201 端口。
2.  **访问**: 用户点击 Addon 的 "Open Web UI"。
3.  **扫描**: 前端自动调用 `/api/wifi/scan`，展示 WiFi 列表。
4.  **连接 (DHCP)**:
    -   用户点击 WiFi，输入密码，点击连接。
    -   后端执行 `nmcli device wifi connect <ssid> password <password>`。
5.  **连接 (Static)**:
    -   用户选择 "手动"，输入 IP/网关/DNS。
    -   后端执行 `nmcli device wifi connect <ssid> password <password> ipv4.method manual ipv4.addresses <ip> ipv4.gateway <gw> ...`。
6.  **反馈**: 界面显示连接进度，连接成功后刷新状态。
