# HACS Installer 使用说明

## 简介
HACS Installer 是一个辅助工具，用于帮助您快速将 HACS (Home Assistant Community Store) 安装到您的 Home Assistant 实例中。

## 安装步骤

1. **配置路径**：在安装本 Addon之前，请务必确认您的 Home Assistant 配置路径。默认路径为 `/usr/share/hassio/homeassistant`。如果您的 Home Assistant 安装在不同位置，请在配置中修改 `HA_CONFIG_PATH`。
2. **启动服务**：安装并启动 HACS Installer。
3. **访问界面**：点击"访问服务"或直接访问 `http://<您的IP>:8099`。

## 操作指南

1. **检查状态**：打开 Web 界面后，工具会自动检查是否已安装 HACS。
2. **开始安装**：如果未安装，点击"开始安装"按钮。
   - 工具会自动从 GitHub 下载最新版本的 HACS。
   - 解压并安装到 `custom_components/hacs` 目录。
3. **完成安装**：安装完成后，界面会提示成功。

## 后续步骤

安装完成后，您需要：
1. **重启 Home Assistant**：必须重启才能使 HACS 生效。
2. **添加集成**：
   - 进入 Home Assistant -> 配置 -> 设备与服务 -> 添加集成。
   - 搜索 "HACS"。
   - 按照提示完成 GitHub 授权。

## 常见问题

**Q: 安装失败怎么办？**
A: 请检查：
- Home Assistant 配置路径是否正确挂载。
- 网络是否正常（需要访问 GitHub）。

**Q: 安装后找不到 HACS 集成？**
A: 请确保已重启 Home Assistant，并清除浏览器缓存。
