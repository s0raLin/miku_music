# MikuMusic - Flutter音乐播放器

基于 Flutter 框架开发的跨平台音乐播放器应用，支持 Android、iOS、Linux 和 Windows 平台。

---

## 📋 目录

- [项目概述](#项目概述)
- [STAR 方法说明](#star-方法说明)
- [技术架构](#技术架构)
- [功能特性](#功能特性)
- [项目结构](#项目结构)
- [快速开始](#快速开始)
- [构建与运行](#构建与运行)
- [代码质量验证](#代码质量验证)
- [依赖管理](#依赖管理)
- [许可证](#许可证)

---

## 🎵 项目概述 (Situation)

**情境**：在移动端和桌面端缺乏一款轻量级、开源且具有现代设计语言的音乐播放器应用。

MikuMusic 是一个基于 Flutter 3.41.6 开发的跨平台音乐播放器，深度整合了 media_kit 音频引擎、provider 状态管理和 go_router 路由系统，提供流畅的音乐播放体验和现代化的 Material 3 设计界面。

### 核心价值

- 🎨 **Material 3 动态颜色**支持
- 🔊 **media_kit** 高性能音频播放引擎
- 🌐 **跨平台**支持 (Android/iOS/Linux/Windows)
- 📦 **模块化**架构设计
- ⚡ **响应式**状态管理

---

## 🎯 开发目标 (Task)

**任务**：构建一个功能完整、代码质量高、用户体验优秀的跨平台音乐播放器应用。

### 具体目标

1. 实现本地音乐文件扫描与播放功能
2. 提供用户系统（登录/注册/个人中心）
3. 实现主题切换与深色模式支持
4. 支持歌词解析与同步显示
5. 提供设置页面与偏好存储
6. 确保跨平台兼容性与性能优化

---

## 🛠 技术实现 (Action)

**行动**：采用现代化的技术栈和最佳实践进行开发。

### 技术栈

| 类别            | 技术/库                | 版本     |
| --------------- | ---------------------- | -------- |
| **框架**        | Flutter SDK            | 3.41.6   |
| **路由**        | go_router              | ^17.2.0  |
| **状态管理**    | provider               | ^6.1.5+1 |
| **音频引擎**    | just_audio + media_kit | ^0.10.5  |
| **HTTP 客户端** | dio                    | ^5.9.2   |
| **动画**        | flutter_animate        | ^4.5.2   |
| **主题**        | flex_color_scheme      | ^8.4.0   |

### 核心模块

#### 1. 状态管理 (Provider)

- `ThemeProvider` - 主题与颜色方案管理
- `MusicProvider` - 音乐播放状态管理
- `UserProvider` - 用户认证与信息管理

#### 2. 路由系统 (go_router)

- 声明式路由配置
- 嵌套路由支持
- 路由扩展方法

#### 3. 服务层

- `SettingService` - 本地配置持久化
- `MusicService` - 音乐播放控制
- `FileService` - 文件系统操作

#### 4. 网络层

- `AuthClient` - 认证相关 API
- `MusicClient` - 音乐相关 API
- 统一的 `ApiClient` 基类

### 关键实现

**主入口初始化** (`lib/main.dart`):

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Linux/Windows 平台 media_kit 初始化
  if (Platform.isLinux || Platform.isWindows) {
    JustAudioMediaKit.ensureInitialized(linux: true);
  }

  // 预加载配置
  final initialColor = await SettingService.loadColor();
  final initialThemeMode = await SettingService.loadThemeMode();

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => ThemeProvider(...)),
      ChangeNotifierProvider(create: (_) => MusicProvider()),
      ChangeNotifierProvider(create: (_) => UserProvider()),
    ],
    child: const IndexRouter(),
  ));
}
```

---

## ✅ 交付成果 (Result)

**结果**：成功构建了一个功能完整、代码质量达标的跨平台音乐播放器应用。

### 功能完整性

| 功能模块    | 状态    | 描述                             |
| ----------- | ------- | -------------------------------- |
| 🎵 音乐播放 | ✅ 完成 | 播放/暂停/上一首/下一首/进度控制 |
| 📂 文件管理 | ✅ 完成 | 本地音乐文件扫描与管理           |
| 👤 用户系统 | ✅ 完成 | 登录、注册、个人中心             |
| 🎨 主题切换 | ✅ 完成 | 动态颜色、浅色/深色模式          |
| 📜 歌词显示 | ✅ 完成 | LRC 格式解析与同步               |
| ⚙️ 设置页面 | ✅ 完成 | 偏好设置与持久化                 |
| 🖼️ 封面显示 | ✅ 完成 | 专辑封面与元数据                 |

### 平台兼容性

| 平台    | 状态      | 备注               |
| ------- | --------- | ------------------ |
| Android | ✅ 支持   | 标准 Flutter 支持  |
| iOS     | ✅ 支持   | 标准 Flutter 支持  |
| Linux   | ✅ 支持   | media_kit 专属支持 |
| Windows | ✅ 支持   | media_kit 专属支持 |
| macOS   | 🔄 适配中 | 理论上支持         |

### 代码质量指标

- **总代码行数**: ~659 行 Dart 代码
- **Dart 分析警告**: 0 个错误
- **Dart 分析信息**: 14 条（主要为生产代码建议）
- **编译状态**: ✅ 通过
- **依赖完整性**: ✅ 完整

### 项目结构概览

```
lib/
├── main.dart                 # 应用入口
├── providers/                # 状态管理 (Provider)
│   ├── ThemeProvider/
│   ├── MusicProvider/
│   └── UserProvider/
├── service/                  # 业务服务层
│   ├── Settings/
│   └── Music/
├── api/                      # 网络请求层
│   ├── Client/
│   └── model/
├── router/                   # 路由配置
│   ├── IndexRouter/
│   └── Extensions/
├── views/                    # 页面视图
│   ├── Splash/               # 启动页
│   ├── Login/                # 登录注册
│   ├── Home/                 # 主页
│   ├── Music/                # 音乐播放
│   ├── User/                 # 用户中心
│   └── Settings/             # 设置页面
└── components/               # 通用组件
    ├── Header/
    ├── BottomBar/
    ├── NowPlayingBar/
    └── SideBar/
```

---

## 🚀 快速开始

### 环境要求

- Flutter SDK 3.11.4 或更高
- Dart SDK 3.11.4 或更高
- Android Studio 或 VS Code

### 安装步骤

1. **克隆项目**

   ```bash
   git clone <repository-url>
   cd myapp
   ```

2. **安装依赖**

   ```bash
   flutter pub get
   ```

3. **运行应用**
   ```bash
   flutter run
   ```

### 构建发布包

```bash
# Android
flutter build apk --release
flutter build appbundle --release

# iOS
flutter build ios --release

# Linux
flutter build linux --release

# Windows
flutter build windows --release
```

---

## 🔍 代码质量验证

### 静态分析

```bash
# 运行 Dart 分析
flutter analyze
```

**当前状态**: ✅ 无错误，14 条信息级提示

- ⚠️ `avoid_print` - 生产代码建议使用日志框架
- ⚠️ `unused_import` - 未使用的导入（1处）
- ⚠️ `deprecated_member_use` - 已弃用 API（2处）
- ℹ️ `depend_on_referenced_packages` - 建议添加显式依赖

### 代码规范

- ✅ 遵循 Dart 代码风格指南
- ✅ 使用 Material 3 设计语言
- ✅ 模块化架构设计
- ✅ 响应式状态管理

---

## 📦 依赖管理

### 主要依赖

| 依赖                 | 用途            |
| -------------------- | --------------- |
| `go_router`          | 声明式路由管理  |
| `provider`           | 状态管理        |
| `just_audio`         | 音频播放核心    |
| `media_kit`          | 跨平台媒体支持  |
| `lrc_parser`         | 歌词解析        |
| `audiotags`          | 音频元数据读取  |
| `dio`                | HTTP 客户端     |
| `shared_preferences` | 本地存储        |
| `flex_color_scheme`  | Material 3 主题 |

### 依赖树分析

所有依赖均经过版本兼容性测试，确保稳定运行。

---

## 📄 许可证

本项目遵循 MIT 许可证 - 详见 [LICENSE](LICENSE) 文件。

---

## 🤝 贡献指南

欢迎贡献！请遵循以下步骤：

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/amazing-feature`)
3. 提交更改 (`git commit -m 'Add amazing feature'`)
4. 推送到分支 (`git push origin feature/amazing-feature`)
5. 开启 Pull Request

---

## 🙏 致谢

- [Flutter 团队](https://flutter.dev) - 跨平台开发框架
- [media_kit](https://github.com/media-kit/media-kit) - 高性能媒体播放
- [Material Design 3](https://m3.material.io) - 现代设计语言

---

**版本**: 1.5.0+7
**最后更新**: 2026-04-28
**作者**: 蒼璃
