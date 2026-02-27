# DeviceHub 使用文档

## 概述

DeviceHub 是一个物联网设备中心服务集合 addon，将多个核心服务打包在一个容器中运行。

## 安装

1. 在 Addon 管理界面搜索 **DeviceHub**
2. 点击安装
3. 启动服务

## 服务说明

### iegcloudaccess (端口 1692)

iEG 云端接入服务，负责设备与云端的通信桥接。

### ha2devicehub (端口 1691)

Home Assistant 设备中心桥接服务，将 HA 设备与设备中心进行联动。

### linknlinkedge (端口 1696)

LinknLink 边缘计算平台，提供设备管理、MQTT 通信、WebSocket 实时推送和 RESTful API 接口。

## 数据持久化

- **MySQL 数据**：自动持久化，容器重启不会丢失数据
- **Mosquitto 数据**：保留消息（retained messages）持久化

## 查看服务状态

```bash
docker exec devicehub supervisorctl status
```

## 查看日志

```bash
docker logs devicehub
```
