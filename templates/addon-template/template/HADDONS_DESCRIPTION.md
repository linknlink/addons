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

#### config.json 配置（开发时 Addon 目录需要）

`config.json` 是开发时 Addon 目录需要的配置文件，定义了 Addon 的元数据、配置选项和 Schema。

**注意**：Template 中不需要 `config.json`，因为 Haddons 服务会从 `upload_config.json` 和 `docker-compose.yml` 中获取所需信息。

#### docker-compose.yml 配置

`docker-compose.yml` 定义了容器的编排配置，包括镜像、环境变量、挂载卷等。

**重要**：Template 中的 `docker-compose.yml` 必须使用已发布的镜像（`image:`），不要使用 `build:`。

#### 环境变量映射

Haddons 服务会将配置项映射为环境变量（开发时通过 `config.json` 定义，Template 中通过 `docker-compose.yml` 直接配置）：
- 配置项名称（小写，下划线分隔）
- 映射为环境变量（大写，下划线分隔）

例如：
- `wifi_scan_interval` → `WIFI_SCAN_INTERVAL`
- `auto_reconnect` → `AUTO_RECONNECT`

### Haddons Template 文件要求

Haddons Template 是用于上传到 Haddons 服务的模板文件包。**注意**：这里说明的是**上传必需的文件**（Haddons 服务识别和管理 Addon 所需的最小文件集），而不是服务运行需要的文件。

#### 上传必需的文件（最小文件集）

**只有以下两个文件是上传必需的**，缺少任何一个文件，Haddons 服务都无法识别和管理 Addon：

1. **`upload_config.json`** - 上传配置文件（**必需**）
   - 定义 Addon 的上传元数据
   - 包含：name、addonid、version、display_name、id 等字段
   - 用于 Haddons 服务识别和管理 Addon
   - **作用**：Haddons 服务读取此文件获取 Addon 的基本信息，用于在 Web 界面中显示和管理

2. **`docker-compose.yml`** - Docker Compose 配置（**必需**）
   - 定义容器的编排配置
   - **重要**：必须使用已发布的镜像（`image:`），不能使用 `build:`
   - 包含：镜像地址、环境变量、端口映射、挂载卷等
   - **作用**：Haddons 服务使用此文件来启动、停止和管理容器

#### Template 中不需要的文件

以下文件是开发时 Addon 目录需要的，但在 Template 上传包中**不需要**：

- **`common/`** - Addon 文件目录（**Template 中不需要**）
  - 包含 `Dockerfile` 和 `rootfs/` 目录，用于构建 Docker 镜像
  - **说明**：Template 必须使用 `image:` 而不是 `build:`，因此不需要构建文件

- **`config.json`** - Haddons Addon 配置文件（**Template 中不需要**）
  - 定义 Addon 的元数据、配置选项和 Schema
  - **说明**：Template 中不需要，Haddons 服务会从 `upload_config.json` 和 `docker-compose.yml` 中获取所需信息

#### 推荐文件

4. **`README.md`** - 核心能力说明文档（推荐）
   - 描述 Addon 的核心能力和主要功能
   - 面向最终用户，会显示在 Haddons Web 界面的 Addon 卡片中
   - 内容应简洁、用户友好，突出核心价值

5. **`DOCS.md`** - 详细使用说明文档（推荐）
   - 详细的使用指南，面向生产环境用户
   - 会显示在 Haddons Web 界面的"文档"标签页中
   - 包含：快速开始、配置说明、使用场景、故障排查等

6. **`icon.png`** - 图标文件（推荐）
   - Addon 的图标，显示在 Haddons Web 界面中
   - 推荐尺寸：512x512 像素
   - 格式：PNG，透明背景

#### 可选文件

7. **`.tarignore`** - 打包排除文件列表（可选）
   - 定义打包时排除的文件
   - 默认排除：icon.png、upload_config.json、README.md、TEMPLATE_INFO.md 等

8. **`CHANGELOG.md`** - 更新日志（可选）
   - 记录 Addon 的版本更新历史

9. **`requirements.txt`** - Python 依赖（可选）
   - 如果 Addon 使用 Python，列出依赖包

10. **`repository.json`** - 仓库元数据（可选）
    - Addon 的仓库元数据信息

#### Template 目录结构示例

```
<addon-name>/
├── upload_config.json        # 必需：上传配置（Haddons 服务识别必需）
├── docker-compose.yml        # 必需：Docker Compose 配置（Haddons 服务运行必需）
├── README.md                 # 推荐：核心能力说明（用户界面显示）
├── DOCS.md                   # 推荐：详细使用说明（文档标签页显示）
├── icon.png                  # 推荐：图标文件（用户界面显示）
├── .tarignore                # 可选：打包排除规则
├── CHANGELOG.md              # 可选：更新日志
├── requirements.txt          # 可选：Python 依赖
└── repository.json           # 可选：仓库元数据
```

