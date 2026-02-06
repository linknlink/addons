# Addon 模板说明

本文档说明如何使用此模板创建新的 Haddons Addon。

## 目录结构

```
addon-template/
├── README.md              # Addon 概述说明模板
├── config.json            # Haddons Addon 配置文件模板
├── docker-compose.yml     # Docker Compose 配置模板
├── VERSION                # 版本号文件
├── common/                # 通用文件目录
│   ├── Dockerfile        # Docker 构建文件模板
│   └── rootfs/           # 根文件系统
│       └── app/          # 应用代码目录
│           └── docker-entrypoint.sh  # 启动脚本模板
├── template/              # Template 生成参考文件（用于生成 haddons template）
│   ├── DOCS.md           # 使用说明文档模板（Haddons 文档标签页）
│   ├── upload_config.json # 上传配置文件模板
│   ├── .tarignore        # 打包排除文件列表模板
│   └── HADDONS_DESCRIPTION.md  # Haddons 服务说明（参考文档）
├── ICON_REQUIREMENTS.md  # 图标要求说明
└── TEMPLATE.md           # 本文档
```

## 关于 Haddons

本模板专为 **Haddons** 服务设计。Haddons 是一个参照 Home Assistant Add-on 管理实现的一套 Addon 管理系统，允许用户通过 Web 界面浏览、安装、配置、监控和管理基于 Docker Compose 的应用程序。

## Addon 文件说明（addon-template/）

### README.md
- **用途**: Addon 概述说明（在 Haddons 界面中作为 Addon 卡片简介）
- **内容**: 简要描述 Addon 的能力和主要功能
- **注意**: 不要包含详细的 Haddons 说明，只描述 Addon 本身

### config.json（必需）
- **用途**: Haddons 服务必需的配置文件
- **内容**: Addon 元数据、配置选项和 Schema
- **注意**: 必须存在且格式正确，否则 Haddons 服务无法识别

### docker-compose.yml（必需）
- **用途**: Haddons 服务必需的 Docker Compose 配置
- **内容**: 容器编排配置，包括镜像、环境变量、挂载卷等
- **注意**: 在 addon 中可以使用 `build:`，但在生成 template 时必须改为 `image:`

### common/Dockerfile（必需）
- **用途**: Docker 构建文件
- **内容**: 定义容器构建步骤

### common/rootfs/（必需）
- **用途**: 根文件系统目录
- **内容**: 应用代码和配置文件

## Template 文件说明（addon-template/template/）

`template/` 目录包含用于生成 haddons template 的参考文件。这些文件不会被复制到 addon 中，而是作为生成 template 时的参考。

### template/DOCS.md
- **用途**: Addon 使用说明模板（在 Haddons 界面的"文档"标签页显示）
- **内容**: 详细的使用方法、配置说明、注意事项等
- **注意**: 生成 template 时，脚本会从 addon 的 README.md 生成 DOCS.md，此文件作为参考

### template/upload_config.json
- **用途**: 上传配置文件模板
- **内容**: Haddons 上传所需的配置信息

### template/.tarignore
- **用途**: 打包排除文件列表模板
- **内容**: 指定打包时排除的文件

### template/HADDONS_DESCRIPTION.md
- **用途**: Haddons 服务说明文档（仅作参考）
- **内容**: 详细说明 Haddons 的使用方法和配置

## 使用模板创建 Addon

### 方法一：使用脚本（推荐）

```bash
./scripts/add-addon.sh <addon-name>
```

脚本会自动：
1. 从模板复制文件到 `addons/<addon-name>/`
2. 替换所有 `{{ADDON_NAME}}` 和 `{{ADDON_SLUG}}` 占位符
3. 创建基本配置文件

### 方法二：手动创建

1. 复制 `templates/addon-template/` 目录到 `addons/<addon-name>/`（不包括 `template/` 目录）
2. 替换所有 `{{ADDON_NAME}}` 和 `{{ADDON_SLUG}}` 占位符
3. 根据实际需求修改 `config.json` 和 `docker-compose.yml`
4. 编写 `README.md`（参考模板）
5. 创建 `icon.png` 图标文件（参考 `ICON_REQUIREMENTS.md`）

## 生成 Template

创建 addon 后，使用脚本生成上传用的 template：

```bash
./scripts/generate-template-from-addon.sh <addon-name>
```

脚本会：
1. 从 addon 读取信息
2. 生成 `addon_templates/<addon-name>/` 目录
3. 从 README.md 生成 DOCS.md
4. 创建 upload_config.json 和其他必需文件

## 模板变量

- `{{ADDON_NAME}}`: Addon 名称（如：Network Manager）
- `{{ADDON_SLUG}}`: Addon slug（如：network_manager，使用下划线）

## 注意事项

- `addon-template/` 目录中的文件用于创建 addon
- `addon-template/template/` 目录中的文件仅作为生成 haddons template 的参考
- Addon 的 README.md 应该专注于 Addon 本身的功能和使用方法
- 生成 template 时，DOCS.md 会从 README.md 自动生成
- 如果需要在文档中提及 Haddons，应该简洁说明，不要详细展开
