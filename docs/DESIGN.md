# Docker 容器应用管理仓库框架设计文档

## 1. 概述

本文档描述了一个用于管理多个 Docker 容器应用的仓库框架设计。该框架支持统一管理、构建和发布多个容器应用，同时保持每个容器应用的独立性和可维护性。这些容器应用旨在为 Ubuntu Server 系统提供相关能力。

## 2. 设计目标

- **统一管理**: 在一个仓库中管理多个 Docker 容器应用
- **标准化结构**: 每个容器应用遵循统一的结构和规范
- **自动化构建**: 支持 CI/CD 自动化构建和发布
- **易于扩展**: 方便添加新的容器应用
- **版本管理**: 每个容器应用独立版本管理
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
│   ├── linknlink-remote/       # 示例 addon
│   │   ├── repository.json     # Addon 元数据（可选）
│   │   ├── config.json         # Addon 配置（可选）
│   │   ├── VERSION             # Addon 版本号
│   │   ├── README.md           # Addon 说明文档
│   │   ├── CHANGELOG.md        # 更新日志
│   │   ├── common/             # 通用文件目录
│   │   │   ├── Dockerfile      # Docker 构建文件
│   │   │   └── rootfs/         # 根文件系统
│   │   │       └── app/        # 应用代码
│   │   ├── docker-compose.yml  # Docker Compose 配置（开发用）
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

#### 4.2.1 repository.json（可选）

可选的元数据文件，主要用于指定支持的架构。如果不提供，构建时会使用默认架构（amd64, aarch64, armv7）或通过 `--arch` 参数指定。

```json
{
  "name": "LinknLink Remote",
  "url": "https://github.com/linknlink/addons",
  "maintainer": "linknlink <https://github.com/linknlink>",
  "description": "Docker container for remote access through the LinknLink platform",
  "arch": ["aarch64", "amd64", "armv7"]
}
```

**注意**：此文件不是必需的，可以通过 `--arch` 参数在构建时指定架构。

#### 4.2.2 config.json

Addon 的配置模板文件（可选），定义配置项和默认值：

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

#### 4.2.3 common/ 目录

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
