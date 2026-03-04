#!/bin/bash
# wait-for-dependencies.sh
# 等待给定的本地端口服务就绪，然后再执行后续命令
# 示例：wait-for-dependencies.sh 3306 1883 -- /app/my_service

TIMEOUT=30
HOST="127.0.0.1"

usage() {
    echo "Usage: $0 port [port ...] -- command args"
    exit 1
}

# 提取端口列表
declare -a PORTS
while [[ $# -gt 0 ]]; do
    if [[ "$1" == "--" ]]; then
        shift
        break
    fi
    
    PORTS+=("$1")
    shift 1
done

if [[ ${#PORTS[@]} -eq 0 || $# -eq 0 ]]; then
    usage
fi

COMMAND=("$@")

wait_for() {
    local port=$1
    
    echo "Waiting for $HOST:$port to be ready..."
    
    for i in $(seq 1 $TIMEOUT); do
        if bash -c "</dev/tcp/$HOST/$port" &>/dev/null; then
            echo "$HOST:$port is ready!"
            return 0
        fi
        sleep 1
    done
    
    echo "Timeout waiting for $HOST:$port"
    return 1
}

# 检查所有依赖
for port in "${PORTS[@]}"; do
    if ! wait_for "$port"; then
        exit 1
    fi
done

# 如果所有依赖都已就绪，则执行目标命令
echo "All dependencies ready. Starting service..."
exec "${COMMAND[@]}"
