# {{ADDON_NAME}}

{{ADDON_NAME}} 是一个 Haddons Addon，旨在为 Ubuntu Server 系统提供相关能力。

## 概述

简要描述 Addon 的主要用途、技术实现和设计目标。此文档面向开发者，用于了解 Addon 的功能和实现方式。

## 主要功能

- **功能特性 1**：详细描述功能特性及其实现方式
- **功能特性 2**：详细描述功能特性及其实现方式
- **功能特性 3**：详细描述功能特性及其实现方式

## 技术架构

### 核心技术栈

- 基础镜像：Alpine Linux（或其他）
- 主要依赖：列出主要依赖和工具
- 运行环境：描述运行环境要求

### 目录结构

```
{{ADDON_SLUG}}/
├── config.json              # Haddons Addon 配置文件
├── docker-compose.yml       # Docker Compose 配置
├── VERSION                  # 版本号
├── common/                  # 通用文件目录
│   ├── Dockerfile          # Docker 构建文件
│   └── rootfs/             # 根文件系统
│       └── app/            # 应用代码
│           └── docker-entrypoint.sh  # 启动脚本
└── README.md               # 本文档
```

## 开发指南

### 本地开发

1. 克隆仓库并进入 addon 目录
2. 修改 `common/rootfs/app/` 下的应用代码
3. 使用 Docker Compose 进行本地测试：

```bash
cd addons/{{ADDON_SLUG}}
docker-compose up --build
```

### 构建和测试

```bash
# 验证 addon 结构
./scripts/validate-addon.sh {{ADDON_SLUG}}

# 构建 addon
./scripts/build-addon.sh {{ADDON_SLUG}}

# 发布 addon
./scripts/release-addon.sh {{ADDON_SLUG}} patch --commit --push
```

## 配置说明

### config.json

`config.json` 是 Haddons 服务必需的配置文件，定义了 Addon 的元数据、配置选项和 Schema。

主要配置项：
- `name`: Addon 显示名称
- `version`: Addon 版本号
- `slug`: Addon 唯一标识符
- `description`: Addon 描述信息
- `options`: 配置选项的默认值
- `schema`: 配置选项的 Schema 定义

### docker-compose.yml

`docker-compose.yml` 定义了容器的编排配置。开发时可以使用 `build:`，但在生成 template 时必须改为 `image:`。

## 用户文档

- **用户使用说明**：生成 template 后，用户可以在 Haddons Web 界面的"文档"标签页查看详细的使用说明（DOCS.md）
- **核心能力说明**：生成 template 后，用户可以在 Haddons Web 界面的 Addon 卡片中查看核心能力说明（template/README.md）

## 许可证

MIT
