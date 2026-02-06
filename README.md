# LinknLink Docker Containers Repository

这是一个 Docker 容器应用集合，旨在为 Ubuntu Server 系统提供相关能力。

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

**注意：** 这些容器应用主要针对 Ubuntu Server 系统（特别是鲁班猫设备）设计。
