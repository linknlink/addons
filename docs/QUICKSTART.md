# 快速开始指南

本指南帮助您快速了解和使用 Docker 容器应用管理仓库框架。

## 框架概览

这是一个用于管理多个 Docker 容器应用的统一仓库框架，旨在为 Ubuntu Server 系统提供相关能力，提供：

- ✅ 标准化的 addon 结构
- ✅ 自动化构建和发布流程
- ✅ CI/CD 集成
- ✅ 版本管理
- ✅ 开发工具和脚本

## 目录结构

```
addons/
├── .github/workflows/     # CI/CD 工作流
├── addons/                 # Addon 目录（存放所有 addon）
├── scripts/                # 管理脚本
├── templates/              # Addon 模板
├── docs/                   # 文档
├── repository.json         # 仓库配置
└── README.md              # 主文档
```

## 快速开始

### 1. 添加新 Addon

```bash
./scripts/add-addon.sh my-new-addon
```

这将创建一个标准的 addon 目录结构。

### 2. 开发 Addon

编辑 `addons/my-new-addon/` 目录下的文件：

- `common/rootfs/app/` - 应用代码
- `common/Dockerfile` - Docker 构建文件
- `README.md` - 文档

### 3. 验证 Addon

```bash
./scripts/validate-addon.sh my-new-addon
```

### 4. 构建 Addon

```bash
./scripts/build-addon.sh my-new-addon
```

### 5. 发布 Addon

```bash
./scripts/release-addon.sh my-new-addon patch --commit --push
```

## 常用命令

| 命令 | 说明 |
|------|------|
| `./scripts/add-addon.sh <name>` | 创建新 addon |
| `./scripts/validate-addon.sh <name>` | 验证 addon 结构 |
| `./scripts/build-addon.sh <name>` | 构建 addon |
| `./scripts/release-addon.sh <name> patch` | 发布 addon（补丁版本） |
| `./scripts/release-addon.sh <name> minor` | 发布 addon（次版本） |
| `./scripts/release-addon.sh <name> major` | 发布 addon（主版本） |

## 工作流程

### 开发新 Addon

1. 创建 addon: `./scripts/add-addon.sh my-addon`
2. 开发代码
3. 验证: `./scripts/validate-addon.sh my-addon`
4. 本地测试: `cd addons/my-addon && docker-compose up`
5. 构建测试: `./scripts/build-addon.sh my-addon`
6. 提交代码

### 发布更新

1. 更新代码和文档
2. 更新 CHANGELOG.md
3. 发布: `./scripts/release-addon.sh my-addon patch --commit --push`
4. CI/CD 自动构建和发布

## 文档

- [设计文档](DESIGN.md) - 完整的框架设计说明
- [开发指南](ADDON_GUIDE.md) - Addon 开发详细指南
- [贡献指南](CONTRIBUTING.md) - 如何参与贡献

## 下一步

- 阅读 [设计文档](DESIGN.md) 了解框架详情
- 查看 [开发指南](ADDON_GUIDE.md) 学习如何开发 addon
- 参考 `templates/addon-template/` 了解标准结构

## 获取帮助

如有问题：

- 查看文档
- 创建 [Issue](https://github.com/linknlink/addons/issues)
- 联系维护者
