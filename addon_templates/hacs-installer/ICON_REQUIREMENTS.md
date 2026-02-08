# Icon.png 生成要求

本文档说明如何为 Haddons Addon 创建合适的 `icon.png` 图标文件。

## 基本要求

### 文件格式
- **格式**: PNG（推荐）或 SVG（需要转换为 PNG）
- **文件名**: `icon.png`（必须使用此文件名）

### 尺寸规格
- **推荐尺寸**: 512x512 像素（正方形）
- **最小尺寸**: 256x256 像素
- **最大尺寸**: 1024x1024 像素
- **宽高比**: 1:1（必须为正方形）

### 文件大小
- **推荐大小**: < 100 KB
- **最大大小**: < 500 KB

## 设计规范

### 视觉要求
- **背景**: 建议使用透明背景或单色背景
- **图标**: 清晰、简洁、易于识别
- **颜色**: 使用鲜明的颜色，确保在小尺寸下也能清晰可见
- **风格**: 建议使用扁平化设计风格，与 Haddons 界面风格一致

### 内容要求
- **主题**: 图标应该与 Addon 的功能相关
- **可识别性**: 在 64x64 像素的小尺寸下仍然清晰可辨
- **一致性**: 如果是一系列 Addon，保持风格统一

## 设计建议

### 图标类型
- **功能图标**: 使用与 Addon 功能相关的图标（如 WiFi、网络、数据库等）
- **品牌图标**: 如果 Addon 有特定品牌，可以使用品牌标识
- **抽象图标**: 使用抽象的几何图形表示功能

### 常用图标库
- [Material Design Icons](https://materialdesignicons.com/)
- [Font Awesome](https://fontawesome.com/)
- [Feather Icons](https://feathericons.com/)
- [Heroicons](https://heroicons.com/)

### 颜色方案
- 使用 Material Design 颜色规范
- 确保有足够的对比度
- 避免使用过于相似的颜色

## 生成方法

### 方法一：使用在线工具
1. 访问 [Canva](https://www.canva.com/) 或 [Figma](https://www.figma.com/)
2. 创建 512x512 像素的画布
3. 设计图标
4. 导出为 PNG 格式（透明背景）

### 方法二：使用设计软件
1. 使用 Adobe Illustrator、Photoshop、GIMP 等工具
2. 创建 512x512 像素的画布
3. 设计图标
4. 导出为 PNG 格式

### 方法三：使用命令行工具（从 SVG 转换）
```bash
# 使用 ImageMagick
convert icon.svg -resize 512x512 icon.png

# 使用 Inkscape
inkscape icon.svg --export-filename=icon.png --export-width=512 --export-height=512
```

### 方法四：使用 Python 脚本
```python
from PIL import Image, ImageDraw

# 创建 512x512 的透明背景图片
img = Image.new('RGBA', (512, 512), (0, 0, 0, 0))
draw = ImageDraw.Draw(img)

# 绘制图标（示例：圆形）
draw.ellipse([100, 100, 412, 412], fill=(66, 133, 244, 255))

# 保存
img.save('icon.png', 'PNG')
```

## 验证检查清单

在提交 icon.png 之前，请确认：

- [ ] 文件名为 `icon.png`（小写）
- [ ] 尺寸为正方形（宽高比 1:1）
- [ ] 尺寸在 256x256 到 1024x1024 之间
- [ ] 文件大小 < 500 KB
- [ ] 图标清晰，在小尺寸下可识别
- [ ] 背景透明或单色
- [ ] 图标与 Addon 功能相关

## 示例

### Network Manager 图标建议
- **主题**: WiFi/网络连接
- **图标**: WiFi 信号图标、网络节点图标
- **颜色**: 蓝色系（表示网络/连接）
- **风格**: 扁平化、简洁

### 其他 Addon 图标建议
- **数据库 Addon**: 数据库图标
- **监控 Addon**: 图表/仪表盘图标
- **存储 Addon**: 存储/硬盘图标
- **API Addon**: 连接/API 图标

## 注意事项

1. **版权**: 确保使用的图标素材有合法的使用权限
2. **原创性**: 尽量使用原创设计或免费可商用的图标
3. **测试**: 在 Haddons Web 界面中测试图标显示效果
4. **更新**: 如果 Addon 功能变更，考虑更新图标以反映新功能
