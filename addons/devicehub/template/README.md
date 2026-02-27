# DeviceHub

物联网设备中心服务集合，提供设备接入、设备管理和边缘计算能力。

## 包含服务

| 服务 | 功能 | 端口 |
|------|------|------|
| iegcloudaccess | iEG 云端接入 | 1692 |
| ha2devicehub | HA 设备中心桥接 | 1691 |
| linknlinkedge | 边缘计算平台 | 1696 |
| mosquitto | MQTT 消息代理 | 1883 (内部) |
| mariadb | 数据库 | 3306 (内部) |
