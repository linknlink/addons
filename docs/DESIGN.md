# Haddons Addon 管理仓库框架设计文档

## 1. 概述

本文档描述了一个用于管理多个 **Haddons Addon** 的仓库框架设计。该框架支持统一管理、构建和发布多个 Addon，同时保持每个 Addon 的独立性和可维护性。

### 1.1 关于 Haddons

**Haddons** 是一个参照 Home Assistant Add-on 管理实现的一套 Addon 管理系统，允许用户通过 Web 界面浏览、安装、配置、监控和管理基于 Docker Compose 的应用程序。

本仓库中的 Addon 遵循 Haddons 的配置规范，可以直接部署到 Haddons 服务中使用。Haddons 服务会扫描 `addons/` 目录下的每个子目录，读取 `config.json` 文件获取 Addon 元数据，并使用 `docker-compose.yml` 管理容器的生命周期。

### 1.2 项目定位

- **目标服务**：Haddons（而非 Home Assistant）
- **Addon 格式**：遵循 Haddons 配置规范（类似 HA Add-on，但独立实现）
- **部署方式**：通过 Haddons 服务管理，支持 Web 界面操作
- **系统环境**：主要针对 Ubuntu Server 系统（特别是鲁班猫设备）优化

## 2. 设计目标

- **统一管理**: 在一个仓库中管理多个 Haddons Addon
- **标准化结构**: 每个 Addon 遵循 Haddons 配置规范和统一的结构
- **Haddons 兼容**: 完全兼容 Haddons 服务的配置格式和管理方式
- **自动化构建**: 支持 CI/CD 自动化构建和发布 Docker 镜像
- **易于扩展**: 方便添加新的 Addon
- **版本管理**: 每个 Addon 独立版本管理
- **文档完善**: 提供清晰的文档和使用指南
- **Ubuntu Server 优化**: 针对 Ubuntu Server 系统（特别是鲁班猫设备）优化

## 3. 仓库结构

```
addons/
├── .github/
│   └── workflows/
│       ├── ci.yml              # CI 工作流（测试、构建）
│       └── release.yml         # 发布工作流
├── addons/                     # Addon 目录
│   ├── network-manager/        # 示例 addon
│   │   ├── config.json         # Haddons Addon 元数据配置（必需，用于 Haddons 服务）
│   │   ├── repository.json     # 仓库元数据（可选，用于构建时指定架构）
│   │   ├── VERSION             # Addon 版本号
│   │   ├── README.md           # Addon 说明文档
│   │   ├── CHANGELOG.md        # 更新日志
│   │   ├── common/             # 通用文件目录
│   │   │   ├── Dockerfile      # Docker 构建文件
│   │   │   └── rootfs/         # 根文件系统
│   │   │       └── app/        # 应用代码
│   │   ├── docker-compose.yml  # Docker Compose 配置（Haddons 服务使用）
│   │   ├── requirements.txt    # Python 依赖（如适用）
│   │   └── scripts/            # Addon 特定脚本
│   │       └── build.sh        # 构建脚本
│   └── [其他 addon]/           # 其他 addon...
├── scripts/                    # 仓库管理脚本
│   ├── add-addon.sh           # 添加新 addon
│   ├── build-addon.sh         # 构建指定 addon
│   ├── release-addon.sh       # 发布指定 addon
│   └── validate-addon.sh      # 验证 addon 结构
├── templates/                  # Addon 模板
│   └── addon-template/        # 标准 addon 模板
├── docs/                       # 文档目录
│   ├── DESIGN.md              # 本文档
│   ├── ADDON_GUIDE.md         # Addon 开发指南
│   └── CONTRIBUTING.md        # 贡献指南
├── repository.json             # 仓库根配置
├── README.md                   # 仓库主文档
└── .gitignore                  # Git 忽略文件
```

## 4. 核心组件说明

### 4.1 根 repository.json

仓库的根配置文件，定义仓库的基本信息：

```json
{
  "name": "LinknLink Docker Containers",
  "url": "https://github.com/linknlink/addons",
  "maintainer": "linknlink <https://github.com/linknlink>",
  "description": "Docker container applications collection for Ubuntu Server"
}
```

### 4.2 Addon 目录结构

每个 addon 位于 `addons/` 目录下，包含以下核心文件：

