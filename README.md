# LinknLink Addons Repository

这是一个用于 **Haddons** 服务的 Addon 仓库。Haddons 是一个参照 Home Assistant Add-on 管理实现的一套 Addon 管理系统，本仓库中的 Addon 专为 Haddons 服务设计和使用。

## 关于 Haddons

Haddons 是一个基于 Go 语言开发的 Addon 管理服务系统，模仿 Home Assistant (HA) 的 Add-ons 管理页面设计。该系统允许用户通过 Web 界面浏览、安装、配置、监控和管理基于 Docker Compose 的应用程序（Addons）。

本仓库中的 Addon 遵循 Haddons 的配置规范，可以直接部署到 Haddons 服务中使用。

## 📦 可用容器应用

### Network Manager

WiFi 网络管理容器，通过 NetworkManager 提供 WiFi 连接、配置和管理功能。

**主要特性：**
- WiFi 网络扫描和连接
- DHCP 和静态 IP 配置
- 网络连接状态监控
- 支持多种架构（aarch64, amd64, armv7）

### LinknLink Remote

远程访问容器，通过 LinknLink 平台提供远程访问功能。

**主要特性：**
- 零配置远程访问（仅需账户凭证）
- 自动设备注册和代理配置
- 安全加密隧道
- 支持多种架构（aarch64, amd64, armv7）

## 🚀 使用

### Docker Compose 方式

```yaml
services:
  network-manager:
    image: ghcr.io/linknlink/network-manager:latest
    container_name: network-manager
    network_mode: host
    privileged: true
    restart: unless-stopped
```

### Docker 命令行方式

```bash
docker run -d \
  --name network-manager \
  --network host \
  --privileged \
  ghcr.io/linknlink/network-manager:latest
```

## 📚 文档

- [设计文档](docs/DESIGN.md) - 仓库框架设计说明
- [容器开发指南](docs/ADDON_GUIDE.md) - 如何开发和添加新的容器应用
- [贡献指南](docs/CONTRIBUTING.md) - 如何参与贡献

## 🛠️ 开发

### 添加新容器应用

```bash
./scripts/add-addon.sh <container-name>
```

### 构建容器

```bash
./scripts/build-addon.sh <container-name>
```

### 发布容器

```bash
./scripts/release-addon.sh <container-name> patch
```

更多信息请参考 [设计文档](docs/DESIGN.md)。

## 📝 许可证

本项目采用 MIT 许可证。

## 🤝 贡献

欢迎贡献！请查看 [贡献指南](docs/CONTRIBUTING.md) 了解详细信息。

## 📞 支持

如有问题或建议：

- 通过 [GitHub Issues](https://github.com/linknlink/addons/issues) 提交反馈
- 查看各容器应用的文档和更新日志

---

**注意：** 
- 这些 Addon 专为 **Haddons** 服务设计，需要配合 Haddons 服务使用
- 主要针对 Ubuntu Server 系统（特别是鲁班猫设备）优化
- 关于 Haddons 服务的详细信息，请参考 [Haddons 项目文档](/home/linknlink/1_codes/src/edge/haddons/docs)
