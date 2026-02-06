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
check_file "$ADDON_DIR/README.md" false

# 可选文件（用于元数据和架构配置）
check_file "$ADDON_DIR/repository.json" false

# 必需目录
check_dir "$ADDON_DIR/common" true
check_file "$ADDON_DIR/common/Dockerfile" true
check_dir "$ADDON_DIR/common/rootfs" true

# 可选文件
check_file "$ADDON_DIR/docker-compose.yml" false
check_file "$ADDON_DIR/requirements.txt" false
check_file "$ADDON_DIR/CHANGELOG.md" false

echo ""
echo "验证 JSON 文件..."
echo ""

# 验证 JSON 文件（如果存在）
if [ -f "$ADDON_DIR/repository.json" ]; then
    validate_json "$ADDON_DIR/repository.json"
fi
if [ -f "$ADDON_DIR/config.json" ]; then
    validate_json "$ADDON_DIR/config.json"
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
