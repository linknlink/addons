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

# 创建输出目录
mkdir -p "$TEMPLATE_DIR"
echo -e "${GREEN}创建输出目录: ${TEMPLATE_DIR}${NC}"

# 读取 addon 信息
VERSION="0.0.1"
if [ -f "$ADDON_DIR/VERSION" ]; then
    VERSION=$(cat "$ADDON_DIR/VERSION" | tr -d '[:space:]')
fi

# 读取 config.json（优先）或 repository.json
ADDON_DISPLAY_NAME="$ADDON_NAME"
ADDON_DESCRIPTION=""
ADDON_ID="$ADDON_NAME"
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

# 复制并处理 docker-compose.yml（如果存在）
if [ -f "$ADDON_DIR/docker-compose.yml" ]; then
    echo -e "${GREEN}处理 docker-compose.yml...${NC}"
    cp "$ADDON_DIR/docker-compose.yml" "$TEMPLATE_DIR/docker-compose.yml"
    
    # 检查并转换 build: 为 image:（template 必须使用已发布的镜像）
    if grep -q "build:" "$TEMPLATE_DIR/docker-compose.yml"; then
        echo -e "${YELLOW}警告: docker-compose.yml 包含 build:，需要手动改为 image:${NC}"
        echo "  请编辑 $TEMPLATE_DIR/docker-compose.yml，将 build: 改为 image: <镜像名称>:<版本>"
        # 尝试自动转换（基于 slug）
        if command -v sed &> /dev/null; then
            # 注释掉 build 部分，添加 image 行（需要手动确认）
            sed -i 's/^\([[:space:]]*\)build:/\1# build: (已注释，请改为 image:)/' "$TEMPLATE_DIR/docker-compose.yml" 2>/dev/null || true
            # 在服务定义后添加 image（如果还没有）
            if ! grep -q "image:" "$TEMPLATE_DIR/docker-compose.yml"; then
                sed -i "/container_name:/a\\    image: ghcr.io/linknlink/${ADDON_SLUG}:latest  # 请修改为实际镜像" "$TEMPLATE_DIR/docker-compose.yml" 2>/dev/null || true
            fi
        fi
    fi
else
    echo -e "${YELLOW}警告: docker-compose.yml 不存在，创建默认文件...${NC}"
    cat > "$TEMPLATE_DIR/docker-compose.yml" <<EOF
services:
  ${ADDON_SLUG}:
    image: ghcr.io/linknlink/${ADDON_SLUG}:latest  # 请修改为实际镜像
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

# 生成 .tarignore（使用模板参考文件，如果存在）
if [ -f "$TEMPLATE_REF_DIR/.tarignore" ]; then
    echo -e "${GREEN}复制 .tarignore 模板...${NC}"
    cp "$TEMPLATE_REF_DIR/.tarignore" "$TEMPLATE_DIR/.tarignore"
else
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
fi

