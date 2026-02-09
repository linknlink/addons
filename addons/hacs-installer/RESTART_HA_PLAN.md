# HACS Installer: 重启 Home Assistant 功能

## 目标描述
在 HACS Installer 界面增加直接重启 Home Assistant 容器的功能。这在安装 HACS 后非常有用，因为需要重启才能生效。该功能应能自动识别 Home Assistant 容器。

## 用户审查要求
> [!WARNING]
> 此更改需要将 `/var/run/docker.sock` 挂载到容器中。这赋予了插件极高的权限（控制 Docker 守护进程）。请确认这在安全性上是可接受的。

## 拟议更改

### Docker 配置

#### [修改] [docker-compose.yml](file:///home/linknlink/1_codes/src/github.com/linknlink/addons/addons/hacs-installer/docker-compose.yml)
- 添加卷挂载：`/var/run/docker.sock:/var/run/docker.sock` 以允许访问 Docker API。

#### [修改] [template/docker-compose.yml](file:///home/linknlink/1_codes/src/github.com/linknlink/addons/addons/hacs-installer/template/docker-compose.yml)
- 添加卷挂载：`/var/run/docker.sock:/var/run/docker.sock` 以允许访问 Docker API。

#### [修改] [common/Dockerfile](file:///home/linknlink/1_codes/src/github.com/linknlink/addons/addons/hacs-installer/common/Dockerfile)
- 在 `pip3 install` 命令中添加 `docker` python 库。

### 应用逻辑

#### [修改] [common/rootfs/app/web/app.py](file:///home/linknlink/1_codes/src/github.com/linknlink/addons/addons/hacs-installer/common/rootfs/app/web/app.py)
- 导入 `docker` 库。
- 实现 `find_ha_container()` 函数：
    - 连接到 Docker socket。
    - 列出容器。
    - 查找名称为 "homeassistant"（完全匹配优先）或名称中包含 "homeassistant" 的容器。
    - 优先选择标签中包含 `io.hass.type` 为 `homeassistant` 的容器。
- 添加 `/api/restart_ha` 端点：
    - 调用 `find_ha_container()`。
    - 如果找到，调用 `container.restart()`。
    - 返回成功/错误消息。

#### [修改] [common/rootfs/app/web/templates/index.html](file:///home/linknlink/1_codes/src/github.com/linknlink/addons/addons/hacs-installer/common/rootfs/app/web/templates/index.html)
- 添加 "Restart Home Assistant" 按钮（初始可能禁用，直到确认安装，或始终可用）。
- 添加 JavaScript 函数调用 `/api/restart_ha`。
- 处理响应并显示状态。
