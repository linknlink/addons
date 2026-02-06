# Docker 容器应用开发指南

本指南介绍如何在这个仓库中开发和添加新的 Docker 容器应用。这些容器应用旨在为 Ubuntu Server 系统（特别是鲁班猫设备）提供相关能力。

## 目录

1. [快速开始](#快速开始)
2. [Addon 结构](#addon-结构)
3. [开发流程](#开发流程)
4. [配置说明](#配置说明)
5. [构建和测试](#构建和测试)
6. [发布流程](#发布流程)

## 快速开始

### 创建新 Addon

使用脚本快速创建新的 addon：

```bash
./scripts/add-addon.sh my-new-addon
```

这将创建一个标准的 addon 目录结构，包含所有必需的文件。

### 验证 Addon 结构

创建后，验证 addon 是否符合规范：

```bash
./scripts/validate-addon.sh my-new-addon
```

## Addon 结构

每个 addon 必须包含以下文件和目录：

```
addon-name/
├── VERSION             # 版本号文件（必需）
├── repository.json     # Addon 元数据（可选，用于指定架构）
├── README.md           # 说明文档（推荐）
├── CHANGELOG.md        # 更新日志（推荐）
├── common/             # 通用文件目录（必需）
│   ├── Dockerfile      # Docker 构建文件（必需）
│   └── rootfs/         # 根文件系统（必需）
│       └── app/        # 应用代码
│           └── docker-entrypoint.sh  # 启动脚本
├── docker-compose.yml  # Docker Compose 配置（开发用，可选）
├── requirements.txt    # Python 依赖（如适用）
└── scripts/            # Addon 特定脚本（可选）
```

### repository.json（可选）

可选的元数据文件，主要用于指定支持的架构。如果不提供，构建时会使用默认架构（amd64, aarch64, armv7）。

```json
{
  "name": "My Container",
  "url": "https://github.com/linknlink/addons",
  "maintainer": "linknlink <https://github.com/linknlink>",
  "description": "Docker container description",
  "arch": ["aarch64", "amd64", "armv7"]
}
```

**注意**：可以通过 `--arch` 参数在构建时指定架构，所以此文件不是必需的。
```

### VERSION

版本号文件，使用语义化版本格式（SemVer）：

```
1.0.0
```

### Dockerfile

Docker 镜像构建文件，必须支持多架构：

```dockerfile
ARG BUILD_FROM=alpine:latest
FROM ${BUILD_FROM}

ENV LANG C.UTF-8

# 安装依赖
RUN apk add --no-cache \
    bash \
    curl

# 复制应用文件
COPY rootfs /

# 设置工作目录
WORKDIR /app

# 运行脚本
ENTRYPOINT [ "/bin/bash", "/app/docker-entrypoint.sh" ]
```

### docker-entrypoint.sh

容器启动脚本，应该：

- 使用 `set -e` 确保错误时退出
- 处理必要的初始化
- 启动主应用

示例：

```bash
#!/bin/bash
set -e

echo "Starting my-addon..."

# 初始化逻辑
# ...

# 启动应用
exec "$@"
```

## 开发流程

### 1. 创建 Addon

```bash
./scripts/add-addon.sh my-addon
```

### 2. 开发代码

编辑 addon 目录下的文件：

- 修改 `common/rootfs/app/` 下的应用代码
- 更新 `common/Dockerfile` 添加依赖
- 编写或更新 `README.md` 文档

### 3. 本地测试

使用 Docker Compose 进行本地测试：

```bash
cd addons/my-addon
docker-compose up --build
```

### 4. 验证结构

```bash
./scripts/validate-addon.sh my-addon
```

### 5. 构建测试

```bash
./scripts/build-addon.sh my-addon --arch amd64
```

### 6. 提交代码

```bash
git add addons/my-addon/
git commit -m "feat: 添加 my-addon"
git push
```

## 配置说明

### 环境变量

在 `docker-compose.yml` 中定义环境变量用于开发：

```yaml
services:
  my-addon:
    environment:
      - MY_VAR=value
```

### 配置文件

如果 addon 需要配置文件，可以：

1. 使用环境变量（推荐）
2. 在 `rootfs/` 中放置默认配置
3. 在启动脚本中生成配置

### 持久化数据

如果需要持久化数据，使用 Docker volume：

```yaml
services:
  my-addon:
    volumes:
      - ./data:/data
```

## 构建和测试

### 构建单个架构

```bash
./scripts/build-addon.sh my-addon --arch amd64
```

### 构建所有架构

```bash
./scripts/build-addon.sh my-addon
```

### 构建并推送

```bash
./scripts/build-addon.sh my-addon --push
```

## 发布流程

### 1. 更新版本号

使用发布脚本自动更新版本：

```bash
./scripts/release-addon.sh my-addon patch
```

版本类型：
- `patch`: 补丁版本 (1.0.0 -> 1.0.1)
- `minor`: 次版本 (1.0.0 -> 1.1.0)
- `major`: 主版本 (1.0.0 -> 2.0.0)

### 2. 更新 CHANGELOG.md

在发布前，更新 `CHANGELOG.md` 记录变更：

```markdown
## [1.0.1] - 2024-01-01

### Fixed
- 修复了某个 bug

### Changed
- 改进了某个功能
```

### 3. 提交和推送

```bash
./scripts/release-addon.sh my-addon patch --commit --push
```

这将：
1. 更新版本号
2. 构建 Docker 镜像
3. 提交更改
4. 创建 Git tag
5. 推送到远程仓库

### 4. CI/CD 自动发布

推送 tag 后，GitHub Actions 会自动：
1. 构建多架构镜像
2. 推送到 GitHub Container Registry
3. 创建 GitHub Release

## 最佳实践

### 代码组织

- 保持代码模块化
- 使用清晰的函数和类命名
- 添加必要的注释

### 错误处理

- 使用 `set -e` 在脚本中
- 提供有意义的错误消息
- 记录错误日志

### 文档

- 编写清晰的 README.md
- 记录所有配置选项
- 提供使用示例
- 维护 CHANGELOG.md

### 测试

- 在本地充分测试
- 测试不同架构（如可能）
- 验证配置选项

### 安全性

- 不要硬编码敏感信息
- 使用环境变量存储配置
- 定期更新依赖

## 常见问题

### Q: 如何添加 Python 依赖？

A: 在 `Dockerfile` 中安装：

```dockerfile
RUN apk add --no-cache python3 py3-pip
RUN pip3 install --break-system-packages flask requests
```

或使用 `requirements.txt`：

```dockerfile
COPY requirements.txt /tmp/
RUN pip3 install --break-system-packages -r /tmp/requirements.txt
```

### Q: 如何支持多架构？

A: Dockerfile 应该使用通用的基础镜像和命令。构建脚本会自动处理多架构构建。

### Q: 如何调试 addon？

A: 使用 Docker Compose 进行本地开发，添加必要的调试工具和日志输出。

### Q: 版本号冲突怎么办？

A: 发布脚本会检查 tag 是否已存在。如果冲突，使用不同的版本号。

## 参考资源

- [Docker 官方文档](https://docs.docker.com/)
- [Docker 多架构构建](https://docs.docker.com/build/building/multi-platform/)
- [Docker Compose 文档](https://docs.docker.com/compose/)
- [语义化版本](https://semver.org/)