**重要说明**：
- **上传必需的文件**：只有 `upload_config.json` 和 `docker-compose.yml` 是上传必需的
- **推荐文件**：`README.md`、`DOCS.md`、`icon.png` 等用于改善用户体验，但不是必需的
- **不需要的文件**：`common/` 目录在 Template 中不需要（因为使用 `image:` 而不是 `build:`）

### Template 文件生成说明

以下说明每个文件是如何生成的，以及生成后需要如何检查和修改：

#### 1. upload_config.json（自动生成）

**生成方式**：
- 脚本从 addon 的 `VERSION` 文件读取版本号
- 使用提取的信息和默认值生成完整的 `upload_config.json` 文件

**字段说明**（Haddons 标准格式）：

| 字段 | 类型 | 说明 | 生成来源 |
|------|------|------|---------|
| `name` | string | Addon 显示名称 | `config.json` 的 `name` 字段（优先）或 `repository.json` 的 `name` 字段 |
| `addonid` | string | Addon ID（数据库中的 ID） | 默认为 `"0"`，上传后由系统分配 |
| `addondescription` | string | Addon 描述信息 | `config.json` 的 `description` 字段（优先）或 `repository.json` 的 `description` 字段 |
| `version` | string | Addon 版本号 | `VERSION` 文件内容 |
| `visiturl` | string | 访问 URL（如果有 Web 界面） | 默认为空字符串 `""`，需要手动填写 |
| `issupportupdate` | int | 是否支持更新（0=否，1=是） | 默认为 `0` |
| `issupportuninstall` | int | 是否支持卸载（0=否，1=是） | 默认为 `1` |
| `isbuiltin` | int | 是否内置 Addon（0=否，1=是） | 默认为 `0` |
| `candisableservice` | int | 是否可以禁用服务（0=否，1=是） | 默认为 `1` |
| `releasestatus` | int | 发布状态（0=未发布，1=已发布） | 默认为 `1` |
| `order` | int | 排序顺序（数字越小越靠前） | 默认为 `0` |
| `display_name` | string | 显示名称（用于界面显示） | addon 名称（小写，连字符分隔） |
| `id` | string | Addon 唯一标识符 | addon 名称（小写，连字符分隔） |

**生成后检查**：
- [ ] 确认 `name` 是否正确（应与 `config.json` 的 name 一致）
- [ ] 确认 `addonid` 是否正确（默认为 "0"，上传后由系统分配，通常不需要修改）
- [ ] 确认 `addondescription` 是否完整、准确
- [ ] 确认 `version` 是否与 VERSION 文件一致
- [ ] 确认 `visiturl` 是否填写（如果有 Web 访问地址）
- [ ] 确认 `id` 和 `display_name` 是否正确（应为小写，连字符分隔）
- [ ] 确认 `releasestatus` 是否为 `1`（已发布状态）
- [ ] 确认其他布尔字段（`issupportupdate`、`issupportuninstall`、`isbuiltin`、`candisableservice`）是否符合需求

#### 2. docker-compose.yml（复制并处理）

**生成方式**：
- 从 addon 的 `docker-compose.yml` 复制
- 如果不存在，创建默认文件

**处理逻辑**：
- 检测是否包含 `build:`，如果存在则：
  - 注释掉 `build:` 部分
  - 添加 `image:` 行（需要手动确认镜像地址）
- 如果不存在，创建默认配置

**生成后检查**：
- [ ] **重要**：确认使用 `image:` 而不是 `build:`
- [ ] 确认镜像地址和版本正确（如：`ghcr.io/linknlink/addon_name:0.0.1`）
- [ ] 确认端口映射、环境变量、挂载卷等配置正确
- [ ] 确认容器名称和服务名称正确

#### 3. README.md（使用模板生成）

**生成方式**：
- 使用 `templates/addon-template/template/README.md` 作为模板
- 自动替换变量：`{{ADDON_NAME}}`、`{{ADDON_SLUG}}`
- 从 addon 的 README.md 提取概述和主要功能（如果存在）

**生成逻辑**：
1. 复制模板文件
2. 替换模板变量
3. 从 addon README.md 提取概述（清理技术细节）
4. 从 addon README.md 提取主要功能列表

**生成后检查**：
- [ ] 确认概述部分清晰、用户友好（移除技术实现细节）
- [ ] 确认功能描述准确、易懂
- [ ] 确认适用场景描述合理
- [ ] 确认内容面向最终用户，避免开发者术语

