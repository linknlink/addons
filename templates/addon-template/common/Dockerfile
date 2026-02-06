ARG BUILD_FROM=alpine:latest
FROM ${BUILD_FROM}

ENV LANG C.UTF-8

# 安装依赖
RUN apk add --no-cache \
    bash \
    curl \
    ca-certificates

# 复制应用文件
COPY rootfs /

# 设置工作目录
WORKDIR /app

# 运行脚本
ENTRYPOINT [ "/bin/bash", "/app/docker-entrypoint.sh" ]
