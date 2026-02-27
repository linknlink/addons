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

# 创建服务目录
RUN mkdir -p /etc/iegcloudaccess/output \
    /etc/iegcloudaccess/frontend \
    /etc/ha2devicehub/output \
    /etc/ha2devicehub/frontend \
    /etc/linknlinkedge/web \
    /var/lib/mosquitto \
    /var/log/supervisor

# 复制预编译的可执行文件
COPY bin/iegcloudaccess /etc/iegcloudaccess/iegcloudaccess
COPY bin/ha2devicehub /etc/ha2devicehub/ha2devicehub
COPY bin/linknlinkedge /etc/linknlinkedge/linknlinkedge

# 复制前端页面文件
COPY frontend/iegcloudaccess/ /etc/iegcloudaccess/frontend/
COPY frontend/ha2devicehub/ /etc/ha2devicehub/frontend/
COPY frontend/linknlinkedge/ /etc/linknlinkedge/web/

# 复制配置文件和脚本
COPY rootfs /

# 设置可执行权限
RUN chmod +x /etc/iegcloudaccess/iegcloudaccess && \
    chmod +x /etc/ha2devicehub/ha2devicehub && \
    chmod +x /etc/linknlinkedge/linknlinkedge && \
    chmod +x /app/docker-entrypoint.sh && \
    chmod +x /app/init-db.sh

# 设置 mosquitto 目录权限
RUN chown -R mosquitto:mosquitto /var/lib/mosquitto

WORKDIR /app

ENTRYPOINT ["/bin/bash", "/app/docker-entrypoint.sh"]
