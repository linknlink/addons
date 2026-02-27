# DeviceHub Addon

物联网设备中心服务集合，包含以下服务：

- **iegcloudaccess** - iEG 云端接入服务 (端口 1692)
- **ha2devicehub** - HA 设备中心桥接服务 (端口 1691)
- **linknlinkedge** - LinknLink 边缘计算服务 (端口 1696)
- **mosquitto** - MQTT 消息代理
- **mariadb** - 数据库服务

## 使用方式

### 准备可执行文件和前端页面

将编译好的可执行文件放入 `common/bin/` 目录：

```
common/bin/
├── iegcloudaccess
├── ha2devicehub
└── linknlinkedge
```

将前端页面文件放入 `common/frontend/` 目录：

```
common/frontend/
├── iegcloudaccess/     # iegcloudaccess 前端页面
├── ha2devicehub/       # ha2devicehub 前端页面
└── linknlinkedge/      # linknlinkedge web 页面
```

### 构建和运行

```bash
docker compose build
docker compose up -d
```

### 查看服务状态

```bash
docker exec devicehub supervisorctl status
```

### Web 访问

- iegcloudaccess: http://localhost:1692
- ha2devicehub: http://localhost:1691
- linknlinkedge: http://localhost:1696
