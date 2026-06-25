# M3Music

![Build macOS](https://github.com/s0raLin/miku_music/actions/workflows/build-macos.yml/badge.svg)
![Build Windows](https://github.com/s0raLin/miku_music/actions/workflows/build-windows.yml/badge.svg)
![Version](https://img.shields.io/badge/version-1.50.0%2B56-blue)

基于 Flutter + Rust 的跨平台本地音乐播放器，支持本地音乐扫描与管理、在线歌曲搜索/流媒体播放、网易云歌单导入、歌词在线搜索、Material 3 主题定制、系统托盘与全局热键。

## 项目概览

- 应用入口：[lib/main.dart](lib/main.dart)，启动时执行 `InitializationService.preRunInit()` → 初始化 Rust FFI、SQLite、环境变量、窗口管理器、音频引擎，随后注册 `audio_service` 后台播放服务。
- 全局状态通过 `provider` 管理，注册 6 个 Provider：
  - `ThemeProvider` — 主题、设置项
  - `MusicProvider` — 播放控制、乐库、队列、歌词
  - `PlaylistProvider` — 歌单 CRUD（依赖 MusicProvider）
  - `UserProvider` — 用户登录状态
  - `NavProvider` — 导航状态
  - `StartupProvider` — 启动流程编排
- 路由由 [lib/router/IndexRouter/index.dart](lib/router/IndexRouter/index.dart) 实现，使用 `go_router` + `StatefulShellRoute.indexedStack`，初始路由为 `/splash`。
- 定位为"本地音乐优先"的播放器，同时支持在线歌曲搜索与流媒体播放。

## 完整功能列表

以下所有功能均与代码实现一一验证：

### 1. 启动与初始化

- 启动页：[lib/views/Splash/index.dart](lib/views/Splash/index.dart)，展示初始化进度（4 步）和失败重试。
- 初始化流程由 [lib/providers/StartupProvider/index.dart](lib/providers/StartupProvider/index.dart) 编排：
  1. **加载界面设置** — 主题色、主题模式、列表密度、音质等全量偏好
  2. **扫描本地音乐** — 调用 Rust 并行扫描已保存的目录
  3. **恢复播放器状态** — 重建乐库、播放队列、收藏、历史、歌单
  4. **启动完成** — 进入首页
- Android 首次启动跳转 [lib/views/SetupWizard/index.dart](lib/views/SetupWizard/index.dart) 申请存储权限。
- 桌面端首次启动自动将 `~/Downloads/M3Music` 加入扫描列表。

### 2. 路由与界面结构

- 主导航（`StatefulShellRoute`）包含 4 个一级页面：

| 路由             | 页面            | 说明                                                  |
| ---------------- | --------------- | ----------------------------------------------------- |
| `/home`          | HomePage        | 首页（排行榜、推荐）                                  |
| `/music`         | MusicPage       | 本地音乐库（歌曲/专辑/歌单三个标签页）                |
| `/network-songs` | NetworkSongPage | 网络歌曲搜索与播放                                    |
| `/user`          | UserProfilePage | 我的（歌单/收藏/最近播放/文件管理/下载管理/个人资料） |

- 次级路由包括：

| 路由                       | 页面                                               |
| -------------------------- | -------------------------------------------------- |
| `/splash`                  | SplashPage (启动页)                                |
| `/setup`                   | SetupWizardScreen (权限引导)                       |
| `/login`                   | LoginPage (登录/注册)                              |
| `/settings`                | SettingsPage (设置)                                |
| `/about`                   | AboutPage (关于)                                   |
| `/search`                  | SearchPage (搜索)                                  |
| `/music-detail`            | MusicDetailPage (播放详情, 含从底部弹出的过渡动画) |
| `/toplist`                 | ToplistDetailPage (排行榜详情)                     |
| `/update-download`         | UpdateDownloadPage (更新下载)                      |
| `/playlist-edit/:id`       | PlaylistEditPage (编辑歌单)                        |
| `/user/files`              | FilesPage (文件目录管理)                           |
| `/user/files/album-detail` | AlbumDetailPage (专辑详情)                         |
| `/user/network`            | NetWorkPage (网络云盘)                             |
| `/user/recent`             | RecentlyPlayedPage (最近播放)                      |
| `/user/playlist/favorites` | FavoritesPage (我喜欢)                             |
| `/user/playlist/:id`       | PlaylistDetailPage (歌单详情)                      |
| `/user/edit-profile`       | EditProfilePage (编辑资料)                         |
| `/user/downloads`          | DownloadManagementPage (下载管理)                  |
| `/user/profile`            | UserProfileViewPage (查看资料)                     |

- 主界面在 [lib/views/index.dart](lib/views/index.dart) 中根据屏幕宽度自适应：
  - `>= 450px` → 侧边栏（`SideBar`）+ 内容区 + 播放条
  - `< 450px` → 底部导航栏（`BottomBar`）+ 播放条 + `NowPlayingMiniFab`

### 3. 音频播放引擎

- 使用 `just_audio` + `audio_service` 实现后台音频播放与系统通知控制。
- `MyAudioHandler` ([lib/service/Audio/index.dart](lib/service/Audio/index.dart)) 继承 `BaseAudioHandler`，支持：
  - 播放/暂停、上一首/下一首
  - Android 通知栏媒体控制（含封面、标题、歌手）
  - 系统媒体会话集成
- 音频后端使用 `media_kit`（`just_audio_media_kit`），桌面端支持 Linux/Windows/macOS 原生音频输出。

### 4. 音乐库与播放队列

- `MusicProvider` 由三个模块组成：
  - `MusicLibrary` ([lib/providers/MusicProvider/music_library.dart](lib/providers/MusicProvider/music_library.dart)) — 歌曲排序（自动/名称/专辑/时长）、专辑排序、分组
  - `MusicQueue` ([lib/providers/MusicProvider/music_queue.dart](lib/providers/MusicProvider/music_queue.dart)) — 队列增删替换清空、三种播放模式：
    - 顺序播放（`PlayMode.sequential`）
    - 随机播放（`PlayMode.shuffle`）
    - 单曲循环（`PlayMode.singleRepeat`）
  - `MusicRepository` ([lib/providers/MusicProvider/music_repository.dart](lib/providers/MusicProvider/music_repository.dart)) — 封面加载缓存、网络歌曲元数据持久化、歌词搜索调度
- 本地扫描由 [lib/service/Music/index.dart](lib/service/Music/index.dart) 调用 Rust 层：
  - [rust/src/api/scanner.rs](rust/src/api/scanner.rs) 使用 `jwalk` 并行递归遍历目录
  - [rust/src/api/audio_info.rs](rust/src/api/audio_info.rs) 使用 `lofty` 读取元数据（标题、歌手、专辑、时长、封面）
  - 支持格式：MP3 / FLAC / M4A / WAV / OGG
  - 自动读取同目录同名 `.lrc` 歌词文件
- 扫描目录持久化到 `SharedPreferences`，由 [lib/service/Files/index.dart](lib/service/Files/index.dart) 管理。

### 5. 网络歌曲与流媒体

- 网络歌曲搜索：[lib/views/Network/index.dart](lib/views/Network/index.dart) + [lib/api/Client/Netease/index.dart](lib/api/Client/Netease/index.dart)
  - 通过 Node.js 代理服务器（`typescript/server.js`，使用 `meting` 库）搜索网易云等平台的歌曲
  - 获取真实流媒体 URL 并直接播放
  - 支持 HTTPS 封面图片自动修正
- 网络歌曲元数据由 [lib/service/NetworkSongStore/index.dart](lib/service/NetworkSongStore/index.dart) 持久化为 JSON 文件，跨启动恢复。
- 排行榜获取：[lib/api/Client/Music/index.dart](lib/api/Client/Music/index.dart) 调用 `/api/toplist` 接口。

### 6. Rust SQLite 数据库

- 由 `flutter_rust_bridge` 桥接，Rust 侧使用 `rusqlite`（bundled 模式）。
- 数据库文件位置：`{appDocDir}/m3_music.db`
- [rust/src/api/audio_db/mod.rs](rust/src/api/audio_db/mod.rs) 定义 `DbManager`，启动时自动建表（[rust/src/migrations/init.sql](rust/src/migrations/init.sql)）并创建系统歌单「我喜欢」。
- 子模块：
  - `songs` — 歌曲信息插入与查询
  - `playlists` — 歌单 CRUD、歌曲关联
  - `history` — 播放历史（支持上限裁剪）
  - `favorites` — 收藏/取消收藏
- Dart 侧封装：[lib/service/MusicDb/index.dart](lib/service/MusicDb/index.dart)

### 6. 歌词功能

- 本地歌词：自动读取与音频同名的 `.lrc` 文件，使用 `lrc_parser` 解析。
- 在线搜索：通过 [lrclib.net](https://lrclib.net) API（`MusicApi.searchLyrics`）按歌手+歌名搜索滚动歌词。
- 逐词高亮：支持逐词时间戳（`LyricWord`），使用 `ShaderMask` 实现卡拉 OK 风格实时着色。
- 翻译歌词：支持合并显示原始歌词和翻译行。
- 编辑保存：支持编辑当前歌词并保存到本地文件。

### 7. 网易云音乐集成

- 搜索与播放：[lib/api/Client/Netease/index.dart](lib/api/Client/Netease/index.dart)
- 通过 `typescript/` 下的 Express 代理服务器（端口 3000，配置键 `JS_BACKEND_URL`）调用网易云 API。
- 网易云工具类：[lib/utils/NetEaseCloud/index.dart](lib/utils/NetEaseCloud/index.dart)

### 8. 登录与后端接口

- 登录/注册页：[lib/views/Login/index.dart](lib/views/Login/index.dart)
- 认证接口：[lib/api/Client/Auth/index.dart](lib/api/Client/Auth/index.dart)
- 接口基地址：来自 `.env` 的 `GO_BACKEND_URL`（默认 `http://localhost:8000`），配置读取：[lib/config/index.dart](lib/config/index.dart)
- Go 后端 ([backend/](backend/))：
  - 框架：Gin
  - 功能：邮箱验证码注册/登录、密码登录、头像上传（阿里云 OSS）、修改密码、注销账号、音乐上传、歌单管理
  - JWT 鉴权中间件：[backend/middleware/jwtAuth.go](backend/middleware/jwtAuth.go)
  - Dockerfile 支持容器化部署
- 注意：本地音乐扫描与播放能力本身不依赖后端。

### 9. 主题与设置

- `ThemeProvider` ([lib/providers/ThemeProvider/index.dart](lib/providers/ThemeProvider/index.dart)) + `SettingService` ([lib/service/Settings/index.dart](lib/service/Settings/index.dart))
- 设置项（全部持久化到 SharedPreferences）：

| 设置项             | 可选值                                           | 默认值      |
| ------------------ | ------------------------------------------------ | ----------- |
| 主题模式           | 浅色 / 深色 / 跟随系统                           | 浅色        |
| 主题种子色         | 8 种预设色（含 Material 3 `tonalSpot` 动态配色） | `#C49B8A`   |
| 列表密度           | 紧凑 / 正常                                      | 正常        |
| 进度条样式         | 直线型 / 蛇形波浪                                | 蛇形波浪    |
| 音质选项           | 低 / 标准 / 高                                   | 标准        |
| 歌词页显示封面     | 开 / 关                                          | 开          |
| 启动时自动播放     | 开 / 关                                          | 关          |
| 通知栏显示详情     | 开 / 关                                          | 开          |
| 双击列表项快速播放 | 开 / 关                                          | 开          |
| 播放列表排序方式   | 添加时间 / 名称 / 随机                           | 添加时间    |
| 最大历史记录数量   | 50 / 100 / 300 / 500                             | 100         |
| 窗口置顶           | 开 / 关                                          | 关          |
| 应用图标           | 10 种可选图标（Android 动态图标）                | `app_icon1` |

- 主题使用 `ColorScheme.fromSeed` + `Blend.harmonize` 实现柔化色彩，搭配 `GoogleFonts.notoSansSc` 字体。
- 桌面端（Linux/Windows/macOS）关闭页面过渡动画。

### 10. 桌面端特性

- **系统托盘**：[lib/service/Tray/index.dart](lib/service/Tray/index.dart) — 显示图标、右键菜单（显示/隐藏窗口、退出）
- **关闭到托盘**：[lib/views/index.dart](lib/views/index.dart) 中 `onWindowClose` 拦截关闭事件，隐藏而非退出
- **全局热键**：[lib/service/Hotkeys/index.dart](lib/service/Hotkeys/index.dart) 调用 Rust 层（[rust/src/api/hotkey.rs](rust/src/api/hotkey.rs)）注册系统级快捷键：
  - `Ctrl + Alt + Space` — 播放/暂停
  - `Ctrl + Alt + →` — 下一首
  - `Ctrl + Alt + ←` — 上一首
- **Mini 模式**：隐藏播放条，仅显示悬浮播放按钮（`NowPlayingMiniFab`）
- **动态应用图标**（Android）：[lib/service/AppIcon/index.dart](lib/service/AppIcon/index.dart) — 通过 MethodChannel 切换 10 种图标

### 11. 其他功能

- **应用更新检查**：[lib/service/UpdateCheck/index.dart](lib/service/UpdateCheck/index.dart) — 通过 GitHub API 查询最新 Release，支持直接下载更新
- **搜索**：[lib/views/Search/index.dart](lib/views/Search/index.dart)
- **排行榜**：[lib/views/ToplistDetail/index.dart](lib/views/ToplistDetail/index.dart) + [lib/views/Home/widgets/toplist_card.dart](lib/views/Home/widgets/toplist_card.dart)
- **文件管理**：[lib/views/User/Files/index.dart](lib/views/User/Files/index.dart) — 按专辑分组浏览本地文件
- **下载管理**：[lib/views/User/DownloadManagement/index.dart](lib/views/User/DownloadManagement/index.dart)
- **均衡器**：配置存储在 `assets/Equalizer.json`
- **AGS 桌面组件**：`ags/` 目录包含 Aylur's GTK Shell (GNOME) 的 Dynamic Island 小组件

## 技术栈

### 前端

- **框架**: Flutter 3.x（Dart SDK `^3.11.4`）
- **状态管理**: `provider` + `ChangeNotifier`
- **路由**: `go_router`（`StatefulShellRoute.indexedStack`）
- **音频**: `just_audio` + `audio_service` + `media_kit`
- **HTTP**: `dio`
- **持久化**: `shared_preferences` / `flutter_secure_storage` / Rust SQLite
- **FFI**: `flutter_rust_bridge` v2.12.0

### Rust 核心

- **扫描**: `jwalk`（并行目录遍历）+ `lofty`（音频元数据解析）
- **数据库**: `rusqlite`（bundled SQLite）
- **热键**: `global-hotkey`（系统级快捷键注册）
- **序列化**: `serde` / `serde_json`

### 后端（可选）

- **Go**: `gin` + `gorm` + JWT + 阿里云 OSS
- **TypeScript**: `express` + `meting`（网易云 API 代理）

## 目录结构

```text
lib/
├── main.dart                  # 应用入口
├── api/
│   ├── Client/                # API 客户端（Auth/Music/Netease）
│   └── Model/                 # API 数据模型
├── components/                # 通用 UI 组件
│   ├── BottomBar/             # 底部导航栏
│   ├── Drawer/                # 侧边抽屉
│   ├── Header/                # 页面头部
│   ├── NowPlaying/            # 播放控制条 & MiniFab
│   ├── Shared/                # 共享组件（M3SongList 等）
│   └── SideBar/               # 侧边栏导航
├── config/                    # 环境配置（dotenv 读取）
├── constants/                 # 常量（资源路径、主题默认值）
├── model/                     # 业务模型（Music/Playlist/Toplist）
├── providers/                 # 全局状态
│   ├── MusicProvider/         # 播放核心（library/queue/repository）
│   ├── PlaylistProvider/      # 歌单管理
│   ├── ThemeProvider/         # 主题与设置
│   ├── UserProvider/          # 用户状态
│   ├── NavProvider/           # 导航状态
│   └── StartupProvider/       # 启动流程
├── router/                    # 路由配置
│   ├── IndexRouter/           # 路由表定义
│   └── Extensions/            # 路由扩展
├── service/                   # 业务服务
│   ├── AppIcon/               # 动态图标切换
│   ├── Audio/                 # 音频处理器（audio_service）
│   ├── Files/                 # 文件/目录管理
│   ├── Hotkeys/               # 全局热键
│   ├── Initialization/        # 启动初始化
│   ├── LocalAuth/             # 本地认证
│   ├── Music/                 # 音乐扫描与解析
│   ├── MusicDb/               # SQLite 数据库封装
│   ├── NetworkSongStore/      # 网络歌曲元数据持久化
│   ├── Settings/              # 设置持久化
│   ├── Tray/                  # 系统托盘
│   └── UpdateCheck/           # 版本更新检查
├── src/                       # Rust FFI 生成代码（flutter_rust_bridge）
├── utils/                     # 工具类（HTTP/NetEaseCloud）
└── views/                     # 页面视图
    ├── index.dart             # 主框架（自适应布局）
    ├── Splash/                # 启动页
    ├── Home/                  # 首页
    ├── Music/                 # 音乐库（歌曲/专辑/歌单标签页）
    ├── MusicDetail/           # 播放详情（宽/窄布局 + 歌词）
    ├── Network/               # 网络歌曲搜索
    ├── Search/                # 搜索页
    ├── ToplistDetail/         # 排行榜详情
    ├── Settings/              # 设置页
    ├── Login/                 # 登录/注册
    ├── About/                 # 关于页
    ├── SetupWizard/           # 权限引导
    ├── NotFound/              # 404
    ├── EditPlaylist/          # 编辑歌单
    ├── UpdateDownload/        # 更新下载
    └── User/                  # 用户相关页面
        ├── Profile/           # 个人中心
        ├── EditProfile/       # 编辑资料
        ├── Files/             # 文件管理 & 专辑详情
        ├── Network/           # 网络云盘
        ├── RecentlyPlayed/    # 最近播放
        ├── PlaylistDetail/    # 歌单详情 & 收藏
        └── DownloadManagement/# 下载管理

rust/
├── Cargo.toml
└── src/
    ├── api/
    │   ├── mod.rs
    │   ├── scanner.rs         # 目录扫描
    │   ├── audio_info.rs      # 音频元数据解析
    │   ├── metadata.rs        # 封面图片提取
    │   ├── hotkey.rs          # 全局热键
    │   ├── simple.rs          # 简单 FFI 示例
    │   └── audio_db/          # SQLite 数据库
    │       ├── mod.rs
    │       ├── songs.rs
    │       ├── playlists.rs
    │       ├── history.rs
    │       └── favorites.rs
    └── migrations/
        └── init.sql

backend/                        # Go 后端（可选）
├── cmd/server/main.go
├── config/config.go
├── router/api.go
├── middleware/jwtAuth.go
├── internal/
│   ├── handler/               # auth / music / uploadSign
│   ├── model/                 # 数据模型
│   ├── repository/            # 数据库操作
│   └── service/               # 邮件服务
└── utils/                     # JWT / OSS

typescript/                     # Node.js 代理（网易云 API）
├── server.js
└── package.json

ags/                            # Aylur's GTK Shell 桌面组件
├── app.ts
├── package.json
└── widget/
    └── DynamicIsland.tsx
```

## 运行方式

### 环境要求

- Flutter SDK: `^3.11.4`
- Dart SDK: `^3.11.4`
- Rust toolchain（用于编译原生库）
- Go（可选，用于后端服务）
- Node.js + pnpm（可选，用于网易云 API 代理）

### 安装依赖

```bash
flutter pub get
```

### 配置环境变量

在项目根目录创建 `.env`（或使用已有的 `.env.development` / `.env.production`）：

```env
# Go 后端地址（登录/注册/上传功能需要，非必须）
GO_BACKEND_URL=http://localhost:8000

# Node.js 代理地址（网易云搜索/排行榜需要，非必须）
JS_BACKEND_URL=http://localhost:3000
```

### 启动应用

```bash
# 仅 Flutter 前端
flutter run

# 同时启动 Go 后端 + Flutter 前端
make dev

# 停止后端
make stop
```

### 启动 Node.js 代理（可选）

```bash
cd typescript && pnpm install && node server.js
```

### 平台支持

| 平台    | 状态        | 备注                                |
| ------- | ----------- | ----------------------------------- |
| Android | ✅ 完整支持 | 含权限引导、动态图标、通知栏控制    |
| Linux   | ✅ 完整支持 | 含系统托盘、全局热键、窗口管理      |
| Windows | ✅ 完整支持 | 含系统托盘、全局热键、窗口管理      |
| macOS   | ✅ 完整支持 | 含系统托盘、窗口管理                |
| iOS     | ⚠️ 工程存在 | 未完整验证本地权限流程              |
| Web     | ⚠️ 基础支持 | Rust FFI 在 Web 端不可用，仅基础 UI |

## CI/CD

- [release-please.yml](.github/workflows/release-please.yml) — 自动 Release 管理
- [build-macos.yml](.github/workflows/build-macos.yml) — macOS 构建（手动触发）
- [build-windows.yml](.github/workflows/build-windows.yml) — Windows 构建（手动触发）

## 许可证

本项目代码仅供学习交流使用。
