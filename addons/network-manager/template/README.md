# Network Manager

Network Manager 是一个 Haddons Addon，旨在为 Ubuntu Server 系统提供相关能力。

## 概述

Network Manager 为 Ubuntu Server 系统提供 WiFi 网络管理功能。该容器通过 NetworkManager 的 `nmcli` 命令行工具，实现对 WiFi 连接的扫描、连接、配置和管理。

## 核心能力

- **WiFi 网络管理**：扫描、连接、断开和管理 WiFi 网络连接
- **IP 地址配置**：支持 DHCP 自动分配和静态 IP 配置
- **网络状态监控**：实时监控网络连接状态和自动重连

## 主要功能

- ✅ WiFi 网络扫描：扫描并列出可用的 WiFi 网络
- ✅ WiFi 连接管理：连接、断开、重连 WiFi 网络
- ✅ IP 地址配置：支持 DHCP 自动分配和静态 IP 配置
- ✅ 网络连接状态监控：实时监控网络连接状态
- ✅ 网络配置持久化：配置自动保存，重启后保持
- ✅ 自动重连：支持连接断开时自动重连

## 适用场景

- 需要在 Ubuntu Server 系统上管理 WiFi 连接
- 需要在鲁班猫等设备上配置 WiFi 网络
- 需要自动化的网络连接管理
- 需要支持 DHCP 和静态 IP 配置

## 许可证

MIT
