# Haddons 服务说明

## 关于 Haddons

**Haddons** 是一个参照 Home Assistant Add-on 管理实现的一套 Addon 管理系统，允许用户通过 Web 界面浏览、安装、配置、监控和管理基于 Docker Compose 的应用程序。

## Haddons 使用说明

### 使用 Haddons 服务安装 Addon

1. 确保 Haddons 服务正在运行
2. 将本 Addon 目录复制到 Haddons 的 `addons/` 目录
3. 在 Haddons Web 界面中刷新 Addon 列表
4. 点击"安装"按钮安装 Addon
5. 在"配置"标签页中配置 Addon 选项（如需要）
6. 点击"保存"保存配置
7. 点击"启动"按钮启动 Addon

### Haddons 配置说明

#### config.json 配置

`config.json` 是 Haddons 服务必需的配置文件，定义了 Addon 的元数据、配置选项和 Schema。

Haddons 服务会读取此文件来识别和管理 Addon。

#### docker-compose.yml 配置

`docker-compose.yml` 定义了容器的编排配置，包括镜像、环境变量、挂载卷等。

**重要**：Template 中的 `docker-compose.yml` 必须使用已发布的镜像（`image:`），不要使用 `build:`。

#### 环境变量映射

Haddons 服务会将 `config.json` 中的配置项映射为环境变量：
- `config.json` 中的配置项名称（小写，下划线分隔）
- 映射为环境变量（大写，下划线分隔）

例如：
- `wifi_scan_interval` → `WIFI_SCAN_INTERVAL`
- `auto_reconnect` → `AUTO_RECONNECT`

### Haddons 界面说明

- **信息标签页**: 显示 Addon 基本信息、状态、操作按钮
- **文档标签页**: 显示 `DOCS.md` 的内容
- **配置标签页**: 根据 `config.json` 的 `schema` 动态生成配置表单
- **日志标签页**: 显示容器运行日志

## 注意事项

- 确保 `config.json` 格式正确，否则 Haddons 服务无法识别
- `docker-compose.yml` 必须使用已发布的镜像，不能使用 `build:`
- Template 中不包含 `common/` 目录，因为使用的是已构建的镜像
