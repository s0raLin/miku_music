import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:myapp/providers/MusicProvider/index.dart';
import 'package:myapp/router/Extensions/router.dart';
import 'package:myapp/service/Files/index.dart';
import 'package:myapp/service/Permissions/index.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SetupWizardScreen extends StatefulWidget {
  const SetupWizardScreen({super.key});

  @override
  State<SetupWizardScreen> createState() => _SetupWizardScreenState();
}

class _SetupWizardScreenState extends State<SetupWizardScreen> {
  final PageController _controller = PageController();
  int _currentIndex = 0;
  bool _busy = false;

  Map<AppPermissionKey, AppPermissionState> _permissionStates = const {};
  List<String> _paths = const [];

  @override
  void initState() {
    super.initState();
    _refreshStates();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final stepsCount = 3;
    final progress = (_currentIndex + 1) / stepsCount;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            LinearProgressIndicator(value: progress),

            //中间内容区
            Expanded(
              child: PageView.builder(
                controller: _controller,
                physics: const NeverScrollableScrollPhysics(), //禁止手动滑动,必须点按钮
                onPageChanged: (i) => setState(() {
                  _currentIndex = i;
                }),
                itemCount: stepsCount,
                itemBuilder: (context, index) {
                  switch (index) {
                    case 0:
                      return _buildWelcomePage(textTheme, colorScheme);
                    case 1:
                      return _buildPermissionPage(textTheme, colorScheme);
                    case 2:
                    default:
                      return _buildFolderPage(textTheme, colorScheme);
                  }
                },
              ),
            ),

            //底部控制栏
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentIndex > 0)
                    TextButton(
                      onPressed: () => _controller.previousPage(
                        duration: Duration(milliseconds: 300),
                        curve: Curves.ease,
                      ),
                      child: const Text("返回"),
                    )
                  else
                    const SizedBox.shrink(),

