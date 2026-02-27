#!/bin/bash
# 自动下载、解压各服务 deb 包，并将所需文件放至 DeviceHub adddon 对应目录

set -e

# 设置代理 (可选，如不需要可注释掉或通过执行时传入)
# export https_proxy=http://127.0.0.1:7897

# 架构定义 (默认 amd64，可以通过参数传入，如 ./download.sh arm64)
ARCH=${1:-amd64}

# 下载地址基础 URL
BASE_URL="https://ixgdata.linklinkiot.com/ixg"

# 临时工作目录
TMP_DIR="/tmp/devicehub_extract"

# addon 根目录
ADDON_DIR="$(dirname "$0")"
BIN_DIR="${ADDON_DIR}/common/bin/${ARCH}"
FRONTEND_DIR="${ADDON_DIR}/common/frontend"

# 初始化环境
echo "=== 初始化工作目录 ==="
rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}"
mkdir -p "${BIN_DIR}"
mkdir -p "${FRONTEND_DIR}/iegcloudaccess"
mkdir -p "${FRONTEND_DIR}/ha2devicehub"
mkdir -p "${FRONTEND_DIR}/linknlinkedge"

echo "目标架构: ${ARCH}"

# ======= 1. linknlinkedge =======
PKG_EDGE="linknlinkedge_latest_ieg_${ARCH}.deb"
echo "=== 下载并提取 linknlinkedge (${PKG_EDGE}) ==="
wget -q --show-progress "${BASE_URL}/${PKG_EDGE}" -O "${TMP_DIR}/${PKG_EDGE}"
dpkg-deb -x "${TMP_DIR}/${PKG_EDGE}" "${TMP_DIR}/edge"
cp "${TMP_DIR}/edge/etc/linknlinkedge/linknlinkedge" "${BIN_DIR}/"
cp -r "${TMP_DIR}/edge/etc/linknlinkedge/web/"* "${FRONTEND_DIR}/linknlinkedge/"
echo "linknlinkedge 提取成功！"

# ======= 2. iegcloudaccess =======
PKG_IEG="iegcloudaccess_latest_ieg_${ARCH}.deb"
echo "=== 下载并提取 iegcloudaccess (${PKG_IEG}) ==="
wget -q --show-progress "${BASE_URL}/${PKG_IEG}" -O "${TMP_DIR}/${PKG_IEG}"
dpkg-deb -x "${TMP_DIR}/${PKG_IEG}" "${TMP_DIR}/ieg"
cp "${TMP_DIR}/ieg/etc/iegcloudaccess/iegcloudaccess" "${BIN_DIR}/"
cp -r "${TMP_DIR}/ieg/etc/iegcloudaccess/frontend/"* "${FRONTEND_DIR}/iegcloudaccess/" 2>/dev/null || true
echo "iegcloudaccess 提取成功！"

# ======= 3. ha2devicehub =======
PKG_HA2="ha2devicehub_latest_ieg_${ARCH}.deb"
echo "=== 下载并提取 ha2devicehub (${PKG_HA2}) ==="
wget -q --show-progress "${BASE_URL}/${PKG_HA2}" -O "${TMP_DIR}/${PKG_HA2}"
dpkg-deb -x "${TMP_DIR}/${PKG_HA2}" "${TMP_DIR}/ha2"
cp "${TMP_DIR}/ha2/etc/ha2devicehub/ha2devicehub" "${BIN_DIR}/"
# 查找前端文件（如果存在）
if [ -d "${TMP_DIR}/ha2/etc/ha2devicehub/frontend" ]; then
    cp -r "${TMP_DIR}/ha2/etc/ha2devicehub/frontend/"* "${FRONTEND_DIR}/ha2devicehub/"
fi
echo "ha2devicehub 提取成功！"

# 清理
rm -rf "${TMP_DIR}"

echo "=== 全部提取完成 ==="
echo "可执行文件状态:"
ls -lh "${BIN_DIR}"
echo "前端目录状态:"
ls -lh "${FRONTEND_DIR}"
