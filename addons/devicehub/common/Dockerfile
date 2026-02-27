ARG BUILD_FROM=debian:bookworm-slim
FROM ${BUILD_FROM}

ENV LANG=C.UTF-8 \
    DEBIAN_FRONTEND=noninteractive

# 安装依赖：mosquitto、mariadb、supervisor
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    mosquitto \
    mariadb-server \
    supervisor \
    bash \
    curl \
    ca-certificates && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 定义多架构目标参数 (由 docker buildx 默认注入)
ARG TARGETARCH

# 创建服务目录
RUN mkdir -p /etc/iegcloudaccess/output \
    /etc/iegcloudaccess/frontend \
    /etc/ha2devicehub/output \
    /etc/ha2devicehub/frontend \
    /etc/linknlinkedge/web \
    /var/lib/mosquitto \
    /var/log/supervisor

# 复制当前架构的预编译可执行文件
COPY bin/${TARGETARCH:-amd64} /app/bin

# 复制前端页面文件
COPY frontend/iegcloudaccess/ /etc/iegcloudaccess/frontend/
COPY frontend/ha2devicehub/ /etc/ha2devicehub/frontend/
COPY frontend/linknlinkedge/ /etc/linknlinkedge/web/

# 复制配置文件和脚本
COPY rootfs /

# 设置脚本可执行权限
RUN chmod +x /app/docker-entrypoint.sh && \
    chmod +x /app/init-db.sh

# 设置 mosquitto 目录权限
RUN chown -R mosquitto:mosquitto /var/lib/mosquitto

WORKDIR /app

ENTRYPOINT ["/bin/bash", "/app/docker-entrypoint.sh"]
