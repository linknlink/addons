#!/bin/bash

# 为所有现有 addon 生成上传用的 template 脚本
# 使用方法: ./scripts/generate-all-templates.sh [选项]

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
    echo "  --output-dir <dir>      - 输出目录（默认: addon_templates/）"
    echo "  --skip-no-template      - 跳过没有 template/ 目录的 addon"
    echo "  --verbose, -v          - 显示详细输出"
    echo "  --help, -h              - 显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0"
    echo "  $0 --output-dir /path/to/addon_templates"
    echo "  $0 --skip-no-template --verbose"
}

OUTPUT_DIR=""
SKIP_NO_TEMPLATE=false
VERBOSE=false

# 解析选项
while [[ $# -gt 0 ]]; do
    case $1 in
        --output-dir)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        --skip-no-template)
            SKIP_NO_TEMPLATE=true
            shift
            ;;
        --verbose|-v)
            VERBOSE=true
            shift
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
TEMPLATE_SOURCE_DIR="$PROJECT_ROOT/templates/addon-template/template"

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

# 检查模板源目录是否存在
if [ ! -d "$TEMPLATE_SOURCE_DIR" ]; then
    echo -e "${YELLOW}警告: 模板源目录不存在: $TEMPLATE_SOURCE_DIR${NC}"
    echo "  将无法自动创建 template/ 目录"
fi

echo -e "${BLUE}正在为所有 addon 生成 template...${NC}"
if [ "$SKIP_NO_TEMPLATE" = true ]; then
    echo -e "${YELLOW}提示: 将跳过没有 template/ 目录的 addon${NC}"
fi
echo ""

# 查找所有 addon 目录
ADDON_COUNT=0
SUCCESS_COUNT=0
FAILED_COUNT=0
SKIPPED_COUNT=0
FAILED_ADDONS=()
SKIPPED_ADDONS=()

