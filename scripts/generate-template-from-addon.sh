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
TEMPLATE_REF_DIR="$PROJECT_ROOT/templates/addon-template/template"

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

# 检查 addon 是否有 template/ 目录
ADDON_TEMPLATE_DIR="$ADDON_DIR/template"
if [ ! -d "$ADDON_TEMPLATE_DIR" ]; then
    echo -e "${RED}错误: Addon '$ADDON_NAME' 没有 template/ 目录${NC}"
    echo "  请先运行: ./scripts/add-addon.sh $ADDON_NAME"
    echo "  然后编辑 addons/$ADDON_NAME/template/ 目录中的模板文件"
    exit 1
fi

# 创建输出目录
mkdir -p "$TEMPLATE_DIR"
echo -e "${GREEN}创建输出目录: ${TEMPLATE_DIR}${NC}"

# 从 addon 的 template/ 目录复制模板文件
echo -e "${GREEN}从 addon template/ 目录复制模板文件...${NC}"

# 复制所有模板文件
cp -r "$ADDON_TEMPLATE_DIR"/* "$TEMPLATE_DIR/" 2>/dev/null || {
    echo -e "${RED}错误: 无法复制模板文件${NC}"
    exit 1
}

# 读取版本号（用于更新 upload_config.json）
VERSION="0.0.1"
if [ -f "$ADDON_DIR/VERSION" ]; then
    VERSION=$(cat "$ADDON_DIR/VERSION" | tr -d '[:space:]')
fi

# 读取 addon 信息（用于更新 upload_config.json）
ADDON_DISPLAY_NAME="$ADDON_NAME"
ADDON_DESCRIPTION=""
ADDON_SLUG="${ADDON_NAME//-/_}"

# 优先从 config.json 读取（Haddons 标准）
if [ -f "$ADDON_DIR/config.json" ] && command -v jq &> /dev/null; then
    ADDON_DISPLAY_NAME=$(jq -r '.name // "'"$ADDON_NAME"'"' "$ADDON_DIR/config.json" 2>/dev/null || echo "$ADDON_NAME")
    ADDON_DESCRIPTION=$(jq -r '.description // ""' "$ADDON_DIR/config.json" 2>/dev/null || echo "")
    ADDON_SLUG=$(jq -r '.slug // "'"${ADDON_NAME//-/_}"'"' "$ADDON_DIR/config.json" 2>/dev/null || echo "${ADDON_NAME//-/_}")
# 否则从 repository.json 读取
elif [ -f "$ADDON_DIR/repository.json" ] && command -v jq &> /dev/null; then
    ADDON_DISPLAY_NAME=$(jq -r '.name // "'"$ADDON_NAME"'"' "$ADDON_DIR/repository.json" 2>/dev/null || echo "$ADDON_NAME")
    ADDON_DESCRIPTION=$(jq -r '.description // ""' "$ADDON_DIR/repository.json" 2>/dev/null || echo "")
    ADDON_SLUG=$(jq -r '.slug // "'"${ADDON_NAME//-/_}"'"' "$ADDON_DIR/repository.json" 2>/dev/null || echo "${ADDON_NAME//-/_}")
fi

# 如果没有描述，使用默认值
if [ -z "$ADDON_DESCRIPTION" ]; then
    ADDON_DESCRIPTION="${ADDON_DISPLAY_NAME} 旨在为 Ubuntu Server 系统提供相关能力。"
fi

# 更新 upload_config.json（如果存在）
if [ -f "$TEMPLATE_DIR/upload_config.json" ] && command -v jq &> /dev/null; then
    echo -e "${GREEN}更新 upload_config.json...${NC}"
    # 更新版本号和描述
    jq ".version = \"${VERSION}\" | .name = \"${ADDON_DISPLAY_NAME}\" | .addondescription = \"${ADDON_DESCRIPTION}\" | .display_name = \"${ADDON_NAME}\" | .id = \"${ADDON_NAME}\"" \
        "$TEMPLATE_DIR/upload_config.json" > "$TEMPLATE_DIR/upload_config.json.tmp" && \
        mv "$TEMPLATE_DIR/upload_config.json.tmp" "$TEMPLATE_DIR/upload_config.json"
    echo "  ✓ 已更新版本号: ${VERSION}"
else
    echo -e "${YELLOW}警告: upload_config.json 不存在，创建默认文件...${NC}"
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
fi

# 检查并处理 docker-compose.yml
if [ -f "$TEMPLATE_DIR/docker-compose.yml" ]; then
    echo -e "${GREEN}检查 docker-compose.yml...${NC}"
    # 检查是否包含 build:，如果存在则警告
    if grep -q "build:" "$TEMPLATE_DIR/docker-compose.yml"; then
        echo -e "${YELLOW}警告: docker-compose.yml 包含 build:，需要改为 image:${NC}"
        echo "  请编辑 $TEMPLATE_DIR/docker-compose.yml，将 build: 改为 image: <镜像名称>:<版本>"
    else
        echo "  ✓ docker-compose.yml 使用 image:（正确）"
    fi
else
    echo -e "${YELLOW}警告: docker-compose.yml 不存在，从 addon 复制...${NC}"
    if [ -f "$ADDON_DIR/docker-compose.yml" ]; then
        cp "$ADDON_DIR/docker-compose.yml" "$TEMPLATE_DIR/docker-compose.yml"
        # 检查并转换 build: 为 image:
        if grep -q "build:" "$TEMPLATE_DIR/docker-compose.yml"; then
            echo -e "${YELLOW}警告: docker-compose.yml 包含 build:，需要手动改为 image:${NC}"
        fi
    else
        echo -e "${RED}错误: addon 中也没有 docker-compose.yml${NC}"
    fi
fi

# 复制其他可能需要的文件
echo -e "${GREEN}复制其他文件...${NC}"
for file in "icon.png" "CHANGELOG.md" "requirements.txt" "repository.json"; do
    if [ -f "$ADDON_DIR/$file" ]; then
        cp "$ADDON_DIR/$file" "$TEMPLATE_DIR/" 2>/dev/null && echo "  复制: $file" || true
    fi
done

# 确保 .tarignore 存在
if [ ! -f "$TEMPLATE_DIR/.tarignore" ]; then
    echo -e "${GREEN}创建 .tarignore...${NC}"
    cat > "$TEMPLATE_DIR/.tarignore" <<EOF
.git
__pycache__
*.pyc
*.log
.DS_Store
TEMPLATE_INFO.md
common/
EOF
else
    # 确保 common/ 目录被排除
    if ! grep -q "^common/$" "$TEMPLATE_DIR/.tarignore" 2>/dev/null; then
        echo "common/" >> "$TEMPLATE_DIR/.tarignore"
        echo "  添加: common/ 到 .tarignore"
    fi
fi

# 创建说明文件
cat > "$TEMPLATE_DIR/TEMPLATE_INFO.md" <<EOF
# Template 生成信息

此 template 由脚本自动生成自 addon: \`${ADDON_NAME}\`

生成时间: $(date '+%Y-%m-%d %H:%M:%S')
源版本: ${VERSION}
模板来源: \`addons/${ADDON_NAME}/template/\`

## 文件说明

- \`upload_config.json\`: 上传配置文件（**必需**），已从模板复制并更新版本号
- \`docker-compose.yml\`: Docker Compose 配置（**必需**），必须使用 image: 而不是 build:
- \`.tarignore\`: 打包时排除的文件列表
- \`DOCS.md\`: 使用说明文档（推荐），会显示在 Haddons Web 界面的"文档"标签页
- \`README.md\`: 核心能力说明文档（推荐），会显示在 Haddons Web 界面的 Addon 卡片中
- \`icon.png\`: 图标文件（推荐），显示在 Haddons Web 界面中

**注意**：
- 模板文件来自 \`addons/${ADDON_NAME}/template/\` 目录
- 如需修改模板内容，请编辑 \`addons/${ADDON_NAME}/template/\` 目录中的文件，然后重新运行生成脚本
- \`common/\` 目录**不需要**包含在 Template 中，因为 Template 必须使用已发布的镜像（\`image:\`），不需要构建文件

## 使用前检查清单

- [ ] 检查 \`upload_config.json\` 中的配置（版本号已自动更新为 ${VERSION}）
- [ ] 确认 \`docker-compose.yml\` 配置正确（使用 image: 而不是 build:）
- [ ] 确认 \`README.md\` 和 \`DOCS.md\` 内容完整
- [ ] 确认 \`icon.png\` 存在（如需要）
EOF

echo ""
echo -e "${GREEN}✓ Template 生成成功！${NC}"
echo ""
echo -e "${BLUE}输出目录: ${TEMPLATE_DIR}${NC}"
echo ""
echo -e "${BLUE}下一步:${NC}"
echo "  1. 检查 ${TEMPLATE_DIR}/upload_config.json"
echo "     - 确认版本号已更新为: ${VERSION}"
echo "     - 确认 addonid、visiturl 等字段正确"
echo "  2. 检查 ${TEMPLATE_DIR}/docker-compose.yml"
echo "     - 确保使用 image: 而不是 build:"
echo "     - 确认镜像地址和版本正确"
if [ ! -f "$TEMPLATE_DIR/icon.png" ]; then
    echo "  3. 添加 icon.png 文件到 ${TEMPLATE_DIR}"
    echo "     - 参考 templates/addon-template/template/ICON_REQUIREMENTS.md"
fi
echo "  4. 检查 ${TEMPLATE_DIR}/README.md 和 DOCS.md"
echo "     - 确保内容完整、用户友好"
echo "  5. 使用 upload_batch.py 上传到服务器"
echo ""
echo -e "${YELLOW}重要提示:${NC}"
echo "  - Template 文件已从 addons/$ADDON_NAME/template/ 复制"
echo "  - 如需修改模板内容，请编辑 addons/$ADDON_NAME/template/ 目录中的文件"
echo "  - 然后重新运行此脚本生成 template"
echo "  - Template 中的 docker-compose.yml 必须使用已发布的镜像（image:），不能使用 build:"
echo "  - 上传必需的文件只有：upload_config.json 和 docker-compose.yml"
echo ""