#### 4.2.1 config.json（必需，用于 Haddons 服务）

**这是 Haddons 服务必需的配置文件**，定义了 Addon 的元数据、配置选项和 Schema。Haddons 服务会读取此文件来识别和管理 Addon。

```json
{
  "name": "Network Manager",
  "version": "0.0.3",
  "slug": "network_manager",
  "description": "为 Ubuntu Server 系统提供 WiFi 网络管理功能的 Docker 容器应用",
  "arch": ["aarch64", "amd64", "armv7"],
  "startup": "services",
  "boot": "auto",
  "options": {
    "wifi_scan_interval": 30,
    "auto_reconnect": true,
    "default_ip_method": "dhcp",
    "log_level": "info"
  },
  "schema": {
    "wifi_scan_interval": "int",
    "auto_reconnect": "bool",
    "default_ip_method": "str",
    "log_level": "str"
  },
  "ingress": false,
  "ingress_port": 0
}
```

**字段说明**：
- `name`: Addon 显示名称
- `version`: Addon 版本号（应与 VERSION 文件一致）
- `slug`: Addon 唯一标识符（用于目录名和 URL）
- `description`: Addon 描述信息
- `arch`: 支持的架构列表
- `startup`: 启动类型（`application`/`system`/`services`）
- `boot`: 启动方式（`auto`/`manual`）
- `options`: 配置选项的默认值
- `schema`: 配置选项的 Schema 定义（用于前端表单生成）
- `ingress`: 是否支持 Web UI 嵌入（可选）
- `ingress_port`: 容器内部 Web 端口（可选）

**注意**：此文件是 Haddons 服务识别和管理 Addon 的关键文件，必须存在且格式正确。

#### 4.2.2 repository.json（可选，用于构建）

可选的元数据文件，主要用于指定支持的架构。如果不提供，构建时会使用默认架构（amd64, aarch64, armv7）或通过 `--arch` 参数指定。

```json
{
  "name": "Network Manager",
  "url": "https://github.com/linknlink/addons",
  "maintainer": "linknlink <https://github.com/linknlink>",
  "description": "Docker container for WiFi network management",
  "arch": ["aarch64", "amd64", "armv7"]
}
```

**注意**：此文件主要用于构建时指定架构，可以通过 `--arch` 参数在构建时指定架构，所以此文件不是必需的。但建议保留，以便与 `config.json` 保持一致。

```json
{
  "name": "LinknLink Remote",
  "version": "1.0.0",
  "slug": "linknlink_remote",
  "description": "Remote access solution",
  "arch": ["aarch64", "amd64", "armv7"],
  "startup": "services",
  "boot": "auto",
  "options": {
    "email": "",
    "password": ""
  },
  "schema": {
    "email": "str",
    "password": "str"
  }
}
```

#### 4.2.3 docker-compose.yml（必需，用于 Haddons 服务）

**这是 Haddons 服务必需的配置文件**，定义了容器的编排配置。Haddons 服务使用此文件来启动、停止和管理容器。

```yaml
services:
  network_manager:
    image: ghcr.io/linknlink/network_manager:0.0.3
    container_name: network_manager
    restart: unless-stopped
    network_mode: host
    privileged: true
    environment:
      - WIFI_SCAN_INTERVAL=30
      - AUTO_RECONNECT=true
```

**要求**：
- 使用 Docker Compose v3 格式
- 容器名称建议使用 Addon slug
- 建议设置 `restart: unless-stopped` 或 `restart: always`
- 镜像名称格式：`ghcr.io/linknlink/<slug>:<version>`

#### 4.2.4 common/ 目录

包含 Dockerfile 和应用代码：

- `Dockerfile`: 容器镜像构建文件
- `rootfs/`: 根文件系统，包含应用的所有文件
  - `app/`: 应用核心代码
  - `docker-entrypoint.sh`: 容器启动脚本

### 4.3 管理脚本

#### 4.3.1 add-addon.sh

用于添加新的 addon 到仓库：

```bash
./scripts/add-addon.sh <addon-name> [--from-template]
```

功能：
- 创建新的 addon 目录结构
- 从模板初始化文件
- 验证结构完整性

#### 4.3.2 build-addon.sh

构建指定的 addon：

```bash
./scripts/build-addon.sh <addon-name> [--arch <arch>]
```

