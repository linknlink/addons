#!/bin/bash

# 添加新 addon 到仓库的脚本
# 使用方法: ./scripts/add-addon.sh <addon-name> [--from-template]

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
    echo "  --from-template  - 从模板创建 addon（默认行为）"
    echo "  --help, -h       - 显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 my-new-addon"
    echo "  $0 linknlink-remote"
}

# 检查参数
if [ $# -eq 0 ] || [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
    show_help
    exit 0
fi

ADDON_NAME="$1"
USE_TEMPLATE=true

# 解析选项
shift
while [[ $# -gt 0 ]]; do
    case $1 in
        --from-template)
            USE_TEMPLATE=true
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
else
    # 创建基本文件
    echo -e "${GREEN}创建基本文件...${NC}"
    
    # VERSION
    echo "0.0.1" > "$ADDONS_DIR/$ADDON_NAME/VERSION"

    # README.md
    cat > "$ADDONS_DIR/$ADDON_NAME/README.md" <<EOF
# ${ADDON_NAME}

Docker 容器应用描述，旨在为 Ubuntu Server 系统提供相关能力。

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
fi

echo ""
echo -e "${GREEN}✓ Addon '$ADDON_NAME' 创建成功！${NC}"
echo ""
echo "下一步:"
echo "  1. 编辑 $ADDONS_DIR/$ADDON_NAME/ 目录下的文件"
echo "  2. 配置 addon 的功能和设置"
echo "  3. 运行 ./scripts/validate-addon.sh $ADDON_NAME 验证结构"
echo "  4. 运行 ./scripts/build-addon.sh $ADDON_NAME 测试构建"
echo ""
