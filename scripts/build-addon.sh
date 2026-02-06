#!/bin/bash

# 构建 addon 的脚本
# 使用方法: ./scripts/build-addon.sh <addon-name> [--arch <arch>] [--push]

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
    echo "  addon-name    - 要构建的 addon 名称"
    echo ""
    echo "选项:"
    echo "  --arch <arch>  - 指定架构 (amd64, aarch64, armv7) [默认: 全部]"
    echo "  --push         - 构建后推送到仓库"
    echo "  --help, -h     - 显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 linknlink-remote"
    echo "  $0 linknlink-remote --arch amd64"
    echo "  $0 linknlink-remote --arch amd64 --push"
}

# 检查参数
if [ $# -eq 0 ] || [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
    show_help
    exit 0
fi

ADDON_NAME="$1"
shift

ARCH=""
PUSH=false

# 解析选项
while [[ $# -gt 0 ]]; do
    case $1 in
        --arch)
            ARCH="$2"
            shift 2
            ;;
        --push)
            PUSH=true
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
ADDON_DIR="$ADDONS_DIR/$ADDON_NAME"

# 检查 addon 是否存在
if [ ! -d "$ADDON_DIR" ]; then
    echo -e "${RED}错误: Addon '$ADDON_NAME' 不存在${NC}"
    exit 1
fi

# 读取版本号
if [ ! -f "$ADDON_DIR/VERSION" ]; then
    echo -e "${RED}错误: 找不到 VERSION 文件${NC}"
    exit 1
fi

VERSION=$(cat "$ADDON_DIR/VERSION" | tr -d '[:space:]')
ADDON_SLUG="${ADDON_NAME//-/_}"
IMAGE_NAME="ghcr.io/linknlink/${ADDON_SLUG}"
IMAGE_TAG="${IMAGE_NAME}:${VERSION}"
IMAGE_LATEST="${IMAGE_NAME}:latest"

echo -e "${BLUE}构建 addon: ${ADDON_NAME}${NC}"
echo -e "${BLUE}版本: ${VERSION}${NC}"
echo ""

# 验证 addon 结构
echo -e "${GREEN}验证 addon 结构...${NC}"
"$SCRIPT_DIR/validate-addon.sh" "$ADDON_NAME" || {
    echo -e "${RED}验证失败，请先修复错误${NC}"
    exit 1
}

# 构建 Docker 镜像
BUILD_DIR="$ADDON_DIR/common"

if [ ! -f "$BUILD_DIR/Dockerfile" ]; then
    echo -e "${RED}错误: 找不到 Dockerfile${NC}"
    exit 1
fi

# 确定要构建的架构
ARCHES=()
if [ -n "$ARCH" ]; then
    ARCHES=("$ARCH")
else
    # 从 repository.json 读取支持的架构
    if [ -f "$ADDON_DIR/repository.json" ]; then
        ARCHES_JSON=$(jq -r '.arch[]?' "$ADDON_DIR/repository.json" 2>/dev/null || echo "")
        if [ -n "$ARCHES_JSON" ]; then
            while IFS= read -r arch; do
                ARCHES+=("$arch")
            done <<< "$ARCHES_JSON"
        fi
    fi
    
    # 如果没有指定，使用默认架构
    if [ ${#ARCHES[@]} -eq 0 ]; then
        ARCHES=("amd64" "aarch64" "armv7")
    fi
fi

echo -e "${GREEN}支持的架构: ${ARCHES[*]}${NC}"
echo ""

# 构建镜像
for arch in "${ARCHES[@]}"; do
    echo -e "${BLUE}构建架构: ${arch}${NC}"
    
    # 映射架构名称
    case "$arch" in
        amd64)
            DOCKER_ARCH="linux/amd64"
            ;;
        aarch64)
            DOCKER_ARCH="linux/arm64"
            ;;
        armv7)
            DOCKER_ARCH="linux/arm/v7"
            ;;
        *)
            echo -e "${YELLOW}警告: 未知架构 '$arch'，跳过${NC}"
            continue
            ;;
    esac
    
    # 构建命令
    BUILD_CMD="docker buildx build --platform $DOCKER_ARCH -t ${IMAGE_TAG} -t ${IMAGE_LATEST} $BUILD_DIR"
    
    if [ "$PUSH" = true ]; then
        BUILD_CMD="$BUILD_CMD --push"
    fi
    
    echo "执行: $BUILD_CMD"
    
    if eval "$BUILD_CMD"; then
        echo -e "${GREEN}✓ 架构 ${arch} 构建成功${NC}"
    else
        echo -e "${RED}✗ 架构 ${arch} 构建失败${NC}"
        exit 1
    fi
    
    echo ""
done

echo -e "${GREEN}✓ 构建完成！${NC}"
echo ""
echo "镜像:"
echo "  ${IMAGE_TAG}"
echo "  ${IMAGE_LATEST}"
echo ""

if [ "$PUSH" = false ]; then
    echo "提示: 使用 --push 选项可以推送到仓库"
fi
