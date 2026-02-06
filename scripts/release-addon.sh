#!/bin/bash

# 发布 addon 的脚本
# 使用方法: ./scripts/release-addon.sh <addon-name> [patch|minor|major] [--commit] [--push]

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 显示帮助信息
show_help() {
    echo "使用方法: $0 <addon-name> [版本类型] [选项]"
    echo ""
    echo "参数:"
    echo "  addon-name    - 要发布的 addon 名称"
    echo ""
    echo "版本类型:"
    echo "  patch  - 递增补丁版本 (1.0.1 -> 1.0.2) [默认]"
    echo "  minor  - 递增次版本 (1.0.1 -> 1.1.0)"
    echo "  major  - 递增主版本 (1.0.1 -> 2.0.0)"
    echo "  或直接指定版本号，如: 1.0.2"
    echo ""
    echo "选项:"
    echo "  --commit    - 提交更改到 git"
    echo "  --push      - 推送到远程仓库（包括 tag）"
    echo "  --help, -h  - 显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 linknlink-remote patch"
    echo "  $0 linknlink-remote patch --commit --push"
    echo "  $0 linknlink-remote 1.0.5 --commit --push"
}

# 检查参数
if [ $# -eq 0 ] || [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
    show_help
    exit 0
fi

ADDON_NAME="$1"
shift

VERSION_TYPE="patch"
COMMIT=false
PUSH=false

# 解析参数
while [[ $# -gt 0 ]]; do
    case $1 in
        patch|minor|major)
            VERSION_TYPE="$1"
            shift
            ;;
        --commit)
            COMMIT=true
            shift
            ;;
        --push)
            PUSH=true
            shift
            ;;
        *)
            # 检查是否是版本号格式
            if [[ "$1" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
                NEW_VERSION="$1"
                VERSION_TYPE="custom"
            else
                echo -e "${RED}错误: 未知参数 '$1'${NC}"
                show_help
                exit 1
            fi
            shift
            ;;
    esac
done

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ADDONS_DIR="$PROJECT_ROOT/addons"
ADDON_DIR="$ADDONS_DIR/$ADDON_NAME"
VERSION_FILE="$ADDON_DIR/VERSION"

# 检查 addon 是否存在
if [ ! -d "$ADDON_DIR" ]; then
    echo -e "${RED}错误: Addon '$ADDON_NAME' 不存在${NC}"
    exit 1
fi

# 检查 VERSION 文件
if [ ! -f "$VERSION_FILE" ]; then
    echo "0.0.0" > "$VERSION_FILE"
    echo -e "${YELLOW}警告: 找不到 VERSION 文件，已创建初始版本 0.0.0${NC}"
fi

# 读取当前版本
CURRENT_VERSION=$(cat "$VERSION_FILE" | tr -d '[:space:]')
echo -e "${GREEN}当前版本: ${CURRENT_VERSION}${NC}"

# 计算新版本
if [ "$VERSION_TYPE" = "custom" ]; then
    NEW_VERSION="$NEW_VERSION"
elif [ "$VERSION_TYPE" = "patch" ]; then
    # 递增补丁版本: 1.0.1 -> 1.0.2
    IFS='.' read -ra VERSION_PARTS <<< "$CURRENT_VERSION"
    MAJOR=${VERSION_PARTS[0]}
    MINOR=${VERSION_PARTS[1]}
    PATCH=${VERSION_PARTS[2]}
    NEW_VERSION="${MAJOR}.${MINOR}.$((PATCH + 1))"
elif [ "$VERSION_TYPE" = "minor" ]; then
    # 递增次版本: 1.0.1 -> 1.1.0
    IFS='.' read -ra VERSION_PARTS <<< "$CURRENT_VERSION"
    MAJOR=${VERSION_PARTS[0]}
    MINOR=${VERSION_PARTS[1]}
    NEW_VERSION="${MAJOR}.$((MINOR + 1)).0"
elif [ "$VERSION_TYPE" = "major" ]; then
    # 递增主版本: 1.0.1 -> 2.0.0
    IFS='.' read -ra VERSION_PARTS <<< "$CURRENT_VERSION"
    MAJOR=${VERSION_PARTS[0]}
    NEW_VERSION="$((MAJOR + 1)).0.0"
else
    echo -e "${RED}错误: 未知的版本类型 '$VERSION_TYPE'${NC}"
    exit 1
fi

# 检查版本是否有效
if [ "$NEW_VERSION" = "$CURRENT_VERSION" ]; then
    echo -e "${YELLOW}警告: 新版本与当前版本相同${NC}"
    exit 1
fi

# 检查版本是否已经存在 tag
TAG_NAME="${ADDON_NAME}-v${NEW_VERSION}"
if git tag -l | grep -q "^${TAG_NAME}$"; then
    echo -e "${RED}错误: 版本 tag ${TAG_NAME} 已经存在${NC}"
    echo "请使用不同的版本号"
    exit 1
fi

echo -e "${GREEN}新版本: ${NEW_VERSION}${NC}"
echo ""

# 确认
read -p "确认更新版本号并继续? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "已取消"
    exit 0
fi

# 更新 VERSION 文件
echo -e "${GREEN}更新 VERSION 文件...${NC}"
echo "$NEW_VERSION" > "$VERSION_FILE"

# 验证更新
UPDATED_VERSION=$(cat "$VERSION_FILE" | tr -d '[:space:]')
if [ "$UPDATED_VERSION" != "$NEW_VERSION" ]; then
    echo -e "${RED}错误: 版本更新失败${NC}"
    exit 1
fi

echo -e "${GREEN}✓ 版本已更新为 ${NEW_VERSION}${NC}"

# 构建 addon
echo ""
echo -e "${GREEN}构建 addon...${NC}"
"$SCRIPT_DIR/build-addon.sh" "$ADDON_NAME" --push || {
    echo -e "${RED}构建失败${NC}"
    exit 1
}

# 提交更改
if [ "$COMMIT" = true ]; then
    echo ""
    echo -e "${GREEN}提交更改...${NC}"
    
    # 检查是否有未提交的更改
    if ! git diff --quiet "$VERSION_FILE"; then
        git add "$VERSION_FILE"
        git commit -m "chore($ADDON_NAME): 更新版本到 v${NEW_VERSION}"
        echo -e "${GREEN}✓ 已提交更改${NC}"
    else
        echo -e "${YELLOW}没有需要提交的更改${NC}"
    fi

    # 创建 git tag
    echo -e "${GREEN}创建 tag ${TAG_NAME}...${NC}"
    git tag "$TAG_NAME"
    echo -e "${GREEN}✓ 已创建 tag${NC}"
fi

# 推送到远程
if [ "$PUSH" = true ]; then
    echo ""
    echo -e "${GREEN}推送到远程仓库...${NC}"
    
    if [ "$COMMIT" = false ]; then
        echo -e "${YELLOW}警告: 未提交更改，跳过推送${NC}"
    else
        # 获取当前分支名称
        CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
        
        # 尝试推送代码
        if ! git push 2>/tmp/git_push_error; then
            if grep -q "has no upstream branch" /tmp/git_push_error; then
                echo -e "${YELLOW}当前分支 $CURRENT_BRANCH 没有上游分支，正在设置...${NC}"
                git push --set-upstream origin "$CURRENT_BRANCH"
            else
                cat /tmp/git_push_error
                echo -e "${RED}✗ 推送失败${NC}"
                exit 1
            fi
        fi
        
        # 推送 tags
        echo -e "${GREEN}推送 tags...${NC}"
        if git push origin "$TAG_NAME"; then
             echo -e "${GREEN}✓ 已推送 tags${NC}"
        else
             echo -e "${RED}✗ tags 推送失败${NC}"
        fi

        echo -e "${GREEN}✓ 已推送到远程仓库${NC}"
    fi
fi

echo ""
echo -e "${GREEN}完成!${NC}"
echo ""
echo "下一步:"
echo "  查看构建状态: https://github.com/linknlink/addons/actions"
echo "  查看已发布的镜像: https://github.com/orgs/linknlink/packages"
echo ""
