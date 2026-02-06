# Template 生成信息

此 template 由脚本自动生成自 addon: `network-manager`

生成时间: 2026-02-06 16:28:21
源版本: 0.0.3

## 文件说明

- `upload_config.json`: 上传配置文件，需要根据实际情况修改
- `docker-compose.yml`: Docker Compose 配置
- `common/`: Addon 文件目录（包含 Dockerfile 和 rootfs/）
- `.tarignore`: 打包时排除的文件列表
- `DOCS.md`: 使用说明文档（从 README.md 生成）
- `README.md`: 说明文档（上传时会被排除）

## 使用前检查清单

- [ ] 检查并修改 `upload_config.json` 中的配置
- [ ] 确认 `docker-compose.yml` 配置正确
- [ ] 添加或更新 `icon.png` 图标文件
- [ ] 检查 `.tarignore` 是否需要调整
- [ ] 检查 `DOCS.md` 使用说明是否完整
