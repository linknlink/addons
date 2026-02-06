#!/bin/bash

# 验证 addon 结构的脚本
# 使用方法: ./scripts/validate-addon.sh <addon-name>

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
    echo "  addon-name    - 要验证的 addon 名称"
    echo ""
    echo "选项:"
    echo "  --check-template  - 同时检查上传用的 template（如果存在）"
    echo "  --help, -h        - 显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 linknlink-remote"
    echo "  $0 linknlink-remote --check-template"
}

# 检查参数
if [ $# -eq 0 ] || [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
    show_help
    exit 0
fi

ADDON_NAME="$1"
CHECK_TEMPLATE=false

# 解析选项
shift
while [[ $# -gt 0 ]]; do
    case $1 in
        --check-template)
            CHECK_TEMPLATE=true
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
TEMPLATE_DIR="$PROJECT_ROOT/addon_templates/$ADDON_NAME"

# 检查 addon 是否存在
if [ ! -d "$ADDON_DIR" ]; then
    echo -e "${RED}错误: Addon '$ADDON_NAME' 不存在${NC}"
    exit 1
fi

echo -e "${BLUE}验证 addon: ${ADDON_NAME}${NC}"
echo ""

ERRORS=0
WARNINGS=0

# 检查必需文件
check_file() {
    local file="$1"
    local required="${2:-false}"
    
    if [ -f "$file" ]; then
        echo -e "${GREEN}✓${NC} $file"
        return 0
    else
        if [ "$required" = "true" ]; then
            echo -e "${RED}✗${NC} $file (必需)"
            ERRORS=$((ERRORS + 1))
            return 1
        else
            echo -e "${YELLOW}⚠${NC} $file (可选)"
            WARNINGS=$((WARNINGS + 1))
            return 0
        fi
    fi
}

# 检查必需目录
check_dir() {
    local dir="$1"
    local required="${2:-false}"
    
    if [ -d "$dir" ]; then
        echo -e "${GREEN}✓${NC} $dir/"
        return 0
    else
        if [ "$required" = "true" ]; then
            echo -e "${RED}✗${NC} $dir/ (必需)"
            ERRORS=$((ERRORS + 1))
            return 1
        else
            echo -e "${YELLOW}⚠${NC} $dir/ (可选)"
            WARNINGS=$((WARNINGS + 1))
            return 0
        fi
    fi
}

# 验证 JSON 文件
validate_json() {
    local file="$1"
    if [ -f "$file" ]; then
        # 临时禁用 set -e 来检查 jq 的退出码
        set +e
        jq empty "$file" 2>/dev/null
        local jq_exit_code=$?
        set -e
        if [ $jq_exit_code -eq 0 ]; then
            echo -e "${GREEN}✓${NC} JSON 格式正确: $file"
            return 0
        else
            echo -e "${RED}✗${NC} JSON 格式错误: $file"
            ERRORS=$((ERRORS + 1))
            return 1
        fi
    fi
    return 0
}

echo "检查文件结构..."
echo ""

# 必需文件
check_file "$ADDON_DIR/VERSION" true
check_file "$ADDON_DIR/config.json" true
check_file "$ADDON_DIR/docker-compose.yml" true

# 推荐文件（README.md 是 addon 级文档，面向开发者）
check_file "$ADDON_DIR/README.md" false

# 可选文件（用于元数据和架构配置）
check_file "$ADDON_DIR/repository.json" false
check_file "$ADDON_DIR/requirements.txt" false
check_file "$ADDON_DIR/CHANGELOG.md" false

# 必需目录
check_dir "$ADDON_DIR/common" true
check_file "$ADDON_DIR/common/Dockerfile" true
check_dir "$ADDON_DIR/common/rootfs" true

echo ""
echo "验证 JSON 文件..."
echo ""

# 验证 JSON 文件（如果存在）
if [ -f "$ADDON_DIR/config.json" ]; then
    validate_json "$ADDON_DIR/config.json"
fi
if [ -f "$ADDON_DIR/repository.json" ]; then
    validate_json "$ADDON_DIR/repository.json"
fi

echo ""
echo "检查版本号格式..."
if [ -f "$ADDON_DIR/VERSION" ]; then
    VERSION=$(cat "$ADDON_DIR/VERSION" | tr -d '[:space:]')
    if [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo -e "${GREEN}✓${NC} 版本号格式正确: $VERSION"
    else
        echo -e "${RED}✗${NC} 版本号格式错误: $VERSION (应为 MAJOR.MINOR.PATCH)"
        ERRORS=$((ERRORS + 1))
    fi
fi

echo ""
echo "检查 Dockerfile..."
if [ -f "$ADDON_DIR/common/Dockerfile" ]; then
    if grep -q "FROM" "$ADDON_DIR/common/Dockerfile"; then
        echo -e "${GREEN}✓${NC} Dockerfile 包含 FROM 指令"
    else
        echo -e "${RED}✗${NC} Dockerfile 缺少 FROM 指令"
        ERRORS=$((ERRORS + 1))
    fi
    
    # 检查是否有 ARG BUILD_FROM（推荐）
    if grep -q "ARG BUILD_FROM" "$ADDON_DIR/common/Dockerfile"; then
        echo -e "${GREEN}✓${NC} Dockerfile 包含 ARG BUILD_FROM（推荐）"
    else
        echo -e "${YELLOW}⚠${NC} Dockerfile 未包含 ARG BUILD_FROM（推荐添加以支持多架构）"
        WARNINGS=$((WARNINGS + 1))
    fi
else
    echo -e "${RED}✗${NC} Dockerfile 不存在"
    ERRORS=$((ERRORS + 1))
fi

echo ""
echo "检查 README.md（addon 级文档）..."
if [ -f "$ADDON_DIR/README.md" ]; then
    # 检查是否包含基本章节
    if grep -q "^## 概述\|^## Overview" "$ADDON_DIR/README.md"; then
        echo -e "${GREEN}✓${NC} README.md 包含概述部分"
    else
        echo -e "${YELLOW}⚠${NC} README.md 缺少概述部分（推荐添加）"
        WARNINGS=$((WARNINGS + 1))
    fi
    
    if grep -q "^## 主要功能\|^## 功能\|^## Features" "$ADDON_DIR/README.md"; then
        echo -e "${GREEN}✓${NC} README.md 包含功能说明部分"
    else
        echo -e "${YELLOW}⚠${NC} README.md 缺少功能说明部分（推荐添加）"
        WARNINGS=$((WARNINGS + 1))
    fi
    
    # 检查是否包含模板变量（不应该存在）
    if grep -q "{{ADDON_NAME}}\|{{ADDON_SLUG}}" "$ADDON_DIR/README.md"; then
        echo -e "${RED}✗${NC} README.md 包含未替换的模板变量"
        ERRORS=$((ERRORS + 1))
    else
        echo -e "${GREEN}✓${NC} README.md 模板变量已正确替换"
    fi
else
    echo -e "${YELLOW}⚠${NC} README.md 不存在（推荐添加 addon 级文档）"
    WARNINGS=$((WARNINGS + 1))
fi

echo ""
echo "检查 config.json 内容..."
if [ -f "$ADDON_DIR/config.json" ]; then
    if command -v jq &> /dev/null; then
        # 检查必需字段
        REQUIRED_FIELDS=("name" "version" "slug" "description" "arch" "startup" "boot")
        for field in "${REQUIRED_FIELDS[@]}"; do
            if jq -e ".${field}" "$ADDON_DIR/config.json" > /dev/null 2>&1; then
                echo -e "${GREEN}✓${NC} config.json 包含必需字段: ${field}"
            else
                echo -e "${RED}✗${NC} config.json 缺少必需字段: ${field}"
                ERRORS=$((ERRORS + 1))
            fi
        done
        
        # 检查 slug 格式（应该是下划线分隔）
        SLUG=$(jq -r '.slug' "$ADDON_DIR/config.json" 2>/dev/null || echo "")
        if [[ "$SLUG" =~ ^[a-z0-9_]+$ ]]; then
            echo -e "${GREEN}✓${NC} config.json slug 格式正确: ${SLUG}"
        elif [ -n "$SLUG" ]; then
            echo -e "${YELLOW}⚠${NC} config.json slug 格式建议使用下划线: ${SLUG}"
            WARNINGS=$((WARNINGS + 1))
        fi
    else
        echo -e "${YELLOW}⚠${NC} 未安装 jq，跳过 config.json 内容检查"
        WARNINGS=$((WARNINGS + 1))
    fi
fi

# 检查 template（如果指定）
if [ "$CHECK_TEMPLATE" = true ]; then
    echo ""
    echo "=========================================="
    echo "检查上传用的 template..."
    echo ""
    
    if [ -d "$TEMPLATE_DIR" ]; then
        TEMPLATE_ERRORS=0
        TEMPLATE_WARNINGS=0
        
        # 检查必需文件
        check_file "$TEMPLATE_DIR/upload_config.json" true
        if [ $? -ne 0 ]; then
            TEMPLATE_ERRORS=$((TEMPLATE_ERRORS + 1))
        fi
        
        check_file "$TEMPLATE_DIR/docker-compose.yml" false
        if [ $? -ne 0 ]; then
            TEMPLATE_WARNINGS=$((TEMPLATE_WARNINGS + 1))
        fi
        
        check_file "$TEMPLATE_DIR/.tarignore" false
        if [ $? -ne 0 ]; then
            TEMPLATE_WARNINGS=$((TEMPLATE_WARNINGS + 1))
        fi
        
        check_dir "$TEMPLATE_DIR/common" false
        if [ $? -ne 0 ]; then
            TEMPLATE_WARNINGS=$((TEMPLATE_WARNINGS + 1))
        fi
        
        # 验证 upload_config.json JSON 格式
        if [ -f "$TEMPLATE_DIR/upload_config.json" ]; then
            validate_json "$TEMPLATE_DIR/upload_config.json"
            if [ $? -ne 0 ]; then
                TEMPLATE_ERRORS=$((TEMPLATE_ERRORS + 1))
            fi
        fi
        
        echo ""
        echo "Template 验证结果:"
        if [ $TEMPLATE_ERRORS -eq 0 ] && [ $TEMPLATE_WARNINGS -eq 0 ]; then
            echo -e "${GREEN}✓ Template 验证通过！${NC}"
        elif [ $TEMPLATE_ERRORS -eq 0 ]; then
            echo -e "${YELLOW}⚠ Template 验证通过，但有 $TEMPLATE_WARNINGS 个警告${NC}"
        else
            echo -e "${RED}✗ Template 验证失败：发现 $TEMPLATE_ERRORS 个错误，$TEMPLATE_WARNINGS 个警告${NC}"
            ERRORS=$((ERRORS + TEMPLATE_ERRORS))
            WARNINGS=$((WARNINGS + TEMPLATE_WARNINGS))
        fi
    else
        echo -e "${YELLOW}⚠ Template 目录不存在: $TEMPLATE_DIR${NC}"
        echo "  运行 ./scripts/generate-template-from-addon.sh $ADDON_NAME 生成 template"
        WARNINGS=$((WARNINGS + 1))
    fi
fi

echo ""
echo "=========================================="
if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✓ 验证通过！${NC}"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠ 验证通过，但有 $WARNINGS 个警告${NC}"
    exit 0
else
    echo -e "${RED}✗ 验证失败：发现 $ERRORS 个错误，$WARNINGS 个警告${NC}"
    exit 1
fi
