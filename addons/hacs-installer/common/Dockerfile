ARG BUILD_FROM=alpine:latest
FROM ${BUILD_FROM}

ENV LANG=C.UTF-8

# 安装依赖
RUN apk add --no-cache \
    python3 \
    py3-pip \
    bash \
    curl \
    unzip \
    ca-certificates

# 安装 Flask
RUN pip3 install --no-cache-dir --break-system-packages flask requests docker

# 复制应用文件
COPY rootfs /

# 设置工作目录
WORKDIR /app

# 设置权限
RUN chmod +x /app/docker-entrypoint.sh && \
    chmod +x /app/install-hacs.sh && \
    chmod +x /app/uninstall-hacs.sh

# 运行脚本
ENTRYPOINT [ "/bin/bash", "/app/docker-entrypoint.sh" ]
