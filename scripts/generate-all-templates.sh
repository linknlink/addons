#!/bin/bash

# 为所有现有 addon 生成上传用的 template 脚本
# 使用方法: ./scripts/generate-all-templates.sh [--output-dir <dir>]

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 显示帮助信息
show_help() {
    echo "使用方法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  --output-dir <dir>  - 输出目录（默认: ../addon_templates，相对于脚本位置）"
    echo "  --help, -h          - 显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0"
    echo "  $0 --output-dir /path/to/addon_templates"
}

OUTPUT_DIR=""

# 解析选项
while [[ $# -gt 0 ]]; do
    case $1 in
        --output-dir)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        --help|-h)
            show_help
            exit 0
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
GENERATE_SCRIPT="$SCRIPT_DIR/generate-template-from-addon.sh"

# 检查生成脚本是否存在
if [ ! -f "$GENERATE_SCRIPT" ]; then
    echo -e "${RED}错误: 找不到 generate-template-from-addon.sh 脚本${NC}"
    exit 1
fi

# 检查 addons 目录是否存在
if [ ! -d "$ADDONS_DIR" ]; then
    echo -e "${RED}错误: Addons 目录不存在: $ADDONS_DIR${NC}"
    exit 1
fi

echo -e "${BLUE}正在为所有 addon 生成 template...${NC}"
echo ""

# 查找所有 addon 目录
ADDON_COUNT=0
SUCCESS_COUNT=0
FAILED_COUNT=0
FAILED_ADDONS=()

for addon_dir in "$ADDONS_DIR"/*; do
    if [ -d "$addon_dir" ]; then
        addon_name=$(basename "$addon_dir")
        
        # 跳过隐藏目录
        if [[ "$addon_name" =~ ^\. ]]; then
            continue
        fi
        
        ADDON_COUNT=$((ADDON_COUNT + 1))
        echo -e "${BLUE}[$ADDON_COUNT] 处理 addon: ${addon_name}${NC}"
        
        # 调用生成脚本
        if [ -n "$OUTPUT_DIR" ]; then
            if "$GENERATE_SCRIPT" "$addon_name" --output-dir "$OUTPUT_DIR" > /dev/null 2>&1; then
                echo -e "${GREEN}  ✓ ${addon_name} template 生成成功${NC}"
                SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
            else
                echo -e "${RED}  ✗ ${addon_name} template 生成失败${NC}"
                FAILED_COUNT=$((FAILED_COUNT + 1))
                FAILED_ADDONS+=("$addon_name")
            fi
        else
            if "$GENERATE_SCRIPT" "$addon_name" > /dev/null 2>&1; then
                echo -e "${GREEN}  ✓ ${addon_name} template 生成成功${NC}"
                SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
            else
                echo -e "${RED}  ✗ ${addon_name} template 生成失败${NC}"
                FAILED_COUNT=$((FAILED_COUNT + 1))
                FAILED_ADDONS+=("$addon_name")
            fi
        fi
    fi
done

echo ""
echo "=========================================="
echo -e "${BLUE}生成完成！${NC}"
echo ""
echo "统计信息:"
echo "  总 addon 数: $ADDON_COUNT"
echo -e "  成功: ${GREEN}$SUCCESS_COUNT${NC}"
if [ $FAILED_COUNT -gt 0 ]; then
    echo -e "  失败: ${RED}$FAILED_COUNT${NC}"
    echo ""
    echo "失败的 addon:"
    for failed_addon in "${FAILED_ADDONS[@]}"; do
        echo -e "  ${RED}- $failed_addon${NC}"
    done
else
    echo -e "  失败: $FAILED_COUNT"
fi
echo ""

if [ $FAILED_COUNT -gt 0 ]; then
    exit 1
else
    exit 0
fi