                  FilledButton(
                    onPressed: _busy
                        ? null
                        : () async {
                            if (_currentIndex < stepsCount - 1) {
                              await _controller.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.ease,
                              );
                              return;
                            }
                            await _finishSetup();
                          },
                    child: Text(_currentIndex == stepsCount - 1 ? "开始" : "下一步"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomePage(TextTheme textTheme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.celebration_rounded, size: 84, color: colorScheme.primary),
          const SizedBox(height: 20),
          Text("欢迎使用", style: textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            "接下来会引导你完成权限与目录设置。\n所有设置都可以之后在“设置/文件”中修改。",
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.privacy_tip_outlined, color: colorScheme.tertiary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "仅在你授权后读取你选择的目录，用于扫描本地音频文件。",
                      style: textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionPage(TextTheme textTheme, ColorScheme colorScheme) {
    final audio = _permissionStates[AppPermissionKey.audio];
    final storage = _permissionStates[AppPermissionKey.storage];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      children: [
        Row(
          children: [
            Icon(Icons.security_rounded, color: colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(child: Text("系统权限", style: textTheme.headlineSmall)),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          "Android 不同版本对媒体权限的要求不一样。你只需要授予“音频媒体”或“存储”之一即可扫描音乐。",
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        _PermissionCard(
          title: "音频媒体",
          subtitle: "用于读取你的本地音频文件列表（Android 13+ 常见）",
          icon: Icons.audio_file_rounded,
          state: audio,
          onRequest: _busy
              ? null
              : () => _requestPermission(AppPermissionKey.audio),
          onOpenSettings: _busy
              ? null
              : () => PermissionService.openSystemSettings(),
        ),
        const SizedBox(height: 12),
        _PermissionCard(
          title: "存储访问",
          subtitle: "用于读取你选择的目录（Android 12- 常见）",
          icon: Icons.folder_open_rounded,
          state: storage,
          onRequest: _busy
              ? null
              : () => _requestPermission(AppPermissionKey.storage),
          onOpenSettings: _busy
              ? null
              : () => PermissionService.openSystemSettings(),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _busy ? null : _requestAll,
          icon: const Icon(Icons.check_circle_outline_rounded),
          label: const Text("一键申请"),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: _busy ? null : _refreshStates,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text("刷新状态"),
        ),
      ],
    );
  }

  Widget _buildFolderPage(TextTheme textTheme, ColorScheme colorScheme) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      children: [
        Row(
          children: [
            Icon(Icons.folder_special_rounded, color: colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(child: Text("选择扫描目录", style: textTheme.headlineSmall)),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          Platform.isAndroid
              ? "建议选择包含音乐文件的文件夹。若你不希望授予存储权限，可以只授予音频媒体权限后再尝试扫描。"
              : "选择包含音乐文件的文件夹。",
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        if (_paths.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "尚未添加目录。你可以现在添加，也可以稍后在“文件”页面添加。",
                      style: textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Card(
            child: Column(
              children: _paths
                  .map(
                    (p) => ListTile(
                      title: Text(
                        p,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      leading: const Icon(Icons.folder_rounded),
                      trailing: IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: _busy
                            ? null
                            : () async {
                                final next = [..._paths]..remove(p);
                                await _savePaths(next);
                              },
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _busy ? null : _addFolder,
          icon: const Icon(Icons.add_rounded),
          label: const Text("添加目录"),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _busy || _paths.isEmpty
              ? null
              : () async {
                  await _savePaths(const []);
                },
          icon: const Icon(Icons.delete_outline_rounded),
          label: const Text("清空目录"),
        ),
      ],
    );
  }

  Future<void> _refreshStates() async {
    setState(() => _busy = true);
    try {
      final states = await PermissionService.getAllStatuses();
      final paths = await FileService.loadPaths();
      if (!mounted) return;
      setState(() {
        _permissionStates = states;
        _paths = paths;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _requestAll() async {
    setState(() => _busy = true);
    try {
      final states = await PermissionService.requestAll();
      if (!mounted) return;
      setState(() => _permissionStates = states);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _requestPermission(AppPermissionKey key) async {
    setState(() => _busy = true);
    try {
      final s = await PermissionService.request(key);
      if (!mounted) return;
      setState(() {
        _permissionStates = {..._permissionStates, key: s};
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _addFolder() async {
    setState(() => _busy = true);
    try {
      final p = await FilePicker.getDirectoryPath();
      if (p == null || p.isEmpty) return;
      final next = {..._paths, p}.toList();
      await _savePaths(next);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _savePaths(List<String> paths) async {
    await FileService.savePaths(paths);
    if (!mounted) return;
    setState(() => _paths = paths);
  }

  Future<void> _finishSetup() async {
    // 这里不强制卡住权限；如果用户拒绝，也允许进入应用后再处理。
    final pfs = await SharedPreferences.getInstance();
    await pfs.setBool("is_first_run", false);

    if (!mounted) return;

    //跳转到主页
    context.toHome();
  }
}

class _PermissionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final AppPermissionState? state;
  final VoidCallback? onRequest;
  final VoidCallback? onOpenSettings;

  const _PermissionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.state,
    required this.onRequest,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final statusLabel = _statusText(state?.status);
    final statusColor = _statusColor(colorScheme, state?.status);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(child: Text(title, style: textTheme.titleMedium)),
                _StatusChip(label: statusLabel, color: statusColor),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                FilledButton.tonal(
                  onPressed: onRequest,
                  child: const Text("申请"),
                ),
                const SizedBox(width: 12),
                TextButton(onPressed: onOpenSettings, child: const Text("去设置")),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _statusText(PermissionStatus? s) {
    if (s == null) return "未知";
    if (s.isGranted || s.isLimited) return "已授予";
    if (s.isPermanentlyDenied) return "已永久拒绝";
    if (s.isDenied) return "未授予";
    if (s.isRestricted) return "受限制";
    return "未知";
  }

  static Color _statusColor(ColorScheme scheme, PermissionStatus? s) {
    if (s == null) return scheme.outline;
    if (s.isGranted || s.isLimited) return scheme.primary;
    if (s.isPermanentlyDenied) return scheme.error;
    if (s.isDenied) return scheme.tertiary;
    if (s.isRestricted) return scheme.error;
    return scheme.outline;
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: ShapeDecoration(
        color: scheme.surfaceContainerHighest,
        shape: StadiumBorder(side: BorderSide(color: color)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color),
      ),
    );
  }
}
