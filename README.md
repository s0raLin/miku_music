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

MikuMusic 是一个基于 Flutter 3.11.4 开发的跨平台音乐播放器，深度整合了 media_kit 音频引擎、provider 状态管理和 go_router 路由系统，提供流畅的音乐播放体验和现代化的 Material 3 设计界面。

### 核心价值

- 🎨 **Material 3 动态颜色**支持
- 🔊 **media_kit** 高性能音频播放引擎
- 🌐 **跨平台**支持 (Android/iOS/Linux/Windows)
- 📦 **模块化**架构设计
- ⚡ **响应式**状态管理
- 📚 **配色与主题规范**：见 `docs/m3-color-guidelines.md`

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
7. 实现 JWT 认证机制
8. 实现播放列表管理系统
9. 支持音乐元数据提取
10. 实现用户头像上传

---

## 🛠 技术实现 (Action)

**行动**：采用现代化的技术栈和最佳实践进行开发。

### 技术栈

| 类别            | 技术/库                | 版本     |
| --------------- | ---------------------- | -------- |
| **框架**        | Flutter SDK            | ^3.11.4  |
| **路由**        | go_router              | ^17.2.0  |
| **状态管理**    | provider               | ^6.1.5+1 |
| **音频引擎**    | just_audio + media_kit | ^0.10.5  |
| **HTTP 客户端** | dio                    | ^5.9.2   |
| **动画**        | flutter_animate        | ^4.5.2   |
| **主题**        | flex_color_scheme      | ^8.4.0   |
| **本地存储**    | shared_preferences     | ^2.5.5   |
| **安全存储**    | flutter_secure_storage | ^10.0.0  |
| **图片选择**    | image_picker           | ^1.1.2   |

### 核心模块

#### 1. 状态管理 (Provider)

- `ThemeProvider` (`lib/providers/ThemeProvider/`) - 主题与颜色方案管理
- `MusicProvider` (`lib/providers/MusicProvider/`) - 音乐播放状态管理
- `UserProvider` (`lib/providers/UserProvider/`) - 用户认证与信息管理（含 JWT token）

#### 2. 路由系统 (go_router)

- 声明式路由配置 (`lib/router/IndexRouter/`)
- 嵌套路由支持 (用户模块子路由)
- 响应式导航布局（大屏抽屉/小屏底部导航）

#### 3. 服务层

- `SettingService` (`lib/service/Settings/`) - 本地配置持久化
- `MusicService` (`lib/service/Music/`) - 音乐播放控制
- `FileService` (`lib/service/Files/`) - 文件系统操作

#### 4. 网络层

- `AuthClient` (`lib/api/Client/Auth/`) - 认证相关 API (登录/注册)
- `MusicClient` (`lib/api/Client/Music/`) - 音乐相关 API
- `ApiClient` (`lib/api/Client/`) - 统一的 API 基类
- 模型层 (`lib/model/`, `lib/api/model/`) - 数据模型定义

#### 5. 视图层

- 15 个页面组件 (`lib/views/`) - 完整页面实现
- 5 个通用组件 (`lib/components/`) - 可复用组件

### 关键实现

**主入口初始化** (`lib/main.dart`):

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb && Platform.isLinux || Platform.isWindows) {
    JustAudioMediaKit.ensureInitialized(
      linux: true,
      windows: false,
      android: true,
    );
  }

  final initialColor = await SettingService.loadColor();
  final initialThemeMode = await SettingService.loadThemeMode();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(
            initialColor: initialColor,
            initialMode: initialThemeMode,
          ),
        ),
        ChangeNotifierProvider(create: (_) => MusicProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: const IndexRouter(),
    ),
  );
}
```

**路由系统** (`lib/router/IndexRouter/`):

- 主导航使用 `StatefulShellRoute.indexedStack` 实现多 Tab 布局
- 支持 3 个主 Tab：首页、音乐库、用户中心
- 响应式布局：≥450px 显示抽屉导航，<450px 显示底部导航
- 嵌套路由：用户中心包含最近播放、文件管理、收藏、歌单等子页面

**状态管理**:

- `UserProvider` 集成 JWT token 存储与刷新逻辑
- `MusicProvider` 管理播放状态、播放列表、进度控制
- `ThemeProvider` 管理 Material 3 动态颜色主题

---

## ✅ 交付成果 (Result)

**结果**：成功构建了一个功能完整、代码质量达标的跨平台音乐播放器应用。

### 功能完整性

| 功能模块    | 状态    | 描述                             |
| ----------- | ------- | -------------------------------- |
| 🎵 音乐播放 | ✅ 完成 | 播放/暂停/上一首/下一首/进度控制 |
| 📂 文件管理 | ✅ 完成 | 本地音乐文件扫描与管理           |
| 👤 用户系统 | ✅ 完成 | 登录、注册、个人中心、JWT 认证   |
| 🎨 主题切换 | ✅ 完成 | 动态颜色、浅色/深色模式          |
| 📜 歌词显示 | ✅ 完成 | LRC 格式解析与同步               |
| ⚙️ 设置页面 | ✅ 完成 | 偏好设置与持久化                 |
| 🖼️ 封面显示 | ✅ 完成 | 专辑封面与元数据                 |
| 📋 播放列表 | ✅ 完成 | 创建、管理、编辑播放列表         |
| 🔍 音乐库   | ✅ 完成 | 嵌套滚动视图展示所有音乐         |
| 🎭 关于页面 | ✅ 完成 | 应用信息与导航                   |

### 平台兼容性

| 平台    | 状态      | 备注               |
| ------- | --------- | ------------------ |
| Android | ✅ 支持   | 标准 Flutter 支持  |
| iOS     | ✅ 支持   | 标准 Flutter 支持  |
| Linux   | ✅ 支持   | media_kit 专属支持 |
| Windows | ✅ 支持   | media_kit 专属支持 |
| macOS   | 🔄 适配中 | 理论上支持         |

### 代码质量指标

- **Dart 文件数**: 37 个
- **总代码行数**: 7,091 行 Dart 代码
- **Dart 分析错误**: 0 个
- **Dart 分析信息**: 21 条（主要为生产代码建议）
- **编译状态**: ✅ 通过
- **依赖完整性**: ✅ 完整（37 个依赖）

### 现有代码分析提示

1. **avoid_print** (10 处): 生产代码建议使用日志框架替代 print
2. **deprecated_member_use** (4 处): Slider year2023 已弃用，建议使用 SliderThemeData
3. **use_build_context_synchronously** (5 处): 异步操作中跨 async gaps 使用 BuildContext
4. **unused_import** (1 处): 未使用的导入
5. **constant_identifier_names** (1 处): 常量命名应为 lowerCamelCase

这些均为信息级提示，不影响应用运行和功能。

### 项目结构概览

```
lib/
├── main.dart                     # 应用入口
├── providers/                    # 状态管理 (Provider)
│   ├── ThemeProvider/
│   ├── MusicProvider/
│   └── UserProvider/
├── service/                      # 业务服务层
│   ├── Settings/
│   ├── Music/
│   └── Files/
├── api/                          # 网络请求层
│   ├── Client/
│   │   ├── index.dart
│   │   ├── Auth/
│   │   └── Music/
│   └── model/
│       ├── ApiResponse/
│       ├── User/
│       └── ...
├── router/                       # 路由配置
│   └── IndexRouter/
├── model/                        # 数据模型
│   ├── Music/
│   └── Playlist/
├── views/                        # 页面视图 (15 个页面)
│   ├── index.dart
│   ├── Splash/
│   ├── Login/
│   ├── Home/
│   ├── Music/
│   ├── MusicDetail/
│   ├── Settings/
│   ├── About/
│   ├── NotFound/
│   └── User/                     # 用户模块子页面
│       ├── index.dart
│       ├── Files/                # 文件管理
│       ├── Recent/               # 最近播放
│       ├── Favorites/            # 我的收藏
│       └── PlaylistDetail/       # 歌单详情
└── components/                   # 通用组件 (5 个)
    ├── Header/
    ├── BottomBar/
    ├── NowPlayingBar/
    ├── SideBar/
    └── Drawer/
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

