#!/bin/bash

# 添加新 addon 到仓库的脚本
# 使用方法: ./scripts/add-addon.sh <addon-name> [--from-template] [--generate-template]

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
    echo "  addon-name    - Addon 名称（使用连字符，如: my-addon）"
    echo ""
    echo "选项:"
    echo "  --from-template      - 从模板创建 addon（默认行为）"
    echo "  --generate-template  - 创建 addon 后生成上传用的 template"
    echo "  --help, -h           - 显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 my-new-addon"
    echo "  $0 my-new-addon --generate-template"
    echo "  $0 linknlink-remote"
}

# 检查参数
if [ $# -eq 0 ] || [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
    show_help
    exit 0
fi

ADDON_NAME="$1"
USE_TEMPLATE=true
GENERATE_TEMPLATE=false

# 解析选项
shift
while [[ $# -gt 0 ]]; do
    case $1 in
        --from-template)
            USE_TEMPLATE=true
            shift
            ;;
        --generate-template)
            GENERATE_TEMPLATE=true
            shift
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
TEMPLATE_DIR="$PROJECT_ROOT/templates/addon-template"

# 验证 addon 名称
if [[ ! "$ADDON_NAME" =~ ^[a-z0-9-]+$ ]]; then
    echo -e "${RED}错误: Addon 名称只能包含小写字母、数字和连字符${NC}"
    exit 1
fi

# 检查 addon 是否已存在
if [ -d "$ADDONS_DIR/$ADDON_NAME" ]; then
    echo -e "${RED}错误: Addon '$ADDON_NAME' 已存在${NC}"
    exit 1
fi

echo -e "${BLUE}正在创建 addon: ${ADDON_NAME}${NC}"
echo ""

# 创建 addon 目录
echo -e "${GREEN}创建目录结构...${NC}"
mkdir -p "$ADDONS_DIR/$ADDON_NAME"
mkdir -p "$ADDONS_DIR/$ADDON_NAME/common/rootfs/app"
mkdir -p "$ADDONS_DIR/$ADDON_NAME/common/rootfs/runtime/data"
mkdir -p "$ADDONS_DIR/$ADDON_NAME/common/rootfs/runtime/etc"
mkdir -p "$ADDONS_DIR/$ADDON_NAME/scripts"

# 从模板创建文件
if [ "$USE_TEMPLATE" = true ] && [ -d "$TEMPLATE_DIR" ]; then
    echo -e "${GREEN}从模板复制文件...${NC}"
    
    # 复制模板文件（排除 template/ 目录，因为它需要单独处理）
    rsync -av --exclude='template/' "$TEMPLATE_DIR/" "$ADDONS_DIR/$ADDON_NAME/" 2>/dev/null || {
        # 如果 rsync 不可用，使用 cp 并手动排除
        cp -r "$TEMPLATE_DIR"/* "$ADDONS_DIR/$ADDON_NAME/" 2>/dev/null || true
        rm -rf "$ADDONS_DIR/$ADDON_NAME/template" 2>/dev/null || true
    }
    
    # 复制 template/ 目录到 addon 的 template/ 目录（用于生成上传用的 template）
    if [ -d "$TEMPLATE_DIR/template" ]; then
        echo -e "${GREEN}复制 template 模板文件...${NC}"
        mkdir -p "$ADDONS_DIR/$ADDON_NAME/template"
        cp -r "$TEMPLATE_DIR/template"/* "$ADDONS_DIR/$ADDON_NAME/template/" 2>/dev/null || true
        echo "  ✓ 已创建 $ADDONS_DIR/$ADDON_NAME/template/ 目录"
        echo "  ⚠ 请编辑 template/ 目录中的文件，填充实际的模板内容"
    fi
    
    # 替换模板变量
    ADDON_SLUG="${ADDON_NAME//-/_}"
    ADDON_DISPLAY_NAME=$(echo "$ADDON_NAME" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++)sub(/./,toupper(substr($i,1,1)),$i)}1')
    
    echo -e "${GREEN}替换模板变量...${NC}"
    echo "  ADDON_NAME: ${ADDON_DISPLAY_NAME}"
    echo "  ADDON_SLUG: ${ADDON_SLUG}"
    
    # 替换所有模板文件中的变量（排除二进制文件和 template/ 目录）
    find "$ADDONS_DIR/$ADDON_NAME" -type f -not -path "*/template/*" \( \
        -name "*.md" -o \
        -name "*.json" -o \
        -name "*.yml" -o \
        -name "*.yaml" -o \
        -name "*.sh" -o \
        -name "Dockerfile" -o \
        -name "VERSION" \
    \) -exec sed -i "s/{{ADDON_NAME}}/$ADDON_DISPLAY_NAME/g" {} \; 2>/dev/null || true
    
    find "$ADDONS_DIR/$ADDON_NAME" -type f -not -path "*/template/*" \( \
        -name "*.md" -o \
        -name "*.json" -o \
        -name "*.yml" -o \
        -name "*.yaml" -o \
        -name "*.sh" -o \
        -name "Dockerfile" -o \
        -name "VERSION" \
    \) -exec sed -i "s/{{ADDON_SLUG}}/$ADDON_SLUG/g" {} \; 2>/dev/null || true
    
    # 替换 template/ 目录中的变量
    if [ -d "$ADDONS_DIR/$ADDON_NAME/template" ]; then
        find "$ADDONS_DIR/$ADDON_NAME/template" -type f \( \
            -name "*.md" -o \
            -name "*.json" -o \
            -name "*.yml" -o \
            -name "*.yaml" \
        \) -exec sed -i "s/{{ADDON_NAME}}/$ADDON_DISPLAY_NAME/g" {} \; 2>/dev/null || true
        
        find "$ADDONS_DIR/$ADDON_NAME/template" -type f \( \
            -name "*.md" -o \
            -name "*.json" -o \
            -name "*.yml" -o \
            -name "*.yaml" \
        \) -exec sed -i "s/{{ADDON_SLUG}}/$ADDON_SLUG/g" {} \; 2>/dev/null || true
    fi
    
    # 确保 config.json 存在且格式正确
    if [ ! -f "$ADDONS_DIR/$ADDON_NAME/config.json" ]; then
        echo -e "${GREEN}创建 config.json（Haddons 必需）...${NC}"
        VERSION="0.0.1"
        if [ -f "$ADDONS_DIR/$ADDON_NAME/VERSION" ]; then
            VERSION=$(cat "$ADDONS_DIR/$ADDON_NAME/VERSION" | tr -d '[:space:]')
        fi
        cat > "$ADDONS_DIR/$ADDON_NAME/config.json" <<EOF
{
  "name": "${ADDON_DISPLAY_NAME}",
  "version": "${VERSION}",
  "slug": "${ADDON_SLUG}",
  "description": "${ADDON_DISPLAY_NAME} 旨在为 Ubuntu Server 系统提供相关能力。",
  "arch": ["aarch64", "amd64", "armv7"],
  "startup": "services",
  "boot": "auto",
  "options": {},
  "schema": {}
}
EOF
    else
        echo -e "${GREEN}检查 config.json...${NC}"
        # 验证 JSON 格式
        if command -v jq &> /dev/null; then
            if jq empty "$ADDONS_DIR/$ADDON_NAME/config.json" 2>/dev/null; then
                echo "  ✓ config.json 格式正确"
            else
                echo -e "${YELLOW}  ⚠ config.json 格式可能有问题，请检查${NC}"
            fi
        fi
    fi
    
    # 确保 docker-entrypoint.sh 有执行权限
    if [ -f "$ADDONS_DIR/$ADDON_NAME/common/rootfs/app/docker-entrypoint.sh" ]; then
        chmod +x "$ADDONS_DIR/$ADDON_NAME/common/rootfs/app/docker-entrypoint.sh"
    fi
else
    # 创建基本文件
    echo -e "${GREEN}创建基本文件...${NC}"
    
    # VERSION
    echo "0.0.1" > "$ADDONS_DIR/$ADDON_NAME/VERSION"
    
    # config.json（Haddons 必需）
    ADDON_SLUG="${ADDON_NAME//-/_}"
    cat > "$ADDONS_DIR/$ADDON_NAME/config.json" <<EOF
{
  "name": "$(echo $ADDON_NAME | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++)sub(/./,toupper(substr(\$i,1,1)),\$i)}1')",
  "version": "0.0.1",
  "slug": "${ADDON_SLUG}",
  "description": "Haddons Addon 描述，旨在为 Ubuntu Server 系统提供相关能力。",
  "arch": ["aarch64", "amd64", "armv7"],
  "startup": "services",
  "boot": "auto",
  "options": {},
  "schema": {}
}
EOF

    # README.md
    cat > "$ADDONS_DIR/$ADDON_NAME/README.md" <<EOF
# ${ADDON_NAME}

Haddons Addon 描述，旨在为 Ubuntu Server 系统提供相关能力。

## 功能

- 功能 1
- 功能 2

## 配置

配置说明

## 使用

使用说明

## 许可证

MIT
EOF

    # 基本 Dockerfile
    cat > "$ADDONS_DIR/$ADDON_NAME/common/Dockerfile" <<EOF
ARG BUILD_FROM=alpine:latest
FROM \${BUILD_FROM}

ENV LANG C.UTF-8

# 安装依赖
RUN apk add --no-cache \\
    bash \\
    curl \\
    ca-certificates

# 复制应用文件
COPY rootfs /

# 设置工作目录
WORKDIR /app

# 运行脚本
ENTRYPOINT [ "/bin/bash", "/app/docker-entrypoint.sh" ]
EOF

    # docker-entrypoint.sh
    ADDON_SLUG="${ADDON_NAME//-/_}"
    cat > "$ADDONS_DIR/$ADDON_NAME/common/rootfs/app/docker-entrypoint.sh" <<EOF
#!/bin/bash
set -e

echo "Starting ${ADDON_NAME}..."

# 在这里添加启动逻辑

exec "\$@"
EOF
    chmod +x "$ADDONS_DIR/$ADDON_NAME/common/rootfs/app/docker-entrypoint.sh"
    
    # docker-compose.yml（Haddons 必需）
    cat > "$ADDONS_DIR/$ADDON_NAME/docker-compose.yml" <<EOF
services:
  ${ADDON_SLUG}:
    image: ghcr.io/linknlink/${ADDON_SLUG}:latest
    container_name: ${ADDON_SLUG}
    restart: unless-stopped
    environment:
      - ENV_VAR=value
EOF
fi

echo ""
echo -e "${GREEN}✓ Addon '$ADDON_NAME' 创建成功！${NC}"
echo ""

# 如果指定了生成 template，则调用生成脚本
if [ "$GENERATE_TEMPLATE" = true ]; then
    echo -e "${BLUE}正在生成上传用的 template...${NC}"
    GENERATE_SCRIPT="$SCRIPT_DIR/generate-template-from-addon.sh"
    if [ -f "$GENERATE_SCRIPT" ]; then
        "$GENERATE_SCRIPT" "$ADDON_NAME" || {
            echo -e "${YELLOW}警告: Template 生成失败，但 addon 已创建${NC}"
            echo "  可以稍后运行: ./scripts/generate-template-from-addon.sh $ADDON_NAME"
        }
    else
        echo -e "${YELLOW}警告: 找不到 generate-template-from-addon.sh 脚本${NC}"
    fi
    echo ""
fi

echo -e "${BLUE}下一步:${NC}"
echo "  1. 编辑 $ADDONS_DIR/$ADDON_NAME/README.md - 描述 addon 的功能和技术架构"
echo "  2. 编辑 $ADDONS_DIR/$ADDON_NAME/config.json - 配置 addon 的元数据和选项"
echo "  3. 编辑 $ADDONS_DIR/$ADDON_NAME/common/Dockerfile - 配置 Docker 构建"
echo "  4. 编辑 $ADDONS_DIR/$ADDON_NAME/common/rootfs/app/ - 添加应用代码"
if [ -d "$ADDONS_DIR/$ADDON_NAME/template" ]; then
    echo "  5. 编辑 $ADDONS_DIR/$ADDON_NAME/template/ - 填充上传用的模板内容"
    echo "     - README.md: 用户核心能力说明（会显示在 Addon 卡片中）"
    echo "     - DOCS.md: 详细使用说明（会显示在文档标签页）"
    echo "     - upload_config.json: 上传配置"
fi
echo "  6. 运行 ./scripts/validate-addon.sh $ADDON_NAME 验证结构"
echo "  7. 运行 ./scripts/build-addon.sh $ADDON_NAME 测试构建"
if [ "$GENERATE_TEMPLATE" != true ]; then
    echo "  8. 运行 ./scripts/generate-template-from-addon.sh $ADDON_NAME 生成上传用的 template"
fi
echo ""
echo -e "${YELLOW}提示:${NC}"
echo "  - README.md 是 addon 级文档，面向开发者，描述技术实现"
if [ -d "$ADDONS_DIR/$ADDON_NAME/template" ]; then
    echo "  - template/ 目录包含上传用的模板文件，需要手动编辑填充实际内容"
    echo "  - 可以使用 AI 辅助生成 template/ 目录中的内容"
fi
echo ""