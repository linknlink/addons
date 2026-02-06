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
    cp -r "$TEMPLATE_DIR"/* "$ADDONS_DIR/$ADDON_NAME/" 2>/dev/null || true
    # 替换模板变量
    find "$ADDONS_DIR/$ADDON_NAME" -type f -exec sed -i "s/{{ADDON_NAME}}/$ADDON_NAME/g" {} \;
    find "$ADDONS_DIR/$ADDON_NAME" -type f -exec sed -i "s/{{ADDON_SLUG}}/${ADDON_NAME//-/_}/g" {} \;
    
    # 如果模板中没有 config.json，创建一个
    if [ ! -f "$ADDONS_DIR/$ADDON_NAME/config.json" ]; then
        echo -e "${GREEN}创建 config.json（Haddons 必需）...${NC}"
        ADDON_SLUG="${ADDON_NAME//-/_}"
        VERSION="0.0.1"
        if [ -f "$ADDONS_DIR/$ADDON_NAME/VERSION" ]; then
            VERSION=$(cat "$ADDONS_DIR/$ADDON_NAME/VERSION" | tr -d '[:space:]')
        fi
        cat > "$ADDONS_DIR/$ADDON_NAME/config.json" <<EOF
{
  "name": "$(echo $ADDON_NAME | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++)sub(/./,toupper(substr(\$i,1,1)),\$i)}1')",
  "version": "${VERSION}",
  "slug": "${ADDON_SLUG}",
  "description": "Haddons Addon 描述，旨在为 Ubuntu Server 系统提供相关能力。",
  "arch": ["aarch64", "amd64", "armv7"],
  "startup": "services",
  "boot": "auto",
  "options": {},
  "schema": {}
}
EOF
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
        }
    else
        echo -e "${YELLOW}警告: 找不到 generate-template-from-addon.sh 脚本${NC}"
    fi
    echo ""
fi

echo "下一步:"
echo "  1. 编辑 $ADDONS_DIR/$ADDON_NAME/ 目录下的文件"
echo "  2. 配置 addon 的功能和设置"
echo "  3. 运行 ./scripts/validate-addon.sh $ADDON_NAME 验证结构"
echo "  4. 运行 ./scripts/build-addon.sh $ADDON_NAME 测试构建"
if [ "$GENERATE_TEMPLATE" != true ]; then
    echo "  5. 运行 ./scripts/generate-template-from-addon.sh $ADDON_NAME 生成上传用的 template"
fi
echo ""
