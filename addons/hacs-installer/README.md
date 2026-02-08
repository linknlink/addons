# HACS Installer

HACS Installer 是一个用于简化 HACS (Home Assistant Community Store) 安装过程的工具。

## 功能

- 检测当前 Home Assistant 实例是否安装了 HACS
- 一键下载并安装最新版本的 HACS 到 Home Assistant 的 `custom_components` 目录
- 支持一键卸载 HACS
- 支持从 GitHub 官方源下载

## 使用说明

1. 在 Haddons 界面配置 Home Assistant 的配置目录路径（默认为 `/usr/share/hassio/homeassistant`）。
2. 启动本 Addon。
3. 点击 Web 界面中的"安装"按钮。
4. 安装完成后，重启 Home Assistant。
5. 在 Home Assistant 的集成页面搜索并添加 "HACS"。

## 注意事项

- **必须**正确配置 Home Assistant 的配置目录挂载路径，否则无法安装。
- 安装过程需要从 GitHub 下载文件，请确保网络连接正常。
