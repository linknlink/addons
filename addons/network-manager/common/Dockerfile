ARG BUILD_FROM=debian:bookworm-slim
FROM ${BUILD_FROM}

ENV LANG=C.UTF-8 \
    DEBIAN_FRONTEND=noninteractive

# 安装 nmcli 客户端和相关工具
# 注意：容器只需要 nmcli 客户端，NetworkManager 服务在宿主机上运行
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    network-manager \
    iputils-ping \
    curl \
    jq \
    bash \
    python3 \
    python3-flask \
    python3-pip \
    ca-certificates \
    dbus && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 复制应用文件
COPY rootfs /

# 设置工作目录
WORKDIR /app

# 设置权限
RUN chmod +x /app/docker-entrypoint.sh && \
    chmod +x /app/network-manager.sh && \
    chmod +x /app/config-validator.sh && \
    chmod +x /app/utils.sh

# 运行脚本
ENTRYPOINT ["/bin/bash", "/app/docker-entrypoint.sh"]
