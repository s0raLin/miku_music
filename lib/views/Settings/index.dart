import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:myapp/api/Client/Netease/index.dart';
import 'package:myapp/components/Shared/index.dart';
import 'package:myapp/constants/Assets/index.dart';
import 'package:myapp/providers/MusicProvider/index.dart';
import 'package:myapp/providers/SettingsProvider/index.dart';
import 'package:myapp/providers/ThemeProvider/index.dart';
import 'package:myapp/providers/UserProvider/index.dart';
import 'package:myapp/service/Files/index.dart';
import 'package:myapp/views/Settings/widgets/app_icon_picker_sheet.dart';
import 'package:myapp/views/Settings/widgets/folder_pick_dialog.dart';
import 'package:myapp/views/Settings/widgets/scan_directories_tile.dart';
import 'package:myapp/views/Settings/widgets/theme_color_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  List<String> _scanPaths = [];
  bool _isPathsLoading = true;

  @override
  void initState() {
    super.initState();
    _initPaths();
  }

  Future<void> _initPaths() async {
    final paths = await FileService.loadPaths();
    if (mounted)
      setState(() {
        _scanPaths = paths;
        _isPathsLoading = false;
      });
  }

  Future<void> _showPickDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => FolderPickDialog(
        initialPaths: _scanPaths,
        onPathsChanged: (p) => setState(() => _scanPaths = p),
      ),
    );
  }

  /// 弹出网易云扫码登录 Dialog
  void _showNeteaseQrLoginDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const NeteaseQrLoginDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    final sp = context.watch<SettingsProvider>();
    final up = context.watch<UserProvider>(); // ← 新增
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final ver = context.select<MusicProvider, String>((p) => p.appVersion);
    final bld = context.select<MusicProvider, String>((p) => p.buildNumber);

    return Scaffold(
      appBar: AppBar(title: const Text("设置")),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            children: [
              // ── 外观 ──────────────────────────────────────────────────────
              AppSectionHeader(title: "外观"),
              Card.filled(
                child: Column(
                  children: [
                    ThemeColorPicker(
                      selectedColor: tp.seedColor,
                      onColorSelected: (c) => tp.setSeedColor(c),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    SwitchListTile(
                      secondary: _icon(Icons.dark_mode_outlined),
                      title: const Text("深色模式"),
                      subtitle: Text(
                        tp.themeMode == ThemeMode.system
                            ? "跟随系统"
                            : tp.themeMode == ThemeMode.dark
                            ? "已开启"
                            : "已关闭",
                        style: tt.bodySmall?.copyWith(color: cs.outline),
                      ),
                      value: tp.themeMode == ThemeMode.dark,
                      onChanged: (v) =>
                          tp.setThemeMode(v ? ThemeMode.dark : ThemeMode.light),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    _segmentedTile(
                      icon: Icons.density_medium_outlined,
                      title: "列表密度",
                      subtitle: tp.listDensity == "compact" ? "紧凑" : "舒适",
                      segments: const [
                        ButtonSegment(value: "compact", label: Text("紧凑")),
                        ButtonSegment(value: "normal", label: Text("舒适")),
                      ],
                      selected: {tp.listDensity},
                      onChanged: (v) => tp.setListDensity(v.first),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    _segmentedTile<SliderStyle>(
                      icon: Icons.show_chart_outlined,
                      title: "进度条样式",
                      subtitle: tp.sliderStyle == SliderStyle.wave
                          ? "波浪形"
                          : "直线形",
                      segments: const [
                        ButtonSegment(
                          value: SliderStyle.straight,
                          icon: Icon(Icons.horizontal_rule_rounded),
                        ),
                        ButtonSegment(
                          value: SliderStyle.wave,
                          icon: Icon(Icons.waves_rounded),
                        ),
                      ],
                      selected: {tp.sliderStyle},
                      onChanged: (v) => tp.setSliderStyle(v.first),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    ListTile(
                      leading: _icon(Icons.apps_outlined),
                      title: const Text("应用图标"),
                      subtitle: Text(
                        _iconFileName(sp.appIconPath),
                        style: tt.bodySmall?.copyWith(color: cs.outline),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showAppIconPicker(context, sp),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),
              // ── 账号与服务 (扫码登录) ──────────────────────────────────
              // ── 账号与服务 ──────────────────────────────────
              AppSectionHeader(title: "账号与服务"),
              Card.filled(
                child: Column(
                  children: [
                    ListTile(
                      leading: _icon(Icons.cloud_queue_outlined),
                      title: const Text("网易云音乐账号"),
                      subtitle: Text(
                        up.isNeteaseLoggedIn
                            ? "已登录: ${up.neteaseUsername}"
                            : "未登录 (点击扫码登录以解锁会员及高码率支持)",
                        style: tt.bodySmall?.copyWith(
                          color: up.isNeteaseLoggedIn ? cs.primary : cs.outline,
                        ),
                      ),
                      trailing: up.isNeteaseLoggedIn
                          ? Icon(
                              Icons.chevron_right_rounded,
                              color: cs.onSurfaceVariant,
                            )
                          : const Icon(Icons.qr_code_2_rounded, size: 24),
                      onTap: () {
                        if (up.isNeteaseLoggedIn) {
                          _showNeteaseAccountDetailDialog();
                        } else {
                          _showNeteaseQrLoginDialog();
                        }
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),
              // ── 播放 ──────────────────────────────────────────────────────
              AppSectionHeader(title: "播放"),
              Card.filled(
                child: Column(
                  children: [
                    _switchTile(
                      Icons.play_circle_outline,
                      "启动时自动播放",
                      "应用启动后恢复上次播放",
                      sp.autoPlayOnStart,
                      sp.setAutoPlayOnStart,
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    _switchTile(
                      Icons.touch_app_outlined,
                      "双击快速播放",
                      "双击列表中的歌曲立即播放",
                      sp.doubleTapToPlay,
                      sp.setDoubleTapToPlay,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),
              // ── 显示 ──────────────────────────────────────────────────────
              AppSectionHeader(title: "显示"),
              Card.filled(
                child: Column(
                  children: [
                    _switchTile(
                      Icons.album_outlined,
                      "显示专辑封面",
                      "播放页面展示专辑封面图",
                      sp.showLyricCover,
                      sp.setShowLyricCover,
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    _switchTile(
                      Icons.notifications_outlined,
                      "通知栏显示详情",
                      "通知栏展示歌曲名与封面",
                      sp.showNotificationDetail,
                      sp.setShowNotificationDetail,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),
              // ── 数据 ──────────────────────────────────────────────────────
              AppSectionHeader(title: "数据"),
              Card.filled(
                child: Column(
                  children: [
                    ScanDirectoriesTile(
                      scanPaths: _scanPaths,
                      isLoading: _isPathsLoading,
                      onPickDialog: _showPickDialog,
                      onPathRemoved: () => _initPaths(),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    ListTile(
                      leading: _icon(Icons.history_outlined),
                      title: const Text("历史记录上限"),
                      subtitle: Text(
                        "最多保留 ${sp.maxHistoryCount} 条",
                        style: tt.bodySmall?.copyWith(color: cs.outline),
                      ),
                      trailing: DropdownButton<int>(
                        value: sp.maxHistoryCount,
                        items: const [
                          DropdownMenuItem(value: 50, child: Text("50")),
                          DropdownMenuItem(value: 100, child: Text("100")),
                          DropdownMenuItem(value: 300, child: Text("300")),
                          DropdownMenuItem(value: 500, child: Text("500")),
                        ],
                        onChanged: (v) {
                          if (v != null) sp.setMaxHistoryCount(v);
                        },
                        underline: Container(),
                      ),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    ListTile(
                      leading: _icon(Icons.cleaning_services_outlined),
                      title: const Text("清除缓存"),
                      subtitle: Text(
                        "清除专辑封面、歌词等临时文件",
                        style: tt.bodySmall?.copyWith(color: cs.outline),
                      ),
                      trailing: const Icon(Icons.chevron_right, size: 20),
                      onTap: () => _showClearCache(context),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),
              // ── 关于 ──────────────────────────────────────────────────────
              AppSectionHeader(title: "关于"),
              Card.filled(
                child: Column(
                  children: [
                    ListTile(
                      leading: _icon(Icons.info_outline_rounded),
                      title: const Text("软件版本"),
                      trailing: Text(
                        "$ver ($bld)",
                        style: tt.bodyMedium?.copyWith(color: cs.outline),
                      ),
                      onTap: () {},
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    ListTile(
                      leading: _icon(Icons.description_outlined),
                      title: const Text("开源许可"),
                      trailing: const Icon(Icons.chevron_right, size: 20),
                      onTap: () => showLicensePage(context: context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _icon(IconData icon) => Icon(
    icon,
    size: 20,
    color: Theme.of(context).colorScheme.onSurfaceVariant,
  );

  Widget _switchTile(
    IconData icon,
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return SwitchListTile(
      secondary: _icon(icon),
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: tt.bodySmall?.copyWith(color: cs.outline),
      ),
      value: value,
      onChanged: onChanged,
    );
  }

  Widget _segmentedTile<T>({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<ButtonSegment<T>> segments,
    required Set<T> selected,
    required ValueChanged<Set<T>> onChanged,
  }) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      leading: _icon(icon),
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: tt.bodySmall?.copyWith(color: cs.outline),
      ),
      trailing: SegmentedButton<T>(
        segments: segments,
        selected: selected,
        onSelectionChanged: onChanged,
        showSelectedIcon: false,
        style: const ButtonStyle(visualDensity: VisualDensity.compact),
      ),
    );
  }

  String _iconFileName(String p) => p
      .split('/')
      .last
      .replaceAll(RegExp(r'\.(png|jpeg|jpg)$'), '')
      .replaceAll('app_icon', '风格 ')
      .trim();

  void _showAppIconPicker(BuildContext context, SettingsProvider sp) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => AppIconPickerSheet(
        iconPaths: const [
          MyAssets.app_icon,
          MyAssets.app_icon1,
          MyAssets.app_icon2,
          MyAssets.app_icon3,
          MyAssets.app_icon4,
          MyAssets.app_icon5,
          MyAssets.app_icon6,
          MyAssets.app_icon7,
          MyAssets.app_icon8,
          MyAssets.app_icon9,
        ],
        currentIconPath: sp.appIconPath,
        onConfirm: (p) {
          sp.setAppIconPath(p);
          Navigator.pop(context);
        },
        onCancel: () => Navigator.pop(context),
      ),
    );
  }

  Future<void> _showClearCache(BuildContext context) async {
    final cs = Theme.of(context).colorScheme;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("清除缓存"),
        content: const Text("将清除专辑封面、歌词等临时缓存文件，不会影响您的音乐库和播放列表。"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("取消"),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("确定清除"),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      final tmp = await getTemporaryDirectory();
      if (await tmp.exists()) await tmp.delete(recursive: true);
      final cache = await getApplicationCacheDirectory();
      if (await cache.exists()) {
        await for (final e in cache.list(recursive: true)) {
          if (e is File) {
            try {
              await e.delete();
            } catch (_) {}
          }
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("缓存已清除"),
            backgroundColor: cs.primaryContainer,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("清除失败: $e"), backgroundColor: cs.error),
        );
      }
    }
  }

  /// 弹出网易云账号详情 Dialog
  void _showNeteaseAccountDetailDialog() {
    showDialog(
      context: context,
      builder: (ctx) => NeteaseAccountDetailDialog(
        onSwitchAccount: () {
          // 切换账号逻辑：先清除当前凭据，再打开扫码弹窗
          context.read<UserProvider>().clearNeteaseAuth();
          _showNeteaseQrLoginDialog();
        },
      ),
    );
  }
}
// ── 网易云账号详情弹窗组件 ───────────────────────────

class NeteaseAccountDetailDialog extends StatelessWidget {
  final VoidCallback onSwitchAccount;

  const NeteaseAccountDetailDialog({
    super.key,
    required this.onSwitchAccount,
  });

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    final rawName = userProvider.neteaseUsername;
    final hasName = rawName != null && rawName.trim().isNotEmpty;
    final username = hasName ? rawName : "网易云用户";

    return AlertDialog(
      elevation: 6,
      shadowColor: cs.shadow.withValues(alpha: 0.2),
      surfaceTintColor: cs.surfaceTint,
      backgroundColor: cs.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. 头像区域
          _buildAvatar(cs, tt, username, hasName),
          const SizedBox(height: 16),

          // 2. 账号名称与状态标牌
          Text(
            username,
            style: tt.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          _buildStatusChip(cs, tt),
          const SizedBox(height: 24),

          // 3. 操作选项卡片组
          Container(
            decoration: BoxDecoration(
              color: cs.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.4),
                width: 1,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _buildActionItem(
                  context: context,
                  icon: Icons.swap_horiz_rounded,
                  iconBgColor: cs.primaryContainer,
                  iconColor: cs.onPrimaryContainer,
                  title: "切换账号",
                  subtitle: "清除当前凭据并重新扫码",
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                  onTap: () => _confirmSwitchAccount(context),
                ),
                Divider(
                  height: 1,
                  thickness: 1,
                  indent: 16,
                  endIndent: 16,
                  color: cs.outlineVariant.withValues(alpha: 0.3),
                ),
                _buildActionItem(
                  context: context,
                  icon: Icons.logout_rounded,
                  iconBgColor: cs.errorContainer.withValues(alpha: 0.6),
                  iconColor: cs.error,
                  title: "退出登录",
                  subtitle: "解绑账号并恢复为游客状态",
                  titleColor: cs.error,
                  onTap: () => _confirmLogout(context, userProvider, cs),
                ),
              ],
            ),
          ),
        ],
      ),
      actionsPadding: const EdgeInsets.only(right: 20, bottom: 16),
      actions: [
        TextButton(
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            '关闭',
            style: tt.labelLarge?.copyWith(
              color: cs.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  /// 构建圆角头像
  Widget _buildAvatar(
    ColorScheme cs,
    TextTheme tt,
    String name,
    bool hasName,
  ) {
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: cs.primaryContainer,
        border: Border.all(
          color: cs.surfaceContainerLowest,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: hasName
            ? Text(
                name.characters.first.toUpperCase(),
                style: tt.headlineMedium?.copyWith(
                  color: cs.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              )
            : Icon(
                Icons.account_circle_rounded,
                size: 48,
                color: cs.onPrimaryContainer,
              ),
      ),
    );
  }

  /// 绑定状态徽章
  Widget _buildStatusChip(ColorScheme cs, TextTheme tt) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cs.secondaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_rounded, size: 14, color: cs.secondary),
          const SizedBox(width: 4),
          Text(
            "已绑定网易云音乐",
            style: tt.labelSmall?.copyWith(
              color: cs.onSecondaryContainer,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// 操作项组件
  Widget _buildActionItem({
    required BuildContext context,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? titleColor,
    Widget? trailing,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: cs.primary.withValues(alpha: 0.08),
        highlightColor: cs.primary.withValues(alpha: 0.04),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: tt.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: titleColor ?? cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
        ),
      ),
    );
  }

  /// 切换账号确认弹窗
  Future<void> _confirmSwitchAccount(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("确认切换账号"),
        content: const Text("切换账号将清除当前登录状态并打开重新扫码界面，确定要继续吗？"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("取消"),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("确认切换"),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      Navigator.of(context).pop(); // 关闭当前账号详情弹窗
      onSwitchAccount(); // 执行切换回调
    }
  }

  /// 退出登录确认弹窗及逻辑
  Future<void> _confirmLogout(
    BuildContext context,
    UserProvider userProvider,
    ColorScheme cs,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("确认退出登录"),
        content: const Text("解绑后将恢复为游客状态，确定要退出登录吗？"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("取消"),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: cs.error,
              foregroundColor: cs.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("退出登录"),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await userProvider.clearNeteaseAuth();
      if (context.mounted) {
        Navigator.of(context).pop(); // 关闭当前账号详情弹窗
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text("已退出网易云账号"),
              ],
            ),
            backgroundColor: cs.secondary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }
}

// ── 扫码登录弹窗组件 ──────────────────────────────────────────────────

class NeteaseQrLoginDialog extends StatefulWidget {
  const NeteaseQrLoginDialog({super.key});

  @override
  State<NeteaseQrLoginDialog> createState() => _NeteaseQrLoginDialogState();
}

class _NeteaseQrLoginDialogState extends State<NeteaseQrLoginDialog> {
  String? _qrImgBase64;
  String? _qrKey;
  String _statusText = '加载二维码中...';
  bool _isExpired = false;
  bool _isLoading = true;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _startLoginFlow();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _startLoginFlow() async {
    setState(() {
      _isLoading = true;
      _isExpired = false;
      _statusText = '获取二维码...';
    });

    try {
      // 1. 从 NeteaseApi 获取 qrKey
      _qrKey = await NeteaseApi.getQrKey();
      if (_qrKey == null) throw Exception("Key 获取失败");

      // 2. 从 NeteaseApi 获取二维码图片 (Base64)
      _qrImgBase64 = await NeteaseApi.getQrImage(_qrKey!);

      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusText = '请使用 网易云音乐 App 扫码';
        });
      }

      // 3. 开启轮询扫码状态 (每 2 秒一次)
      _pollingTimer?.cancel();
      _pollingTimer = Timer.periodic(
        const Duration(seconds: 2),
        (_) => _checkQrStatus(),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusText = '生成二维码失败: $e';
        });
      }
    }
  }

  Future<void> _checkQrStatus() async {
    if (_qrKey == null) return;

    try {
      final statusResult = await NeteaseApi.checkQrStatus(_qrKey!);
      final code = statusResult['code'];

      if (!mounted) return;

      if (code == 800) {
        // 二维码过期
        _pollingTimer?.cancel();
        setState(() {
          _isExpired = true;
          _statusText = '二维码已过期，点击刷新';
        });
      } else if (code == 802) {
        // 扫码成功，等待确认
        final nickname = statusResult['nickname'] ?? '用户';
        setState(() {
          _statusText = '$nickname 已扫码，请在手机上确认';
        });
      } else if (code == 803) {
        // 授权成功，完成登录
        _pollingTimer?.cancel();

        final cookie = statusResult['cookie'] ?? '';
        final nickname = statusResult['nickname'] ?? '网易云用户';

        if (mounted) {
          // 保存 Cookie 到 Provider，自动触发刷新界面
          // context.read<SettingsProvider>().saveNeteaseCookie(cookie, nickname);
          // 直接调用 Provider 保存
          await context.read<UserProvider>().saveNeteaseCookie(
            cookie,
            nickname: nickname,
          );

          Navigator.of(context).pop(); // 关闭弹窗
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('网易云音乐登录成功！')));
        }
      }
    } catch (_) {
      // 忽略网络抖动导致的单次轮询异常
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('网易云音乐扫码登录', textAlign: TextAlign.center),
      content: SizedBox(
        width: 260,
        height: 280,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 180,
              height: 180,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _isExpired
                  ? InkWell(
                      onTap: _startLoginFlow,
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.refresh, size: 48, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('点击刷新二维码', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : (_qrImgBase64 != null)
                  ? Image.memory(
                      base64Decode(_qrImgBase64!.split(',').last),
                      fit: BoxFit.contain,
                    )
                  : const SizedBox(),
            ),
            const SizedBox(height: 16),
            Text(_statusText, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
      ],
    );
  }
}
