# Haddons 插件开发规范：config.json 配置文件

## 概述

`config.json` 是 Haddons 插件系统的核心配置文件，用于定义插件的元数据、用户可配置选项和运行时行为。所有插件都应该在根目录下包含此文件。

> **适用对象**: 所有 Haddons 插件开发者  
> **文档用途**: 创建新插件或为现有插件添加配置支持时参考

## 标准目录结构

```
addon_templates/
└── your-addon/
    ├── config.json          # 配置文件
    ├── docker-compose.yml   # Docker Compose 配置
    ├── README.md            # 说明文档
    └── icon.png             # 插件图标
```

## 必需字段说明

### 基础元数据（必填）

| 字段名 | 类型 | 说明 | 示例 |
|--------|------|------|------|
| `name` | string | 插件的显示名称，在 UI 中展示 | `"My Awesome Addon"` |
| `version` | string | 插件版本号，建议使用语义化版本 | `"1.0.0"` 或 `"latest"` |
| `slug` | string | 插件唯一标识符，仅包含小写字母、数字和连字符 | `"my-awesome-addon"` |
| `description` | string | 插件的简短描述（50-100 字） | `"一个强大的工具插件"` |

> **slug 命名规则**:
> - 只能包含小写字母、数字和连字符 `-`
> - 不能以连字符开头或结尾
> - 必须在整个系统中唯一
> - 示例：`mosquitto`, `node-red`, `zwave-js-ui`

### 启动配置（可选）

| 字段名 | 类型 | 默认值 | 说明 | 可选值 |
|--------|------|--------|------|--------|
| `startup` | string | `"application"` | 启动优先级类型 | `"application"`, `"system"`, `"services"` |
| `boot` | string | `"manual"` | 开机启动模式 | `"auto"` (自动), `"manual"` (手动) |

**startup 类型说明**:
- `application`: 普通应用服务（默认）
- `system`: 系统级服务
- `services`: 基础服务

### Ingress 配置（Web UI）

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `ingress` | boolean | `false` | 插件是否提供 Web 管理界面 |
| `ingress_port` | integer | 无 | Web UI 监听端口（`ingress=true` 时必需） |

> **重要提示**:
> - 如果 `ingress` 为 `true`，**必须**提供 `ingress_port`
> - 端口号应避免与常见服务冲突（如 80, 443, 3000, 8080 等）
> - 推荐使用 8000-9000 范围内的端口

### 用户配置选项

#### `options` 字段

定义插件的默认配置值。这些值可以被用户在 UI 中修改。

**类型**: `object`  
**必需**: ❌

**示例**:
```json
"options": {
  "mqtt_broker": "localhost",
  "mqtt_port": 1883,
  "log_level": "info",
  "enable_ssl": false,
  "data_retention_days": 30
}
```

#### `schema` 字段

定义每个选项的数据类型，用于 UI 渲染和验证。

**类型**: `object`  
**必需**: ❌（如果有 `options` 则推荐提供）

**支持的类型**:
- `"str"` 或 `"string"` - 字符串
- `"int"` 或 `"integer"` - 整数
- `"bool"` 或 `"boolean"` - 布尔值
- `"list(...)"` - 列表（例如 `"list(str)"`）

**示例**:
```json
"schema": {
  "mqtt_broker": "str",
  "mqtt_port": "int",
  "log_level": "str",
  "enable_ssl": "bool",
  "data_retention_days": "int"
}
```

> **重要**: 
> - 如果定义了 `schema`，UI 将显示 **Configuration** 标签页
> - `schema` 中的键必须与 `options` 中的键匹配

## 环境变量注入机制

当插件启动时，系统会自动将 `options` 中的配置转换为环境变量，并通过 `.env` 文件传递给 Docker 容器：

1. **键名转换**: 小写转大写，非字母数字字符替换为下划线
   - `mqtt_broker` → `MQTT_BROKER`
   - `log_level` → `LOG_LEVEL`
   - `data_retention_days` → `DATA_RETENTION_DAYS`

2. **值类型转换**:
   - 字符串: 直接使用
   - 数字: 转换为字符串
   - 布尔值: `true` 或 `false`
   - 复杂对象: JSON 编码

3. **自动引用**: 包含空格或特殊字符的值会自动添加引号

## 配置示例

### 示例 1：最简配置（无用户选项）

适用于无需用户配置的简单插件：

```json
{
  "name": "Samba Share",
  "version": "1.0.0",
  "slug": "samba",
  "description": "Network file sharing service",
  "startup": "application",
  "boot": "manual"
}
```

### 示例 2：带 Web UI 的插件

适用于提供管理界面的插件：

```json
{
  "name": "AdGuard Home",
  "version": "latest",
  "slug": "adguardhome",
  "description": "Network-wide ads & trackers blocking DNS server",
  "startup": "application",
  "boot": "auto",
  "ingress": true,
  "ingress_port": 3000
}
```

### 示例 3：完整配置（带用户选项）

适用于需要用户配置的复杂插件：

```json
{
  "name": "Mosquitto MQTT Broker",
  "version": "2.0",
  "slug": "mosquitto",
  "description": "Open source MQTT broker",
  "startup": "services",
  "boot": "auto",
  "ingress": false,
  "options": {
    "broker_port": 1883,
    "websocket_port": 9001,
    "enable_auth": true,
    "log_level": "info",
    "max_connections": 100,
    "retain_messages": true
  },
  "schema": {
    "broker_port": "int",
    "websocket_port": "int",
    "enable_auth": "bool",
    "log_level": "str",
    "max_connections": "int",
    "retain_messages": "bool"
  }
}
```