# 生成 README.md（使用模板，描述 addon 的核心能力，面向用户）
echo -e "${GREEN}生成 README.md（核心能力说明，面向用户）...${NC}"
if [ -f "$TEMPLATE_REF_DIR/README.md" ]; then
    # 使用模板格式，替换变量
    sed "s/{{ADDON_NAME}}/${ADDON_DISPLAY_NAME}/g" "$TEMPLATE_REF_DIR/README.md" | \
    sed "s/{{ADDON_SLUG}}/${ADDON_SLUG}/g" > "$TEMPLATE_DIR/README.md"
    
    # 如果 addon 的 README.md 存在，尝试提取核心能力信息（从开发者文档中提取用户关心的内容）
    if [ -f "$ADDON_DIR/README.md" ]; then
        # 提取概述部分（从"## 概述"部分提取第一段）
        OVERVIEW=$(awk '/^## 概述$/,/^## / {if (/^## / && !/^## 概述$/) exit; if (!/^## / && !/^$/) print}' "$ADDON_DIR/README.md" 2>/dev/null | head -n 3 | tr '\n' ' ' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        if [ -n "$OVERVIEW" ] && [ ${#OVERVIEW} -gt 20 ]; then
            # 替换模板中的概述部分（移除技术实现细节，保留用户关心的内容）
            OVERVIEW_CLEAN=$(echo "$OVERVIEW" | sed 's/技术实现//g' | sed 's/设计目标//g' | sed 's/面向开发者//g' | sed 's/用于了解.*实现方式//g')
            sed -i "s|简要描述 Addon 的核心能力和主要用途。|${OVERVIEW_CLEAN}|" "$TEMPLATE_DIR/README.md" 2>/dev/null || true
        fi
        
        # 提取主要功能部分（从开发者文档中提取，转换为用户友好的格式）
        FEATURES=$(awk '/^## 主要功能$/,/^## / {if (/^## / && !/^## 主要功能$/) exit; if (!/^## / && !/^$/ && /^-/) print}' "$ADDON_DIR/README.md" 2>/dev/null | head -n 6)
        if [ -n "$FEATURES" ]; then
            # 清理功能描述，移除技术细节
            FEATURES_CLEAN=$(echo "$FEATURES" | sed 's/\*\*[^*]*\*\*：//g' | sed 's/及其实现方式//g' | sed 's/详细描述//g')
            # 在"主要功能"部分后插入提取的功能（如果模板中还没有功能列表）
            if ! grep -q "✅\|功能" "$TEMPLATE_DIR/README.md" 2>/dev/null; then
                sed -i "/^## 主要功能$/a\\${FEATURES_CLEAN}" "$TEMPLATE_DIR/README.md" 2>/dev/null || true
            fi
        fi
    fi
    echo "  ✓ 从模板生成 README.md（用户文档）"
else
    # 如果没有模板，从 addon 的 README.md 复制或创建默认文件
    if [ -f "$ADDON_DIR/README.md" ]; then
        echo -e "${GREEN}复制 README.md...${NC}"
        cp "$ADDON_DIR/README.md" "$TEMPLATE_DIR/README.md"
    else
        echo -e "${YELLOW}警告: README.md 模板不存在，创建默认文件...${NC}"
        cat > "$TEMPLATE_DIR/README.md" <<EOF
# ${ADDON_DISPLAY_NAME}

${ADDON_DESCRIPTION}

## 概述

简要描述 Addon 的核心能力和主要用途。

## 核心能力

- **能力特性 1**：简要描述该能力的作用和价值
- **能力特性 2**：简要描述该能力的作用和价值

## 主要功能

- ✅ 功能 1：详细描述功能
- ✅ 功能 2：详细描述功能

## 许可证

MIT
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

# 生成 DOCS.md 使用说明文档（生产环境，ToC 产品用户）
echo -e "${GREEN}生成 DOCS.md 使用说明文档（生产环境）...${NC}"
if [ -f "$TEMPLATE_REF_DIR/DOCS.md" ]; then
    # 使用模板格式，替换变量（DOCS.md 面向生产环境用户，使用标准化的格式）
    sed "s/{{ADDON_NAME}}/${ADDON_DISPLAY_NAME}/g" "$TEMPLATE_REF_DIR/DOCS.md" | \
    sed "s/{{ADDON_SLUG}}/${ADDON_SLUG}/g" > "$TEMPLATE_DIR/DOCS.md"
    
    # 如果 addon 有 config.json 的 schema，提取配置选项信息
    if [ -f "$ADDON_DIR/config.json" ] && command -v jq &> /dev/null; then
        SCHEMA=$(jq -r '.schema // {}' "$ADDON_DIR/config.json" 2>/dev/null)
        OPTIONS=$(jq -r '.options // {}' "$ADDON_DIR/config.json" 2>/dev/null)
        
        if [ "$SCHEMA" != "{}" ] && [ -n "$SCHEMA" ]; then
            # 提取配置选项并添加到 DOCS.md
            echo ""
            echo -e "${GREEN}提取配置选项信息...${NC}"
            # 这里可以进一步处理，将配置选项添加到 DOCS.md 的配置说明部分
            # 由于格式复杂，建议手动完善 DOCS.md
        fi
    fi
    
    echo "  ✓ 从模板生成 DOCS.md（生产环境使用说明）"
    echo "  ⚠ 请检查并完善 DOCS.md 中的配置选项说明和使用场景"
else
    # 如果没有模板，创建基本的 DOCS.md
    cat > "$TEMPLATE_DIR/DOCS.md" <<EOF
# ${ADDON_DISPLAY_NAME} 使用说明

本文档详细介绍如何在生产环境中使用 ${ADDON_DISPLAY_NAME} Addon。此文档会显示在 Haddons Web 界面的"文档"标签页中，面向最终用户（ToC 产品用户）。

## 快速开始

### 安装和启动

1. 在 Haddons Web 界面中找到 ${ADDON_DISPLAY_NAME}
2. 点击"安装"按钮安装 Addon
3. 安装完成后，在"配置"标签页中配置必要的选项（如需要）
4. 点击"保存"保存配置
5. 点击"启动"按钮启动 Addon

## 配置说明

在 Haddons Web 界面的"配置"标签页中，您可以配置相关选项。

## 注意事项

- 确保系统满足 Addon 的运行要求
- 检查必要的资源是否可用
- 确认网络连接正常（如需要）

## 许可证

MIT
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
echo -e "${BLUE}输出目录: ${TEMPLATE_DIR}${NC}"
echo ""
echo -e "${BLUE}下一步:${NC}"
echo "  1. 检查并修改 ${TEMPLATE_DIR}/upload_config.json"
echo "     - 确认 addonid、visiturl 等字段正确"
echo "  2. 检查并修改 ${TEMPLATE_DIR}/docker-compose.yml"
echo "     - 确保使用 image: 而不是 build:"
echo "     - 确认镜像地址和版本正确"
if [ ! -f "$TEMPLATE_DIR/icon.png" ]; then
    echo "  3. 添加 icon.png 文件到 ${TEMPLATE_DIR}"
    echo "     - 参考 templates/addon-template/ICON_REQUIREMENTS.md"
fi
echo "  4. 检查并完善 ${TEMPLATE_DIR}/README.md（用户核心能力说明）"
echo "     - 确保概述和功能描述清晰、用户友好"
echo "  5. 检查并完善 ${TEMPLATE_DIR}/DOCS.md（生产环境使用说明）"
echo "     - 补充配置选项的详细说明"
echo "     - 添加实际使用场景和示例"
echo "     - 完善故障排查指南"
echo "  6. 检查 common/ 和其他目录中的文件"
echo "  7. 使用 upload_batch.py 上传到服务器"
echo ""
echo -e "${YELLOW}重要提示:${NC}"
echo "  - Template 中的 docker-compose.yml 必须使用已发布的镜像（image:），不能使用 build:"
echo "  - README.md 是用户文档，描述核心能力，会显示在 Haddons Web 界面的 Addon 卡片中"
echo "  - DOCS.md 是详细使用说明，会显示在 Haddons Web 界面的"文档"标签页中"
echo "  - 如果 docker-compose.yml 包含 build:，请手动修改为 image: <镜像名称>:<版本>"
echo ""
