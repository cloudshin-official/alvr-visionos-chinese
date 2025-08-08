# ALVR Vision Pro 中文版技术文档

本文档详细说明了中文版的所有修改和技术实现细节。

## 项目定位

这是一个独立维护的ALVR Vision Pro中文版本，专门针对中文用户的使用习惯进行优化。我们不打算将这些修改合并回原项目，而是作为一个独立的分支持续更新。

## 已完成的修改

### 1. 界面汉化
- ✅ 主界面所有文本已汉化为简体中文
- ✅ 设置界面完全汉化
- ✅ 错误提示和对话框汉化
- ✅ 连接状态信息汉化

### 2. 界面重新设计
- ✅ 窗口大小调整为 1024x768
- ✅ 采用更简洁的界面布局
- ✅ 主界面采用大圆形按钮设计
- ✅ 设置和IP管理采用弹出式面板

### 3. IP地址管理功能
- ✅ 新增电脑IP地址管理功能
- ✅ 支持添加多个电脑IP地址
- ✅ 支持选择当前连接的电脑
- ✅ 支持删除已保存的IP地址
- ✅ IP地址自动保存到本地

### 4. 界面布局说明

#### 主界面
- 顶部：显示ALVR logo和版本/IP信息
- 中间：大型圆形开始/停止按钮
- 底部：设置、电脑管理、帮助三个功能按钮

#### 设置面板
- 主要设置：基础选项如手部显示、系统叠加等
- 高级设置：实验性功能和高级选项

#### IP管理面板
- 添加新IP地址
- 管理已保存的IP地址列表
- 选择当前要连接的电脑

## 使用说明

1. **首次使用**：
   - 点击"电脑管理"按钮
   - 输入您的电脑IP地址（例如：192.168.1.100）
   - 点击"添加"保存IP地址

2. **连接电脑**：
   - 在电脑管理中选择要连接的电脑
   - 等待连接成功后，中间的按钮会变为蓝色
   - 点击"开始串流"按钮开始使用

3. **设置调整**：
   - 点击"设置"按钮打开设置面板
   - 根据需要调整各项设置
   - 设置会自动保存

## 技术细节

### 修改的文件
1. `ALVRClient/Entry/Entry.swift` - 主界面重新设计
2. `ALVRClient/Entry/EntryControls.swift` - 控制按钮重新设计
3. `ALVRClient/ALVRClientApp.swift` - 应用程序入口汉化
4. `ALVRClient/GlobalSettings.swift` - 添加IP地址保存功能
5. `ALVRClient/EventHandler.swift` - 连接状态文本汉化

### 新增功能
- IP地址管理系统
- 弹出式设置面板
- 简化的用户界面

## 编译说明

请使用 Xcode 打开 `ALVRClient.xcodeproj` 项目文件进行编译。

确保您的开发环境：
- Xcode 15.0 或更高版本
- visionOS SDK
- 有效的开发者账号（用于设备调试）

## 与原版的主要差异

### 设计理念
- **原版**：简洁的单页面设计，自动发现为主
- **中文版**：多标签页设计，支持手动IP管理

### 用户体验
- **原版**：国际化设计，英文界面
- **中文版**：完全中文化，更大的按钮和更清晰的状态提示

### 功能增强
- IP地址管理系统（原版没有）
- 更详细的连接状态显示
- 分组的设置页面

## 维护计划

1. **定期同步**：每月检查原版更新，合并重要的功能和修复
2. **独立功能**：根据中文用户反馈添加新功能
3. **社区驱动**：欢迎中文用户提出建议和贡献代码

## 已知限制

1. 界面文本硬编码为中文，不支持语言切换
2. 窗口大小固定，不支持自由调整
3. 某些visionOS 2.0特性可能需要进一步优化

## 贡献指南

如果您想为本项目贡献代码：

1. Fork 本仓库
2. 创建您的特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交您的修改 (`git commit -m '添加某个很棒的功能'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启一个 Pull Request

请确保您的代码：
- 保持中文注释和文档
- 遵循现有的代码风格
- 在真实设备上测试过

## 联系方式

- GitHub Issues: [提交问题](https://github.com/caidingding233/alvr-visionos-chinese/issues)
- 项目主页: [https://github.com/caidingding233/alvr-visionos-chinese](https://github.com/caidingding233/alvr-visionos-chinese)

---  
# 以下是原版ALVR苹果版的介绍 如果需要可以自己看
---

# ALVR for Apple visionOS

This repository hosts the platform-specific code for the Apple visionOS client.

## Building

See the [Building](https://github.com/alvr-org/alvr-visionos/wiki/Building) wiki page for detailed instructions.
