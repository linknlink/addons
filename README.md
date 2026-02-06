# LinknLink Home Assistant Add-ons Repository

这是一个用于管理多个 Home Assistant Add-ons 的统一仓库。

## 📦 可用 Add-ons

### LinknLink Remote

Home Assistant add-on，通过 LinknLink 平台提供远程访问功能。

**主要特性：**
- 零配置远程访问（仅需账户凭证）
- 自动设备注册和代理配置
- 安全加密隧道
- 支持多种架构（aarch64, amd64, armv7）

[![Install Add-on][addon-badge]][addon]

[addon-badge]: https://my.home-assistant.io/badges/supervisor_addon.svg
[addon]: https://my.home-assistant.io/redirect/supervisor_addon/?addon=a4a84f10_frpc

## 🚀 安装

### 方式一：一键添加

点击下面的按钮将此仓库添加到 Home Assistant：

[![Add Repository to Home Assistant][add-repo-badge]][add-repo]

[add-repo-badge]: https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg
[add-repo]: https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2Flinknlink%2Faddons

### 方式二：手动添加

1. 打开 Home Assistant
2. 导航到 **设置** → **加载项** → **加载项商店**
3. 点击右上角菜单图标 (⋮) → **仓库**
4. 添加仓库 URL: `https://github.com/linknlink/addons`
5. 点击 **添加**

### 安装 Add-on

添加仓库后，在商店中找到所需的 addon 并点击 **安装**。

## 📚 文档

- [设计文档](docs/DESIGN.md) - 仓库框架设计说明
- [Addon 开发指南](docs/ADDON_GUIDE.md) - 如何开发和添加新的 addon
- [贡献指南](docs/CONTRIBUTING.md) - 如何参与贡献

## 🛠️ 开发

### 添加新 Addon

```bash
./scripts/add-addon.sh <addon-name>
```

### 构建 Addon

```bash
./scripts/build-addon.sh <addon-name>
```

### 发布 Addon

```bash
./scripts/release-addon.sh <addon-name> patch
```

更多信息请参考 [设计文档](docs/DESIGN.md)。

## 📝 许可证

本项目采用 MIT 许可证。

## 🤝 贡献

欢迎贡献！请查看 [贡献指南](docs/CONTRIBUTING.md) 了解详细信息。

## 📞 支持

如有问题或建议：

- 通过 [GitHub Issues](https://github.com/linknlink/addons/issues) 提交反馈
- 查看各 addon 的文档和更新日志

---

**注意：** 这些 addon 需要 LinknLink IoT 平台才能正常工作。
