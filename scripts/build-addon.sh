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

# 检查并设置 Docker buildx
setup_buildx() {
    local current_arch=$(uname -m)
    local needs_multiarch=false
    
    # 检查是否需要多架构支持
    for arch in "${ARCHES[@]}"; do
        case "$arch" in
            aarch64|armv7)
                # 如果当前架构不是 ARM，则需要多架构支持
                case "$current_arch" in
                    x86_64|amd64)
                        needs_multiarch=true
                        break
                        ;;
                esac
                ;;
        esac
    done
    
    if [ "$needs_multiarch" = true ]; then
        echo -e "${YELLOW}检测到需要跨架构构建，正在设置 buildx 和 QEMU...${NC}"
        
        # 首先安装 QEMU 模拟器
        echo -e "${GREEN}安装 QEMU 模拟器...${NC}"
        if docker run --rm --privileged multiarch/qemu-user-static --reset -p yes 2>/dev/null; then
            echo -e "${GREEN}✓ QEMU 安装成功${NC}"
        else
            echo -e "${RED}✗ QEMU 安装失败，多架构构建可能不可用${NC}"
            echo -e "${YELLOW}提示: 可以只构建当前架构 (--arch amd64)${NC}"
            return 1
        fi
        
        # 检查并创建 buildx builder
        if ! docker buildx ls 2>/dev/null | grep -q "multiarch"; then
            echo -e "${GREEN}创建多架构 builder...${NC}"
            if docker buildx create --name multiarch --driver docker-container --use 2>/dev/null; then
                echo -e "${GREEN}✓ 多架构 builder 创建成功${NC}"
            else
                echo -e "${YELLOW}警告: 无法创建多架构 builder，将使用默认 builder${NC}"
            fi
        else
            echo -e "${GREEN}使用现有的多架构 builder...${NC}"
            docker buildx use multiarch 2>/dev/null || true
        fi
        
        # 验证 buildx 是否支持多架构
        if docker buildx inspect --bootstrap 2>/dev/null | grep -q "linux/arm"; then
            echo -e "${GREEN}✓ Buildx 多架构支持已就绪${NC}"
        else
            echo -e "${YELLOW}警告: Buildx 可能不支持多架构，构建可能失败${NC}"
        fi
    else
        echo -e "${GREEN}当前架构匹配，无需多架构支持${NC}"
    fi
}

# 设置 buildx
setup_buildx

# 构建镜像
# 构建镜像
PLATFORMS=""
for arch in "${ARCHES[@]}"; do
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
    
    if [ -z "$PLATFORMS" ]; then
        PLATFORMS="$DOCKER_ARCH"
    else
        PLATFORMS="$PLATFORMS,$DOCKER_ARCH"
    fi
done

if [ -z "$PLATFORMS" ]; then
    echo -e "${RED}错误: 没有有效的构建架构${NC}"
    exit 1
fi

echo -e "${BLUE}构建目标平台: ${PLATFORMS}${NC}"

# 构建命令
BUILD_CMD="docker buildx build --platform $PLATFORMS -t ${IMAGE_TAG} -t ${IMAGE_LATEST} $BUILD_DIR"

if [ "$PUSH" = true ]; then
    BUILD_CMD="$BUILD_CMD --push"
    echo "执行 (Push): $BUILD_CMD"
    
    if eval "$BUILD_CMD"; then
        echo -e "${GREEN}✓ 多架构镜像构建并推送成功${NC}"
        echo -e "${GREEN}  Tag: ${IMAGE_TAG}${NC}"
        echo -e "${GREEN}  Tag: ${IMAGE_LATEST}${NC}"
    else
        echo -e "${RED}✗ 构建或推送失败${NC}"
        exit 1
    fi
else
    # 本地构建 (非 Push 模式)
    # 注意: docker buildx build --load 不支持多平台
    # 所以如果没有 --push，通过 --load 只能构建当前架构
    
    CURRENT_ARCH=$(uname -m)
    TARGET_PLATFORM=""
    
    echo -e "${YELLOW}提示: 未启用 --push，仅构建当前架构并加载到本地${NC}"
    
    case "$CURRENT_ARCH" in
        x86_64|amd64)
            if [[ "$PLATFORMS" == *"linux/amd64"* ]]; then
                TARGET_PLATFORM="linux/amd64"
            fi
            ;;
        aarch64|arm64)
            if [[ "$PLATFORMS" == *"linux/arm64"* ]]; then
                TARGET_PLATFORM="linux/arm64"
            fi
            ;;
        armv7l|armv7)
            if [[ "$PLATFORMS" == *"linux/arm/v7"* ]]; then
                TARGET_PLATFORM="linux/arm/v7"
            fi
            ;;
    esac
    
    if [ -n "$TARGET_PLATFORM" ]; then
        # 仅构建当前架构
        local_build_cmd="docker buildx build --platform $TARGET_PLATFORM -t ${IMAGE_TAG} -t ${IMAGE_LATEST} --load $BUILD_DIR"
        echo "执行 (Local): $local_build_cmd"
        
        if eval "$local_build_cmd"; then
            echo -e "${GREEN}✓ 本地架构 ($TARGET_PLATFORM) 构建成功${NC}"
            echo -e "${GREEN}  已加载镜像: ${IMAGE_TAG}${NC}"
        else
            echo -e "${RED}✗ 本地构建失败${NC}"
            exit 1
        fi
    else
        echo -e "${RED}错误: 当前系统架构 ($CURRENT_ARCH) 不在支持的目标列表内，无法进行本地构建${NC}"
        echo -e "${YELLOW}支持的列表: $PLATFORMS${NC}"
        echo -e "${YELLOW}请使用 --push 参数进行跨平台构建并推送到仓库${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}✓ 构建完成！${NC}"
echo ""
echo "镜像:"
echo "  ${IMAGE_TAG}"
echo "  ${IMAGE_LATEST}"
echo ""

if [ "$PUSH" = false ]; then
    echo "提示: 使用 --push 选项可以推送到仓库"
fi