for addon_dir in "$ADDONS_DIR"/*; do
    if [ -d "$addon_dir" ]; then
        addon_name=$(basename "$addon_dir")
        
        # 跳过隐藏目录
        if [[ "$addon_name" =~ ^\. ]]; then
            continue
        fi
        
        ADDON_COUNT=$((ADDON_COUNT + 1))
        
        # 检查是否有 template/ 目录，如果没有或为空则自动创建/填充
        TEMPLATE_NEEDS_CREATE=false
        if [ ! -d "$addon_dir/template" ]; then
            TEMPLATE_NEEDS_CREATE=true
        elif [ -z "$(ls -A "$addon_dir/template" 2>/dev/null)" ]; then
            # 目录存在但为空
            TEMPLATE_NEEDS_CREATE=true
        fi
        
        if [ "$TEMPLATE_NEEDS_CREATE" = true ]; then
            if [ "$SKIP_NO_TEMPLATE" = true ]; then
                echo -e "${YELLOW}[$ADDON_COUNT] 跳过 ${addon_name}（没有 template/ 目录或目录为空）${NC}"
                SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
                SKIPPED_ADDONS+=("$addon_name")
                continue
            else
                echo -e "${BLUE}[$ADDON_COUNT] 处理 addon: ${addon_name}${NC}"
                echo -e "${YELLOW}  检测到 template/ 目录不存在或为空，自动创建...${NC}"
                
                # 自动创建/填充 template/ 目录
                if [ -d "$TEMPLATE_SOURCE_DIR" ]; then
                    mkdir -p "$addon_dir/template"
                    cp -r "$TEMPLATE_SOURCE_DIR"/* "$addon_dir/template/" 2>/dev/null || {
                        echo -e "${RED}  ✗ 无法复制模板文件${NC}"
                        FAILED_COUNT=$((FAILED_COUNT + 1))
                        FAILED_ADDONS+=("$addon_name")
                        continue
                    }
                    
                    # 读取 addon 信息用于替换变量
                    ADDON_SLUG="${addon_name//-/_}"
                    ADDON_DISPLAY_NAME="$addon_name"
                    
                    # 优先从 config.json 读取
                    if [ -f "$addon_dir/config.json" ] && command -v jq &> /dev/null; then
                        ADDON_DISPLAY_NAME=$(jq -r '.name // "'"$addon_name"'"' "$addon_dir/config.json" 2>/dev/null || echo "$addon_name")
                        ADDON_SLUG=$(jq -r '.slug // "'"${addon_name//-/_}"'"' "$addon_dir/config.json" 2>/dev/null || echo "${addon_name//-/_}")
                    # 否则从 repository.json 读取
                    elif [ -f "$addon_dir/repository.json" ] && command -v jq &> /dev/null; then
                        ADDON_DISPLAY_NAME=$(jq -r '.name // "'"$addon_name"'"' "$addon_dir/repository.json" 2>/dev/null || echo "$addon_name")
                        ADDON_SLUG=$(jq -r '.slug // "'"${addon_name//-/_}"'"' "$addon_dir/repository.json" 2>/dev/null || echo "${addon_name//-/_}")
                    else
                        # 生成显示名称（首字母大写）
                        ADDON_DISPLAY_NAME=$(echo "$addon_name" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++)sub(/./,toupper(substr($i,1,1)),$i)}1')
                    fi
                    
                    # 替换模板变量
                    # 注意：{{ADDON_NAME}} 替换为显示名称，{{ADDON_SLUG}} 替换为 slug（下划线格式）
                    # 但 upload_config.json 中的 display_name 和 id 应该使用 addon 名称（连字符格式）
                    find "$addon_dir/template" -type f \( \
                        -name "*.md" -o \
                        -name "*.json" -o \
                        -name "*.yml" -o \
                        -name "*.yaml" \
                    \) -exec sed -i "s/{{ADDON_NAME}}/$ADDON_DISPLAY_NAME/g" {} \; 2>/dev/null || true
                    
                    find "$addon_dir/template" -type f \( \
                        -name "*.md" -o \
                        -name "*.json" -o \
                        -name "*.yml" -o \
                        -name "*.yaml" \
                    \) -exec sed -i "s/{{ADDON_SLUG}}/$ADDON_SLUG/g" {} \; 2>/dev/null || true
                    
                    # 特殊处理 upload_config.json：display_name 和 id 应该使用 addon 名称（连字符格式）
                    if [ -f "$addon_dir/template/upload_config.json" ]; then
                        sed -i "s/\"display_name\": \"$ADDON_SLUG\"/\"display_name\": \"$addon_name\"/g" "$addon_dir/template/upload_config.json" 2>/dev/null || true
                        sed -i "s/\"id\": \"$ADDON_SLUG\"/\"id\": \"$addon_name\"/g" "$addon_dir/template/upload_config.json" 2>/dev/null || true
                    fi
                    
                    echo -e "${GREEN}  ✓ 已创建/填充 template/ 目录并复制模板文件${NC}"
                    echo -e "${YELLOW}  ⚠ 请编辑 addons/$addon_name/template/ 目录中的文件，填充实际的模板内容${NC}"
                else
                    echo -e "${RED}  ✗ 模板源目录不存在: $TEMPLATE_SOURCE_DIR${NC}"
                    FAILED_COUNT=$((FAILED_COUNT + 1))
                    FAILED_ADDONS+=("$addon_name")
                    continue
                fi
            fi
        else
            echo -e "${BLUE}[$ADDON_COUNT] 处理 addon: ${addon_name}${NC}"
        fi
        
        # 调用生成脚本
        if [ "$VERBOSE" = true ]; then
            # 详细模式：显示所有输出
            if [ -n "$OUTPUT_DIR" ]; then
                if "$GENERATE_SCRIPT" "$addon_name" --output-dir "$OUTPUT_DIR"; then
                    echo -e "${GREEN}  ✓ ${addon_name} template 生成成功${NC}"
                    SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
                else
                    echo -e "${RED}  ✗ ${addon_name} template 生成失败${NC}"
                    FAILED_COUNT=$((FAILED_COUNT + 1))
                    FAILED_ADDONS+=("$addon_name")
                fi
            else
                if "$GENERATE_SCRIPT" "$addon_name"; then
                    echo -e "${GREEN}  ✓ ${addon_name} template 生成成功${NC}"
                    SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
                else
                    echo -e "${RED}  ✗ ${addon_name} template 生成失败${NC}"
                    FAILED_COUNT=$((FAILED_COUNT + 1))
                    FAILED_ADDONS+=("$addon_name")
                fi
            fi
        else
            # 静默模式：只显示关键信息
            TEMP_OUTPUT=$(mktemp)
            if [ -n "$OUTPUT_DIR" ]; then
                if "$GENERATE_SCRIPT" "$addon_name" --output-dir "$OUTPUT_DIR" > "$TEMP_OUTPUT" 2>&1; then
                    echo -e "${GREEN}  ✓ ${addon_name} template 生成成功${NC}"
                    SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
                else
                    echo -e "${RED}  ✗ ${addon_name} template 生成失败${NC}"
                    # 显示错误信息
                    if grep -q "错误:" "$TEMP_OUTPUT"; then
                        grep "错误:" "$TEMP_OUTPUT" | head -1 | sed 's/^/    /'
                    fi
                    FAILED_COUNT=$((FAILED_COUNT + 1))
                    FAILED_ADDONS+=("$addon_name")
                fi
            else
                if "$GENERATE_SCRIPT" "$addon_name" > "$TEMP_OUTPUT" 2>&1; then
                    echo -e "${GREEN}  ✓ ${addon_name} template 生成成功${NC}"
                    SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
                else
                    echo -e "${RED}  ✗ ${addon_name} template 生成失败${NC}"
                    # 显示错误信息
                    if grep -q "错误:" "$TEMP_OUTPUT"; then
                        grep "错误:" "$TEMP_OUTPUT" | head -1 | sed 's/^/    /'
                    fi
                    FAILED_COUNT=$((FAILED_COUNT + 1))
                    FAILED_ADDONS+=("$addon_name")
                fi
            fi
            rm -f "$TEMP_OUTPUT"
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
if [ $SKIPPED_COUNT -gt 0 ]; then
    echo -e "  跳过: ${YELLOW}$SKIPPED_COUNT${NC}"
fi
if [ $FAILED_COUNT -gt 0 ]; then
    echo -e "  失败: ${RED}$FAILED_COUNT${NC}"
else
    echo -e "  失败: $FAILED_COUNT"
fi
echo ""

# 显示跳过的 addon
if [ $SKIPPED_COUNT -gt 0 ]; then
    echo "跳过的 addon（没有 template/ 目录或目录为空）:"
    for skipped_addon in "${SKIPPED_ADDONS[@]}"; do
        echo -e "  ${YELLOW}- $skipped_addon${NC}"
    done
    echo ""
fi

# 显示失败的 addon
if [ $FAILED_COUNT -gt 0 ]; then
    echo "失败的 addon:"
    for failed_addon in "${FAILED_ADDONS[@]}"; do
        echo -e "  ${RED}- $failed_addon${NC}"
    done
    echo ""
    echo -e "${YELLOW}提示:${NC}"
    echo "  - 如果 addon 没有 template/ 目录，请先运行: ./scripts/add-addon.sh <addon-name>"
    echo "  - 然后编辑 addons/<addon-name>/template/ 目录中的模板文件"
    echo "  - 使用 --skip-no-template 选项可以跳过没有 template/ 目录的 addon"
    echo ""
    exit 1
else
    exit 0
fi
