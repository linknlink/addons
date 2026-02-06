#!/bin/bash

# 从现有 addon 生成上传用的 template 脚本
# 使用方法: ./scripts/generate-template-from-addon.sh <addon-name> [--output-dir <dir>]

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 显示帮助信息
show_help() {
    echo "使用方法: $0 <addon-name> [选项]"
    echo ""
    echo "参数:"
    echo "  addon-name    - Addon 名称（使用连字符，如: network-manager）"
    echo ""
    echo "选项:"
    echo "  --output-dir <dir>  - 输出目录（默认: ../addon_templates，相对于脚本位置）"
    echo "  --help, -h          - 显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 network-manager"
    echo "  $0 network-manager --output-dir /path/to/addon_templates"
}

# 检查参数
if [ $# -eq 0 ] || [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
    show_help
    exit 0
fi

ADDON_NAME="$1"
OUTPUT_DIR=""
shift

# 解析选项
while [[ $# -gt 0 ]]; do
    case $1 in
        --output-dir)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        *)
            echo -e "${RED}错误: 未知选项 '$1'${NC}"
            show_help
            exit 1
            ;;
    esac
done

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ADDONS_DIR="$PROJECT_ROOT/addons"
ADDON_DIR="$ADDONS_DIR/$ADDON_NAME"

# 确定输出目录
if [ -z "$OUTPUT_DIR" ]; then
    # 默认输出到项目根目录的 addon_templates 目录
    OUTPUT_DIR="$PROJECT_ROOT/addon_templates"
else
    OUTPUT_DIR="$(cd "$OUTPUT_DIR" && pwd)"
fi

TEMPLATE_DIR="$OUTPUT_DIR/$ADDON_NAME"

# 检查 addon 是否存在
if [ ! -d "$ADDON_DIR" ]; then
    echo -e "${RED}错误: Addon '$ADDON_NAME' 不存在${NC}"
    exit 1
fi

echo -e "${BLUE}正在从 addon '${ADDON_NAME}' 生成 template...${NC}"
echo ""

# 创建输出目录
mkdir -p "$TEMPLATE_DIR"
echo -e "${GREEN}创建输出目录: ${TEMPLATE_DIR}${NC}"

# 读取 addon 信息
VERSION="0.0.1"
if [ -f "$ADDON_DIR/VERSION" ]; then
    VERSION=$(cat "$ADDON_DIR/VERSION" | tr -d '[:space:]')
fi

# 读取 repository.json（如果存在）
ADDON_DISPLAY_NAME="$ADDON_NAME"
ADDON_DESCRIPTION=""
ADDON_ID="$ADDON_NAME"
ADDON_SLUG="${ADDON_NAME//-/_}"

if [ -f "$ADDON_DIR/repository.json" ]; then
    if command -v jq &> /dev/null; then
        ADDON_DISPLAY_NAME=$(jq -r '.name // "'"$ADDON_NAME"'"' "$ADDON_DIR/repository.json" 2>/dev/null || echo "$ADDON_NAME")
        ADDON_DESCRIPTION=$(jq -r '.description // ""' "$ADDON_DIR/repository.json" 2>/dev/null || echo "")
        ADDON_SLUG=$(jq -r '.slug // "'"${ADDON_NAME//-/_}"'"' "$ADDON_DIR/repository.json" 2>/dev/null || echo "${ADDON_NAME//-/_}")
    fi
fi

# 生成 upload_config.json
echo -e "${GREEN}生成 upload_config.json...${NC}"
cat > "$TEMPLATE_DIR/upload_config.json" <<EOF
{
    "name": "${ADDON_DISPLAY_NAME}",
    "addonid": "0",
    "addondescription": "${ADDON_DESCRIPTION}",
    "version": "${VERSION}",
    "visiturl": "",
    "issupportupdate": 0,
    "issupportuninstall": 1,
    "isbuiltin": 0,
    "candisableservice": 1,
    "releasestatus": 1,
    "order": 0,
    "display_name": "${ADDON_NAME}",
    "id": "${ADDON_NAME}"
}
EOF

# 复制 docker-compose.yml（如果存在）
if [ -f "$ADDON_DIR/docker-compose.yml" ]; then
    echo -e "${GREEN}复制 docker-compose.yml...${NC}"
    cp "$ADDON_DIR/docker-compose.yml" "$TEMPLATE_DIR/docker-compose.yml"
else
    echo -e "${YELLOW}警告: docker-compose.yml 不存在，创建默认文件...${NC}"
    cat > "$TEMPLATE_DIR/docker-compose.yml" <<EOF
services:
  ${ADDON_SLUG}:
    build:
      context: ./common
      dockerfile: Dockerfile
    container_name: ${ADDON_SLUG}
    restart: unless-stopped
    ports:
      - "8080:8080"
    environment:
      - ENV_VAR=value
EOF
fi

# 复制整个 addon 目录结构（用于打包）
echo -e "${GREEN}复制 addon 文件结构...${NC}"

# 复制 common 目录（必需）
if [ -d "$ADDON_DIR/common" ]; then
    cp -r "$ADDON_DIR/common" "$TEMPLATE_DIR/"
    echo "  复制: common/"
fi

# 复制其他可能需要的文件（不包括 README.md，稍后单独处理）
for file in "CHANGELOG.md" "requirements.txt" "repository.json"; do
    if [ -f "$ADDON_DIR/$file" ]; then
        cp "$ADDON_DIR/$file" "$TEMPLATE_DIR/"
        echo "  复制: $file"
    fi
done

# 生成 .tarignore
echo -e "${GREEN}生成 .tarignore...${NC}"
cat > "$TEMPLATE_DIR/.tarignore" <<EOF
icon.png
upload_config.json
.git
__pycache__
*.pyc
*.log
.DS_Store
TEMPLATE_INFO.md
README.md
EOF

# 复制或创建 README.md（如果不存在）
if [ ! -f "$TEMPLATE_DIR/README.md" ]; then
    if [ -f "$ADDON_DIR/README.md" ]; then
        echo -e "${GREEN}复制 README.md...${NC}"
        cp "$ADDON_DIR/README.md" "$TEMPLATE_DIR/README.md"
    else
        echo -e "${YELLOW}警告: README.md 不存在，创建默认文件...${NC}"
        cat > "$TEMPLATE_DIR/README.md" <<EOF
# ${ADDON_DISPLAY_NAME}

${ADDON_DESCRIPTION:-Docker 容器应用描述，旨在为 Ubuntu Server 系统提供相关能力。}

## 配置说明

请根据实际需求修改 \`docker-compose.yml\` 和 \`upload_config.json\`。

## 使用方法

1. 修改 \`upload_config.json\` 中的配置项
2. 修改 \`docker-compose.yml\` 中的镜像和配置
3. 使用 \`upload_batch.py\` 上传到服务器

## 注意事项

- 确保 \`id\` 字段在系统中唯一
- 检查 \`visiturl\` 是否正确配置
- 验证 Docker 镜像是否可用
EOF
    fi
fi

# 检查是否有 icon.png
if [ -f "$ADDON_DIR/icon.png" ]; then
    echo -e "${GREEN}复制 icon.png...${NC}"
    cp "$ADDON_DIR/icon.png" "$TEMPLATE_DIR/icon.png"
else
    echo -e "${YELLOW}提示: 请添加 icon.png 文件到 ${TEMPLATE_DIR}${NC}"
fi

# 生成 DOCS.md 使用说明文档
echo -e "${GREEN}生成 DOCS.md 使用说明文档...${NC}"
if [ -f "$ADDON_DIR/README.md" ]; then
    # 从 README.md 复制内容作为 DOCS.md
    cp "$ADDON_DIR/README.md" "$TEMPLATE_DIR/DOCS.md"
    echo "  从 README.md 生成 DOCS.md"
else
    # 如果 README.md 不存在，创建基本的 DOCS.md
    cat > "$TEMPLATE_DIR/DOCS.md" <<EOF
# ${ADDON_DISPLAY_NAME} 使用说明

${ADDON_DESCRIPTION:-Docker 容器应用描述，旨在为 Ubuntu Server 系统提供相关能力。}

## 快速开始

### 使用 Docker Compose

1. 编辑 \`docker-compose.yml\`，配置必要的环境变量和挂载卷
2. 启动容器：
   \`\`\`bash
   docker-compose up -d
   \`\`\`

### 使用 Docker 命令

\`\`\`bash
docker run -d \\
  --name ${ADDON_NAME} \\
  --restart unless-stopped \\
  <镜像名称>:<版本>
\`\`\`

## 配置说明

请根据实际需求修改 \`docker-compose.yml\` 中的配置项。

## 注意事项

- 确保容器有足够的权限访问所需资源
- 检查端口映射是否正确
- 验证挂载卷路径是否存在
EOF
    echo "  创建默认 DOCS.md"
fi

# 创建说明文件
cat > "$TEMPLATE_DIR/TEMPLATE_INFO.md" <<EOF
# Template 生成信息

此 template 由脚本自动生成自 addon: \`${ADDON_NAME}\`

生成时间: $(date '+%Y-%m-%d %H:%M:%S')
源版本: ${VERSION}

## 文件说明

- \`upload_config.json\`: 上传配置文件，需要根据实际情况修改
- \`docker-compose.yml\`: Docker Compose 配置
- \`common/\`: Addon 文件目录（包含 Dockerfile 和 rootfs/）
- \`.tarignore\`: 打包时排除的文件列表
- \`DOCS.md\`: 使用说明文档（从 README.md 生成）
- \`README.md\`: 说明文档（上传时会被排除）

## 使用前检查清单

- [ ] 检查并修改 \`upload_config.json\` 中的配置
- [ ] 确认 \`docker-compose.yml\` 配置正确
- [ ] 添加或更新 \`icon.png\` 图标文件
- [ ] 检查 \`.tarignore\` 是否需要调整
- [ ] 检查 \`DOCS.md\` 使用说明是否完整
EOF

echo ""
echo -e "${GREEN}✓ Template 生成成功！${NC}"
echo ""
echo "输出目录: ${TEMPLATE_DIR}"
echo ""
echo "下一步:"
echo "  1. 检查并修改 ${TEMPLATE_DIR}/upload_config.json"
echo "  2. 检查并修改 ${TEMPLATE_DIR}/docker-compose.yml"
if [ ! -f "$TEMPLATE_DIR/icon.png" ]; then
    echo "  3. 添加 icon.png 文件到 ${TEMPLATE_DIR}"
fi
echo "  4. 检查 common/ 和其他目录中的文件"
echo "  5. 使用 upload_batch.py 上传到服务器"
echo ""