#### 4. DOCS.md（使用模板生成）

**生成方式**：
- 使用 `templates/addon-template/template/DOCS.md` 作为模板
- 自动替换变量：`{{ADDON_NAME}}`、`{{ADDON_SLUG}}`

**生成逻辑**：
1. 复制模板文件
2. 替换模板变量
3. 从 `config.json` 的 `schema` 提取配置选项信息（如果存在）

**生成后检查**：
- [ ] 补充配置选项的详细说明（从 addon 的 config.json 的 schema 提取）
- [ ] 添加实际使用场景和示例
- [ ] 完善故障排查指南
- [ ] 确认所有配置项都有说明
- [ ] 确认使用说明完整、清晰

#### 5. icon.png（复制）

**生成方式**：
- 从 addon 的 `icon.png` 复制（如果存在）
- 如果不存在，需要手动添加

**生成后检查**：
- [ ] 确认图标文件存在
- [ ] 确认尺寸为 512x512 像素（推荐）
- [ ] 确认格式为 PNG，透明背景
- [ ] 确认图标清晰，在小尺寸下可识别

#### 6. .tarignore（使用模板或生成）

**生成方式**：
- 优先使用 `templates/addon-template/template/.tarignore` 模板
- 如果模板不存在，生成默认配置

**默认排除规则**（模板 `.tarignore`）：
```
.git
__pycache__
*.pyc
*.log
.DS_Store
TEMPLATE_INFO.md
```

**重要说明**：
- `.tarignore` 中**不排除** `upload_config.json` 和 `docker-compose.yml`（这两个是上传必需的）
- `.tarignore` 中**不排除** `README.md`、`DOCS.md`、`icon.png`（这些是推荐文件，应该上传）
- `.tarignore` 中**排除** `TEMPLATE_INFO.md`（这是生成信息文件，不需要上传）
- `.tarignore` 中**排除** `common/`（Template 中不需要，因为使用 `image:` 而不是 `build:`）

**生成后检查**：
- [ ] 确认 `upload_config.json` 和 `docker-compose.yml` **没有被排除**（这两个是上传必需的）
- [ ] 确认 `README.md`、`DOCS.md`、`icon.png` **没有被排除**（这些是推荐文件）
- [ ] 确认 `common/` 目录被排除（Template 中不需要）

#### 7. CHANGELOG.md（复制，可选）

**生成方式**：
- 从 addon 的 `CHANGELOG.md` 复制（如果存在）

**生成后检查**：
- [ ] 确认更新日志内容完整
- [ ] 确认版本号与 VERSION 文件一致

#### 8. requirements.txt（复制，可选）

**生成方式**：
- 从 addon 的 `requirements.txt` 复制（如果存在）

**生成后检查**：
- [ ] 确认依赖列表完整
- [ ] 确认版本号正确

#### 9. repository.json（复制，可选）

**生成方式**：
- 从 addon 的 `repository.json` 复制（如果存在）

**生成后检查**：
- [ ] 确认元数据信息正确

### Haddons 界面说明

- **信息标签页**: 显示 Addon 基本信息、状态、操作按钮
- **文档标签页**: 显示 `DOCS.md` 的内容
- **配置标签页**: 显示配置选项（通过 `docker-compose.yml` 中的环境变量配置）
- **日志标签页**: 显示容器运行日志

## 注意事项

### Template 文件注意事项

#### 上传必需的文件

- **upload_config.json**：**必需**，确保格式正确，字段完整，否则 Haddons 服务无法识别和管理 Addon
- **docker-compose.yml**：**必需**，必须使用已发布的镜像（`image:`），不能使用 `build:`

#### 不需要的文件

- **common/ 目录**：**不需要**包含在上传包中，因为 Template 必须使用 `image:`，使用的是已发布的镜像，不需要构建文件
- **config.json**：**不需要**包含在上传包中，这是开发时 Addon 目录需要的文件，Template 中不需要

#### 推荐文件（可选，但建议包含）

- **README.md**：应面向用户，描述核心能力，避免技术实现细节
- **DOCS.md**：应包含完整的使用说明，包括配置选项、使用场景、故障排查等
- **icon.png**：建议使用 512x512 像素的 PNG 格式，透明背景

### 生成 Template

# 生成后需要检查：
# 1. upload_config.json 中的配置是否正确
# 2. docker-compose.yml 是否使用 image: 而不是 build:
# 3. README.md 和 DOCS.md 是否需要完善
# 4. icon.png 是否存在
```

**重要**：需要生成template子目录，所有配置文件放在template目录中