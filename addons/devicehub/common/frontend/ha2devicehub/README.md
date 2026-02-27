# HA2Devicehub 前端管理界面

这是一个用于管理 Home Assistant 设备同步到 LinkLinkEdge 服务的前端界面。

## 功能特性

1. **HA Token 设置**
   - 设置 Home Assistant 的长期访问令牌
   - 支持显示/隐藏令牌功能
   - 自动保存和加载令牌

2. **HA 连接状态监控**
   - 实时显示与 Home Assistant 的连接状态
   - 显示 HA 服务器地址
   - 显示最后活跃时间

3. **设备管理**
   - 获取当前可添加的 HA 设备列表
   - 搜索和过滤设备
   - 查看设备详细信息
   - 添加设备到 LinkLinkEdge 服务
   - 管理已添加的设备

## 使用方法

1. 启动 ha2devicehub 服务
2. 在浏览器中访问 `http://localhost:1691` 或 `http://your-server:1691`
3. 在 "HA Token 设置" 区域输入你的 Home Assistant 长期访问令牌
4. 点击 "保存 Token" 按钮
5. 等待连接状态显示为 "在线"
6. 点击 "刷新设备列表" 获取可添加的设备
7. 浏览设备列表，点击 "详情" 查看设备信息
8. 点击 "添加" 将设备添加到 LinkLinkEdge 服务

## 获取 HA Token

1. 登录 Home Assistant 管理界面
2. 点击左下角的用户头像
3. 滚动到底部，找到 "长期访问令牌" 部分
4. 点击 "创建令牌"
5. 输入令牌名称（如 "HA2Devicehub"）
6. 点击 "确定" 并复制生成的令牌

## 技术特性

- 响应式设计，支持移动设备
- 现代化的 UI 界面
- 实时状态更新
- 错误处理和用户反馈
- 设备搜索和过滤功能

## 文件结构

```
frontend/
├── index.html      # 主页面
├── styles.css      # 样式文件
├── script.js       # JavaScript 逻辑
└── README.md       # 说明文档
```

## API 接口

前端与后端通过以下 API 接口通信：

- `POST /ha2devicehub/settoken` - 设置 HA Token
- `GET /ha2devicehub/hainfo` - 获取 HA 连接信息
- `GET /ha2devicehub/gethaentity` - 获取可添加设备列表
- `POST /ha2devicehub/addhaentity` - 添加设备到服务

## 注意事项

- 确保 Home Assistant 服务正在运行
- 确保网络连接正常
- 定期更新 HA Token 以确保连接稳定
- 添加设备后需要等待一段时间才能在 LinkLinkEdge 服务中看到