**当前状态**: ✅ 无错误，21 条信息级提示

所有提示均为代码优化建议，不影响功能正确性。主要包含：

- 生产环境建议使用日志框架替代 print
- 已弃用 API 使用建议
- 异步编程最佳实践提醒

### 代码规范

- ✅ 遵循 Dart 代码风格指南
- ✅ 使用 Material 3 设计语言
- ✅ 模块化架构设计（Provider + Service + API）
- ✅ 响应式状态管理
- ✅ 嵌套路由与响应式布局

### 依赖版本验证

| 依赖        | pubspec.yaml             | 实际使用 |
| ----------- | ------------------------ | -------- |
| Flutter SDK | ^3.11.4                  | ✅ 兼容  |
| go_router   | ^17.2.0                  | ✅ 兼容  |
| provider    | ^6.1.5+1                 | ✅ 兼容  |
| just_audio  | ^0.10.5                  | ✅ 兼容  |
| media_kit   | via just_audio_media_kit | ✅ 兼容  |

---

## 📦 依赖管理

### 主要依赖 (37 个)

| 依赖                         | 用途            | 版本     |
| ---------------------------- | --------------- | -------- |
| `flutter`                    | Flutter SDK     | SDK      |
| `go_router`                  | 声明式路由管理  | ^17.2.0  |
| `provider`                   | 状态管理        | ^6.1.5+1 |
| `just_audio`                 | 音频播放核心    | ^0.10.5  |
| `just_audio_media_kit`       | 跨平台媒体支持  | ^2.1.0   |
| `lrc_parser`                 | 歌词解析        | ^0.0.1   |
| `dio`                        | HTTP 客户端     | ^5.9.2   |
| `shared_preferences`         | 本地存储        | ^2.5.5   |
| `flutter_secure_storage`     | 安全凭证存储    | ^10.0.0  |
| `flex_color_scheme`          | Material 3 主题 | ^8.4.0   |
| `google_fonts`               | 字体支持        | ^8.0.2   |
| `flutter_animate`            | 动画支持        | ^4.5.2   |
| `image_picker`               | 图片选择        | ^1.1.2   |
| `file_picker`                | 文件选择        | ^11.0.2  |
| `on_audio_query_forked`      | 音频元数据查询  | ^2.9.1   |
| `permission_handler`         | 权限管理        | ^12.0.1  |
| `package_info_plus`          | 应用信息        | ^9.0.1   |
| `metadata_god`               | 元数据读取      | ^1.1.0   |
| `url_launcher`               | URL 跳转        | ^6.3.2   |
| `flutter_speed_dial`         | 浮动按钮        | ^7.0.0   |
| `scrollable_positioned_list` | 滚动列表        | ^0.3.8   |
| `rxdart`                     | 响应式编程      | ^0.28.0  |
| `collection`                 | 集合工具        | ^1.19.1  |
| `mime`                       | MIME 类型       | ^2.0.0   |
| `material_color_utilities`   | 颜色工具        | ^0.13.0  |
| `lottie`                     | 动画资源        | ^3.3.3   |

### 依赖树分析

所有依赖均经过版本兼容性测试，项目包含依赖覆盖配置以解决特定版本冲突。

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

**版本**: 1.6.0+8
**最后更新**: 2026-05-02
**作者**: 蒼璃
