#!/bin/bash
# 自动下载、解压各服务 deb 包，并将所需文件放至 DeviceHub addon 对应目录
# 用法: ./download_bins.sh [服务名]
#   服务名: linknlinkedge | iegcloudaccess | ha2devicehub | devicehubmanager | all (默认)
#   示例:
#     ./download_bins.sh                    # 下载全部服务
#     ./download_bins.sh devicehubmanager   # 仅下载 devicehubmanager

set -e

# 设置代理 (可选，如不需要可注释掉或通过执行时传入)
# export https_proxy=http://127.0.0.1:7897

# 所有支持的服务列表
ALL_SERVICES="linknlinkedge iegcloudaccess ha2devicehub devicehubmanager"

# 所有架构，全部下载
ALL_ARCHS="amd64 arm64"

# 目标服务 (默认 all = 全部)
TARGET=${1:-all}

# 下载地址基础 URL
BASE_URL="https://ixgdata.linklinkiot.com/ixg"

# 临时工作目录
TMP_DIR="/tmp/devicehub_extract"

# addon 根目录
ADDON_DIR="$(dirname "$0")"

# ---------- 各服务的下载与提取函数 ----------

download_linknlinkedge() {
    local arch=$1
    local bin_dir="${ADDON_DIR}/common/bin/${arch}"
    local frontend_dir="${ADDON_DIR}/common/frontend/linknlinkedge"
    local pkg="linknlinkedge_addon_latest_ieg_${arch}.deb"
    local extract_dir="${TMP_DIR}/edge_${arch}"
    echo "=== 下载并提取 linknlinkedge [${arch}] ==="
    wget -q --show-progress "${BASE_URL}/${pkg}" -O "${TMP_DIR}/${pkg}"
    dpkg-deb -x "${TMP_DIR}/${pkg}" "${extract_dir}"
    mkdir -p "${bin_dir}" "${frontend_dir}"
    cp "${extract_dir}/etc/linknlinkedge/linknlinkedge" "${bin_dir}/"
    cp -r "${extract_dir}/etc/linknlinkedge/web/"* "${frontend_dir}/"
    echo "linknlinkedge [${arch}] 提取成功！"
}

download_iegcloudaccess() {
    local arch=$1
    local bin_dir="${ADDON_DIR}/common/bin/${arch}"
    local frontend_dir="${ADDON_DIR}/common/frontend/iegcloudaccess"
    local pkg="iegcloudaccess_addon_latest_ieg_${arch}.deb"
    local extract_dir="${TMP_DIR}/ieg_${arch}"
    echo "=== 下载并提取 iegcloudaccess [${arch}] ==="
    wget -q --show-progress "${BASE_URL}/${pkg}" -O "${TMP_DIR}/${pkg}"
    dpkg-deb -x "${TMP_DIR}/${pkg}" "${extract_dir}"
    mkdir -p "${bin_dir}" "${frontend_dir}"
    cp "${extract_dir}/etc/iegcloudaccess/iegcloudaccess" "${bin_dir}/"
    cp -r "${extract_dir}/etc/iegcloudaccess/frontend/"* "${frontend_dir}/" 2>/dev/null || true
    echo "iegcloudaccess [${arch}] 提取成功！"
}

download_ha2devicehub() {
    local arch=$1
    local bin_dir="${ADDON_DIR}/common/bin/${arch}"
    local frontend_dir="${ADDON_DIR}/common/frontend/ha2devicehub"
    local pkg="ha2devicehub_addon_latest_ieg_${arch}.deb"
    local extract_dir="${TMP_DIR}/ha2_${arch}"
    echo "=== 下载并提取 ha2devicehub [${arch}] ==="
    wget -q --show-progress "${BASE_URL}/${pkg}" -O "${TMP_DIR}/${pkg}"
    dpkg-deb -x "${TMP_DIR}/${pkg}" "${extract_dir}"
    mkdir -p "${bin_dir}" "${frontend_dir}"
    cp "${extract_dir}/etc/ha2devicehub/ha2devicehub" "${bin_dir}/"
    if [ -d "${extract_dir}/etc/ha2devicehub/frontend" ]; then
        cp -r "${extract_dir}/etc/ha2devicehub/frontend/"* "${frontend_dir}/"
    fi
    echo "ha2devicehub [${arch}] 提取成功！"
}

download_devicehubmanager() {
    local arch=$1
    local bin_dir="${ADDON_DIR}/common/bin/${arch}"
    local frontend_dir="${ADDON_DIR}/common/frontend/devicehubmanager"
    local pkg="devicehubmanager_addon_latest_ieg_${arch}.deb"
    local extract_dir="${TMP_DIR}/mgr_${arch}"
    echo "=== 下载并提取 devicehubmanager [${arch}] ==="
    wget -q --show-progress "${BASE_URL}/${pkg}" -O "${TMP_DIR}/${pkg}"
    dpkg-deb -x "${TMP_DIR}/${pkg}" "${extract_dir}"
    mkdir -p "${bin_dir}" "${frontend_dir}"
    cp "${extract_dir}/etc/devicehubmanager/devicehubmanager" "${bin_dir}/"
    if [ -d "${extract_dir}/etc/devicehubmanager/frontend" ]; then
        cp -r "${extract_dir}/etc/devicehubmanager/frontend/"* "${frontend_dir}/"
    fi
    echo "devicehubmanager [${arch}] 提取成功！"
}

# ---------- 主逻辑 ----------

# 校验服务名是否合法
if [ "${TARGET}" != "all" ]; then
    valid=false
    for svc in ${ALL_SERVICES}; do
        if [ "${TARGET}" = "${svc}" ]; then
            valid=true
            break
        fi
    done
    if [ "${valid}" = false ]; then
        echo "错误: 未知服务 '${TARGET}'"
        echo "可选服务: ${ALL_SERVICES} 或 all"
        exit 1
    fi
fi

# 初始化临时目录
echo "=== 初始化工作目录 ==="
rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}"

if [ "${TARGET}" = "all" ]; then
    echo "目标服务: 全部"
else
    echo "目标服务: ${TARGET}"
fi
echo "目标架构: ${ALL_ARCHS}"

# 确定要下载的服务列表
if [ "${TARGET}" = "all" ]; then
    services="${ALL_SERVICES}"
else
    services="${TARGET}"
fi

# 对每个服务，遍历所有架构进行下载
for svc in ${services}; do
    for arch in ${ALL_ARCHS}; do
        "download_${svc}" "${arch}"
    done
done

# 清理
rm -rf "${TMP_DIR}"

echo "=== 提取完成 ==="
for arch in ${ALL_ARCHS}; do
    echo "可执行文件 [${arch}]:"
    ls -lh "${ADDON_DIR}/common/bin/${arch}"
done
echo "前端目录状态:"
ls -lh "${ADDON_DIR}/common/frontend"
