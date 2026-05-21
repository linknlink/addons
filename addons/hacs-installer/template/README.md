# HACS Installer

HACS Installer 是一个 Haddons Addon，用于安装 HACS 文件，并引导用户完成 Home Assistant 中必需的 HACS 集成配置。

## 概述

HACS Installer 为 Home Assistant 用户提供 HACS (Home Assistant Community Store) 的一键安装、管理和卸载能力。通过简洁的 Web 界面，用户可以安装 HACS 文件、重启 Home Assistant，并按照提示在 Home Assistant 中添加 HACS 集成和完成 GitHub 授权。

## 核心能力

- **一键安装**：自动化下载并安装最新版本的 HACS
- **安装后引导**：说明如何重启 Home Assistant、添加 HACS 集成并完成 GitHub 授权
- **智能管理**：自动检测安装状态，支持重新安装
- **卸载支持**：提供一键卸载功能，清理残留文件

## 主要功能

- ✅ 自动安装：从 GitHub 官方源获取最新 HACS 并安装到指定目录
- ✅ 配置引导：在文件安装完成后提示 Home Assistant 内的后续配置步骤
- ✅ 状态检测：实时检查 HACS 是否已安装
- ✅ 一键卸载：安全移除 HACS 及其相关文件
- ✅ 网络优化：内置网络连接检查，确保安装过程顺畅
- ✅ 端口配置：使用 8202 端口提供服务

## 适用场景

- 需要快速在 Home Assistant 中启用社区商店功能
- 不熟悉命令行操作，希望通过图形界面管理 HACS
- 需要在多台设备上快速部署 HACS
- 需要方便地卸载和重装 HACS 进行故障排查

## 许可证

MIT
