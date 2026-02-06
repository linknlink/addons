# Template 生成信息

此 template 由脚本自动生成自 addon: `network-manager`

生成时间: 2026-02-06 16:58:33
源版本: 0.0.3

## 文件说明

- `config.json`: **Haddons 服务必需的配置文件**，定义了 Addon 的元数据、配置选项和 Schema
- `upload_config.json`: 上传配置文件，需要根据实际情况修改
- `docker-compose.yml`: **Haddons 服务必需的 Docker Compose 配置**（使用已发布的镜像，不需要 build）
- `.tarignore`: 打包时排除的文件列表
- `DOCS.md`: 使用说明文档（Haddons 服务会显示此文档）
- `README.md`: 说明文档（上传时会被排除）

**注意**：Template 中不包含 `common/` 目录，因为使用的是已构建的 Docker 镜像，不需要构建文件。

## 使用前检查清单

- [ ] **检查 `config.json` 格式是否正确**（Haddons 服务必需）
- [ ] **确认 `docker-compose.yml` 配置正确**（Haddons 服务必需）
- [ ] 检查并修改 `upload_config.json` 中的配置
- [ ] 添加或更新 `icon.png` 图标文件
- [ ] 检查 `.tarignore` 是否需要调整
- [ ] 检查 `DOCS.md` 使用说明是否完整
