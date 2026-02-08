# Template 生成信息

此 template 由脚本自动生成自 addon: `hacs-installer`

生成时间: 2026-02-08 16:53:12
源版本: 1.0.0
模板来源: `addons/hacs-installer/template/`

## 文件说明

- `upload_config.json`: 上传配置文件（**必需**），已从模板复制并更新版本号
- `docker-compose.yml`: Docker Compose 配置（**必需**），必须使用 image: 而不是 build:
- `.tarignore`: 打包时排除的文件列表
- `DOCS.md`: 使用说明文档（推荐），会显示在 Haddons Web 界面的"文档"标签页
- `README.md`: 核心能力说明文档（推荐），会显示在 Haddons Web 界面的 Addon 卡片中
- `icon.png`: 图标文件（推荐），显示在 Haddons Web 界面中

**注意**：
- 模板文件来自 `addons/hacs-installer/template/` 目录
- 如需修改模板内容，请编辑 `addons/hacs-installer/template/` 目录中的文件，然后重新运行生成脚本
- `common/` 目录**不需要**包含在 Template 中，因为 Template 必须使用已发布的镜像（`image:`），不需要构建文件

## 使用前检查清单

- [ ] 检查 `upload_config.json` 中的配置（版本号已自动更新为 1.0.0）
- [ ] 确认 `docker-compose.yml` 配置正确（使用 image: 而不是 build:）
- [ ] 确认 `README.md` 和 `DOCS.md` 内容完整
- [ ] 确认 `icon.png` 存在（如需要）