### 示例 4：智能家居集成插件

```json
{
  "name": "Zigbee2MQTT",
  "version": "latest",
  "slug": "zigbee2mqtt",
  "description": "Zigbee to MQTT bridge",
  "startup": "application",
  "boot": "auto",
  "ingress": true,
  "ingress_port": 8080,
  "options": {
    "mqtt_server": "mqtt://localhost:1883",
    "mqtt_base_topic": "zigbee2mqtt",
    "serial_port": "/dev/ttyUSB0",
    "permit_join": false,
    "homeassistant": true
  },
  "schema": {
    "mqtt_server": "str",
    "mqtt_base_topic": "str",
    "serial_port": "str",
    "permit_join": "bool",
    "homeassistant": "bool"
  }
}
```

## UI 行为说明

### Configuration 标签页显示条件

Configuration 标签页会在以下情况显示：
- `schema` 字段存在且非空，**或者**
- `options` 字段存在且非空

### 用户修改配置的流程

1. 用户在 UI 的 Configuration 标签页修改配置
2. 点击 "Save" 按钮
3. 配置保存到 `data/{slug}_options.json`
4. 下次启动容器时，新配置通过环境变量传递给容器

## Docker Compose 集成

在 `docker-compose.yml` 中使用环境变量：

```yaml
services:
  my-addon:
    container_name: my-addon
    image: my-addon:latest
    environment:
      # 使用 ${VAR:-default} 语法提供默认值
      - MQTT_BROKER=${MQTT_BROKER:-localhost}
      - MQTT_PORT=${MQTT_PORT:-1883}
      - LOG_LEVEL=${LOG_LEVEL:-info}
      - ENABLE_SSL=${ENABLE_SSL:-false}
```

> **提示**: 使用 `${VAR_NAME:-default}` 语法可以在环境变量未定义时提供默认值。

## 最佳实践

### 1. 配置设计原则

- **提供合理默认值**: 在 `options` 中为所有配置项提供开箱即用的默认值
- **使用描述性键名**: 选择清晰、自解释的配置键名（如 `mqtt_broker` 而非 `mb`）
- **类型匹配**: 确保 `schema` 中的类型与 `options` 中的值类型一致
- **文档化**: 在 README.md 中详细说明每个配置项的作用

### 2. 安全性考虑

- **敏感信息**: 对于密码、API 密钥等敏感配置，提供占位符默认值并在文档中说明
  ```json
  "options": {
    "api_key": "YOUR_API_KEY_HERE",
    "password": "changeme"
  }
  ```
- **验证**: 在 docker-compose.yml 中添加启动检查，防止无效配置导致容器崩溃

### 3. 端口管理

避免端口冲突：
- **预留端口** (避免使用): 80, 443, 22, 3000, 5000, 8080, 8443
- **推荐范围**: 8000-8999 或 9000-9999
- **文档化**: 在 README 中说明需要占用的所有端口

### 4. 版本管理

- **语义化版本**: 使用 `MAJOR.MINOR.PATCH` 格式（如 `1.2.3`）
- **latest 标签**: 仅用于开发测试，生产环境应指定具体版本
- **更新说明**: 在版本更新时添加 CHANGELOG.md

## 故障排查

### Configuration 标签页不显示

**原因**: 插件缺少 `config.json` 或配置文件无效

**解决步骤**:
1. 检查插件目录下是否存在 `config.json`
2. 确认 `schema` **或** `options` 至少有一个非空
3. 使用 JSON 验证器检查格式是否正确
   ```bash
   # 在线验证：https://jsonlint.com/
   # 或使用命令行工具
   cat config.json | jq .
   ```
4. 检查插件是否已安装（只有已安装的插件才显示 Configuration 标签）

### 环境变量未生效

**原因**: 配置未保存或容器未重启

**解决步骤**:
1. 检查配置是否已保存
   ```bash
   cat data/{slug}_options.json
   ```
2. 重启容器以应用新配置
3. 查看容器日志
   ```bash
   docker logs {container_name}
   ```
4. 检查 `.env` 文件是否生成
   ```bash
   cat addons/{slug}/.env
   ```
5. 验证容器环境变量
   ```bash
   docker inspect {container_name} | grep -A 20 Env
   ```

### 配置丢失

**原因**: 用户配置文件被删除

**说明**:
- 用户配置保存在 `data/{slug}_options.json`
- 卸载插件时**不会自动删除**此文件
- 重新安装后配置会自动恢复
- 建议定期备份 `data/` 目录

### 常见错误

| 错误现象 | 可能原因 | 解决方法 |
|----------|----------|----------|
| JSON 解析失败 | 配置文件格式错误 | 使用 JSON 验证器检查格式 |
| 容器启动失败 | 环境变量值不合法 | 检查 docker logs 和 `.env` 文件 |
| Configuration 按钮不能点击 | 插件未安装 | 先安装插件 |
| 配置保存后不生效 | 未重启容器 | 停止并重新启动插件 |

## 参考资料

- [Docker Compose 环境变量文档](https://docs.docker.com/compose/environment-variables/)
- [JSON Schema 规范](https://json-schema.org/)
