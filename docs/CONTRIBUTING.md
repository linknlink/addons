# 贡献指南

感谢您对 LinknLink Add-ons 仓库的兴趣！本文档将指导您如何参与贡献。

## 如何贡献

### 报告问题

如果您发现了 bug 或有功能建议：

1. 检查 [Issues](https://github.com/linknlink/addons/issues) 是否已有相关问题
2. 如果没有，创建新的 Issue
3. 提供清晰的问题描述和复现步骤

### 提交代码

1. Fork 本仓库
2. 创建功能分支 (`git checkout -b feature/amazing-feature`)
3. 提交更改 (`git commit -m 'feat: 添加新功能'`)
4. 推送到分支 (`git push origin feature/amazing-feature`)
5. 创建 Pull Request

### 添加新 Addon

1. 使用脚本创建 addon：
   ```bash
   ./scripts/add-addon.sh my-new-addon
   ```

2. 开发 addon 功能

3. 验证 addon：
   ```bash
   ./scripts/validate-addon.sh my-new-addon
   ```

4. 测试构建：
   ```bash
   ./scripts/build-addon.sh my-new-addon
   ```

5. 提交 Pull Request

## 代码规范

### 提交消息

使用 [Conventional Commits](https://www.conventionalcommits.org/) 格式：

- `feat`: 新功能
- `fix`: 修复 bug
- `docs`: 文档更新
- `style`: 代码格式（不影响功能）
- `refactor`: 重构
- `test`: 测试相关
- `chore`: 构建/工具相关

示例：
```
feat: 添加新的配置选项
fix: 修复启动脚本的错误
docs: 更新 README
```

### 代码风格

- 使用有意义的变量和函数名
- 添加必要的注释
- 保持代码简洁和可读
- 遵循现有代码风格

### Shell 脚本

- 使用 `set -e` 确保错误时退出
- 使用双引号包裹变量
- 检查命令是否存在
- 提供错误消息

### Dockerfile

- 使用多阶段构建（如适用）
- 最小化镜像大小
- 使用 `.dockerignore`
- 支持多架构

## Pull Request 流程

### 创建 PR 前

- [ ] 代码已通过验证脚本
- [ ] 已测试构建
- [ ] 更新了相关文档
- [ ] 提交消息符合规范

### PR 检查清单

- [ ] 代码符合项目规范
- [ ] 添加了必要的测试
- [ ] 更新了文档
- [ ] 没有破坏性变更（或已说明）

### 审查过程

- 维护者会审查您的 PR
- 可能需要一些修改
- 审查通过后会合并

## 开发环境设置

### 必需工具

- Git
- Docker
- Bash
- jq (用于 JSON 处理)

### 安装依赖

```bash
# Ubuntu/Debian
sudo apt-get install jq

# macOS
brew install jq
```

### 克隆仓库

```bash
git clone https://github.com/linknlink/addons.git
cd addons
```

## 测试

### 验证 Addon

```bash
./scripts/validate-addon.sh <addon-name>
```

### 构建测试

```bash
./scripts/build-addon.sh <addon-name> --arch amd64
```

### 本地运行

```bash
cd addons/<addon-name>
docker-compose up --build
```

## 文档

### 更新文档

- README.md: 主要文档
- docs/DESIGN.md: 设计文档
- docs/ADDON_GUIDE.md: 开发指南
- 各 addon 的 README.md

### 文档要求

- 使用清晰的标题和结构
- 提供代码示例
- 保持文档更新

## 行为准则

### 我们的承诺

为了营造开放和友好的环境，我们承诺：

- 尊重所有贡献者
- 接受建设性批评
- 关注社区最佳利益
- 对其他社区成员表示同理心

### 不可接受的行为

- 使用性化的语言或图像
- 人身攻击或侮辱性评论
- 公开或私下骚扰
- 发布他人的私人信息
- 其他不道德或不专业的行为

## 许可证

通过贡献，您同意您的贡献将在与项目相同的许可证下授权。

## 联系方式

如有问题，可以通过以下方式联系：

- 创建 [Issue](https://github.com/linknlink/addons/issues)
- 联系维护者

感谢您的贡献！
