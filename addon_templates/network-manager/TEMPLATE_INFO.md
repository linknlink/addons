# Template 生成信息

此 template 由脚本自动生成自 addon: `network-manager`

生成时间: 2026-02-06 21:50:27
源版本: 0.0.3

## 文件说明

- `upload_config.json`: 上传配置文件（**必需**），需要根据实际情况修改
- `docker-compose.yml`: Docker Compose 配置（**必需**），必须使用 image: 而不是 build:
- `.tarignore`: 打包时排除的文件列表
- `DOCS.md`: 使用说明文档（推荐），会显示在 Haddons Web 界面的"文档"标签页
- `README.md`: 核心能力说明文档（推荐），会显示在 Haddons Web 界面的 Addon 卡片中
- `icon.png`: 图标文件（推荐），显示在 Haddons Web 界面中

**注意**：`common/` 目录**不需要**包含在 Template 中，因为 Template 必须使用已发布的镜像（`image:`），不需要构建文件。

## 使用前检查清单

- [ ] 检查并修改 `upload_config.json` 中的配置
- [ ] 确认 `docker-compose.yml` 配置正确
- [ ] 添加或更新 `icon.png` 图标文件
- [ ] 检查 `.tarignore` 是否需要调整
- [ ] 检查 `DOCS.md` 使用说明是否完整
