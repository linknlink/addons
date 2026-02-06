# Addon Template 生成规则文档

本文档说明如何从现有 addon 生成用于上传的 template，以及相关的生成规则。

## 概述

Addon template 是用于上传到服务器的模板文件，包含上传配置、Docker Compose 配置和 addon 文件结构。本仓库提供了自动化脚本，可以从开发用的 addon 结构自动生成上传用的 template。

## 目录结构

### 开发用 Addon 结构（`addons/`）

```
addons/
└── <addon-name>/
    ├── VERSION                    # 版本号
    ├── repository.json           # Addon 元数据（可选）
    ├── README.md                 # 说明文档
    ├── docker-compose.yml        # Docker Compose 配置
    ├── common/                   # 通用文件目录
    │   ├── Dockerfile           # Docker 构建文件
    │   └── rootfs/              # 根文件系统
    │       └── app/             # 应用代码
    └── scripts/                 # Addon 特定脚本（可选）
```

### 上传用 Template 结构（`addon_templates/`）

```
addon_templates/
└── <addon-name>/
    ├── upload_config.json        # 上传配置文件（必需）
    ├── docker-compose.yml       # Docker Compose 配置
    ├── .tarignore              # 打包排除文件列表
    ├── README.md               # 说明文档
    ├── icon.png                # 图标文件（可选）
    ├── common/                 # Addon 文件目录
    │   ├── Dockerfile
    │   └── rootfs/
    └── TEMPLATE_INFO.md        # Template 生成信息
```

## 生成规则

### 1. upload_config.json 生成规则

从 addon 的 `repository.json` 和 `VERSION` 文件提取信息：

- `name`: 从 `repository.json` 的 `name` 字段获取，如果没有则使用 addon 名称（首字母大写）
- `addonid`: 默认为 `"0"`
- `addondescription`: 从 `repository.json` 的 `description` 字段获取
- `version`: 从 `VERSION` 文件读取
- `id`: 使用 addon 名称（小写，连字符分隔）
- `display_name`: 使用 addon 名称（小写，连字符分隔）
- 其他字段使用默认值

### 2. 文件复制规则

从 addon 目录复制以下内容到 template 目录：

**必需文件/目录：**
- `common/` - 整个目录（包含 Dockerfile 和 rootfs）

**可选文件/目录：**
- `docker-compose.yml` - 如果存在则复制
- `README.md` - 如果存在则复制
- `CHANGELOG.md` - 如果存在则复制
- `requirements.txt` - 如果存在则复制
- `repository.json` - 如果存在则复制
- `scripts/` - 如果存在则复制整个目录
- `docs/` - 如果存在则复制整个目录
- `icon.png` - 如果存在则复制

### 3. .tarignore 生成规则

自动生成 `.tarignore` 文件，默认排除：

```
icon.png
upload_config.json
.git
__pycache__
*.pyc
*.log
.DS_Store
TEMPLATE_INFO.md
```

### 4. docker-compose.yml 处理

- 如果 addon 中存在 `docker-compose.yml`，直接复制
- 如果不存在，生成默认的 `docker-compose.yml`，使用 addon slug（连字符替换为下划线）作为服务名

## 使用方法

### 1. 为单个 Addon 生成 Template

```bash
./scripts/generate-template-from-addon.sh <addon-name> [--output-dir <dir>]
```

**示例：**
```bash
# 使用默认输出目录（addon_templates/）
./scripts/generate-template-from-addon.sh network-manager

# 指定输出目录
./scripts/generate-template-from-addon.sh network-manager --output-dir /path/to/addon_templates
```

### 2. 为所有 Addon 生成 Template

```bash
./scripts/generate-all-templates.sh [--output-dir <dir>]
```

**示例：**
```bash
# 使用默认输出目录
./scripts/generate-all-templates.sh

# 指定输出目录
./scripts/generate-all-templates.sh --output-dir /path/to/addon_templates
```

### 3. 创建新 Addon 时自动生成 Template

```bash
./scripts/add-addon.sh <addon-name> --generate-template
```

**示例：**
```bash
./scripts/add-addon.sh my-new-addon --generate-template
```

### 4. 验证 Addon 和 Template

```bash
# 仅验证 addon
./scripts/validate-addon.sh <addon-name>

# 同时验证 addon 和 template
./scripts/validate-addon.sh <addon-name> --check-template
```

## 脚本说明

### generate-template-from-addon.sh

从现有 addon 生成上传用的 template。

**功能：**
- 读取 addon 的 `repository.json` 和 `VERSION` 文件
- 生成 `upload_config.json`
- 复制必要的文件和目录
- 生成 `.tarignore` 文件
- 创建 `TEMPLATE_INFO.md` 说明文件

**参数：**
- `<addon-name>`: Addon 名称（必需）
- `--output-dir <dir>`: 输出目录（可选，默认：`addon_templates/`）

### generate-all-templates.sh

为所有现有 addon 批量生成 template。

**功能：**
- 扫描 `addons/` 目录下的所有 addon
- 为每个 addon 调用 `generate-template-from-addon.sh`
- 显示生成统计信息

**参数：**
- `--output-dir <dir>`: 输出目录（可选，默认：`addon_templates/`）

### add-addon.sh（已更新）

创建新 addon 的脚本，新增 `--generate-template` 选项。

**新增选项：**
- `--generate-template`: 创建 addon 后自动生成 template

### validate-addon.sh（已更新）

验证 addon 结构的脚本，新增 `--check-template` 选项。

**新增选项：**
- `--check-template`: 同时检查上传用的 template

## 生成后的检查清单

生成 template 后，请检查以下内容：

- [ ] `upload_config.json` 中的配置是否正确
  - `id` 字段是否唯一
  - `visiturl` 是否正确配置
  - `addonid` 是否需要修改
- [ ] `docker-compose.yml` 配置是否正确
  - 服务名和容器名是否正确
  - 端口映射是否正确
  - 环境变量是否配置
- [ ] `icon.png` 是否存在（如果不需要可以忽略）
- [ ] `common/` 目录中的文件是否完整
- [ ] `.tarignore` 是否需要调整
- [ ] `README.md` 是否需要更新

## 注意事项

1. **版本号同步**：Template 中的版本号从 addon 的 `VERSION` 文件读取，确保版本号正确
2. **文件排除**：`.tarignore` 中已排除 `upload_config.json` 和 `icon.png`，这些文件不会被打包
3. **目录结构**：Template 目录结构与 addon 目录结构类似，但包含额外的上传配置文件
4. **重复生成**：可以重复运行生成脚本，已存在的文件会被覆盖（`README.md` 除外，如果已存在则不会覆盖）

## 与上传工具的集成

生成的 template 可以直接用于 `upload_batch.py` 脚本上传：

```bash
cd /path/to/addons_upload
python3 upload_batch.py -t all
```

或者指定特定的 addon：

```bash
python3 upload_batch.py -t targets  # targets 文件中列出要上传的 addon
```

## 相关文档

- [Addon 开发指南](./ADDON_GUIDE.md)
- [设计方案](./DESIGN.md)
- [快速开始](./QUICKSTART.md)