功能：
- 读取 addon 的 VERSION 文件
- 构建 Docker 镜像
- 支持多架构构建

#### 4.3.3 release-addon.sh

发布指定的 addon：

```bash
./scripts/release-addon.sh <addon-name> [patch|minor|major]
```

功能：
- 更新版本号
- 构建并推送镜像
- 创建 Git tag
- 触发 CI/CD

#### 4.3.4 validate-addon.sh

验证 addon 结构是否符合规范：

```bash
./scripts/validate-addon.sh <addon-name>
```

功能：
- 检查必需文件是否存在
- 验证 JSON 格式
- 检查 Dockerfile 语法

## 5. CI/CD 工作流

### 5.1 CI 工作流 (ci.yml)

触发条件：
- Pull Request
- Push 到主分支

执行步骤：
1. 检测变更的 addon
2. 验证 addon 结构
3. 构建 Docker 镜像（测试）
4. 运行测试（如适用）

### 5.2 Release 工作流 (release.yml)

触发条件：
- 创建 Git tag (格式: `<addon-name>-v<version>`)

执行步骤：
1. 解析 tag 获取 addon 名称和版本
2. 构建多架构 Docker 镜像
3. 推送到容器仓库
4. 创建 GitHub Release

## 6. 版本管理策略

### 6.1 版本号格式

遵循语义化版本（SemVer）：
- 格式: `MAJOR.MINOR.PATCH`
- 示例: `1.0.0`, `1.0.1`, `1.1.0`, `2.0.0`

### 6.2 版本存储

每个 addon 在根目录维护 `VERSION` 文件：
```
addons/linknlink-remote/VERSION
```

### 6.3 Git Tag 格式

使用格式: `<addon-slug>-v<version>`

示例：
- `linknlink-remote-v1.0.0`
- `linknlink-remote-v1.0.1`

## 7. Docker 镜像命名规范

### 7.1 镜像命名

格式: `ghcr.io/linknlink/<addon-slug>:<version>`

示例：
- `ghcr.io/linknlink/linknlink-remote:1.0.0`
- `ghcr.io/linknlink/linknlink-remote:latest`

### 7.2 多架构支持

支持以下架构：
- `amd64` (x86_64)
- `aarch64` (ARM 64-bit)
- `armv7` (ARM 32-bit)

## 8. 开发工作流

### 8.1 添加新 Addon

1. 运行 `./scripts/add-addon.sh <addon-name>`
2. 编辑 addon 的文件和配置
3. 测试构建: `./scripts/build-addon.sh <addon-name>`
4. 提交代码并创建 PR

### 8.2 更新现有 Addon

1. 修改 addon 代码
2. 更新 `CHANGELOG.md`
3. 运行 `./scripts/release-addon.sh <addon-name> patch`
4. 脚本会自动：
   - 更新版本号
   - 构建镜像
   - 创建 tag
   - 触发发布

### 8.3 本地开发

1. 进入 addon 目录
2. 使用 `docker-compose.yml` 进行本地测试
3. 修改代码后重新构建测试

## 9. 最佳实践

### 9.1 容器应用开发

- 遵循 Docker 容器最佳实践
- 保持代码模块化和可维护性
- 提供清晰的文档和示例
- 编写测试用例（如适用）
- 针对 Ubuntu Server 系统优化

### 9.2 版本管理

- 重大变更递增主版本号
- 新功能递增次版本号
- 修复和补丁递增补丁版本号
- 每次发布更新 CHANGELOG.md

### 9.3 文档

- 每个 addon 提供 README.md
- 记录配置选项和使用方法
- 提供故障排除指南
- 维护更新日志

## 10. 扩展性考虑

### 10.1 支持多种语言

框架设计支持：
- Python addon
- Node.js addon
- Go addon
- Shell 脚本 addon

### 10.2 插件系统

未来可扩展：
- 自定义构建步骤
- 预发布钩子
- 后发布钩子
- 通知集成

## 11. 安全考虑

- 使用 GitHub Actions 的安全最佳实践
- 敏感信息使用 Secrets
- 镜像签名和验证
- 依赖扫描和更新

## 12. 未来改进

- [ ] 自动化依赖更新
- [ ] 集成测试框架
- [ ] 性能基准测试
- [ ] 多仓库支持
- [ ] Web UI 管理界面
