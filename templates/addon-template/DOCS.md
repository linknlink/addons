# {{ADDON_NAME}} 使用说明

本文档详细介绍如何使用 {{ADDON_NAME}} Addon。

## 关于 Haddons

本 Addon 专为 **Haddons** 服务设计。Haddons 是一个参照 Home Assistant Add-on 管理实现的一套 Addon 管理系统，允许用户通过 Web 界面浏览、安装、配置、监控和管理基于 Docker Compose 的应用程序。

## 快速开始

### 使用 Haddons 服务

1. 确保 Haddons 服务正在运行
2. 将本 Addon 目录复制到 Haddons 的 `addons/` 目录
3. 在 Haddons Web 界面中刷新 Addon 列表
4. 点击"安装"按钮安装 Addon
5. 配置 Addon 选项（如需要）
6. 启动 Addon

### 使用 Docker Compose（开发/测试）

1. 编辑 `docker-compose.yml`，配置必要的环境变量和挂载卷
2. 启动容器：

```bash
docker-compose up -d
```

### 使用 Docker 命令

```bash
docker run -d \
  --name {{ADDON_SLUG}} \
  --restart unless-stopped \
  <镜像名称>:<版本>
```

## 配置说明

请根据实际需求修改 `config.json` 中的配置项和 `docker-compose.yml` 中的环境变量。

### config.json 配置

`config.json` 是 Haddons 服务必需的配置文件，定义了 Addon 的元数据、配置选项和 Schema。

### docker-compose.yml 配置

`docker-compose.yml` 定义了容器的编排配置，包括镜像、环境变量、挂载卷等。

## 注意事项

- 确保容器有足够的权限访问所需资源
- 检查端口映射是否正确
- 验证挂载卷路径是否存在
- 确保 `config.json` 格式正确，否则 Haddons 服务无法识别

## 许可证

MIT
