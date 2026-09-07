import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:myapp/router/Extensions/router.dart';
import 'package:myapp/service/Files/index.dart';
import 'package:myapp/service/Permissions/index.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SetupWizardScreen extends StatefulWidget {
  const SetupWizardScreen({super.key});

  @override
  State<SetupWizardScreen> createState() => _SetupWizardScreenState();
}

class _SetupWizardScreenState extends State<SetupWizardScreen> {
  static const int _totalSteps = 3;

  final PageController _pageController = PageController();
  int _currentIndex = 0;
  bool _busy = false;

  Map<AppPermissionKey, AppPermissionState> _permissionStates = const {};
  List<String> _paths = const [];

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    setState(() => _busy = true);
    try {
      final results = await Future.wait([
        PermissionService.getAllStatuses(),
        FileService.loadPaths(),
      ]);
      if (!mounted) return;
      setState(() {
        _permissionStates =
            results[0] as Map<AppPermissionKey, AppPermissionState>;
        _paths = results[1] as List<String>;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _requestPermission(AppPermissionKey key) async {
    setState(() => _busy = true);
    try {
      final status = await PermissionService.request(key);
      if (!mounted) return;
      setState(() {
        _permissionStates = {..._permissionStates, key: status};
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _requestAllPermissions() async {
    setState(() => _busy = true);
    try {
      final states = await PermissionService.requestAll();
      if (!mounted) return;
      setState(() => _permissionStates = states);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _addFolder() async {
    setState(() => _busy = true);
    try {
      final selectedPath = await FilePicker.getDirectoryPath();
      if (selectedPath == null || selectedPath.isEmpty) return;
      final updatedPaths = {..._paths, selectedPath}.toList();
      await _savePaths(updatedPaths);
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("is_first_run", false);

    if (!mounted) return;
    context.toHome();
  }

  void _onNextPressed() async {
    if (_currentIndex < _totalSteps - 1) {
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      await _finishSetup();
    }
  }

  void _onBackPressed() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_currentIndex + 1) / _totalSteps;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            LinearProgressIndicator(value: progress),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) => setState(() => _currentIndex = index),
                children: [
                  const _WelcomeStep(),
                  _PermissionStep(
                    busy: _busy,
                    states: _permissionStates,
                    onRequest: _requestPermission,
                    onRequestAll: _requestAllPermissions,
                    onRefresh: _refreshData,
                  ),
                  _FolderStep(
                    busy: _busy,
                    paths: _paths,
                    onAddFolder: _addFolder,
                    onSavePaths: _savePaths,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentIndex > 0)
                    TextButton(
                      onPressed: _busy ? null : _onBackPressed,
                      child: const Text("返回"),
                    )
                  else
                    const SizedBox.shrink(),
                  FilledButton(
                    onPressed: _busy ? null : _onNextPressed,
                    child: Text(
                      _currentIndex == _totalSteps - 1 ? "开始" : "下一步",
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== 1. 欢迎页组件 ====================

class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.celebration_rounded, size: 84, color: colorScheme.primary),
          const SizedBox(height: 20),
          Text("欢迎使用", style: theme.textTheme.headlineMedium),
          const SizedBox(height: 12),
          Text(
            "接下来会引导你完成权限与目录设置。\n所有设置都可以之后在“设置/文件”中修改。",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          Card(
            elevation: 0,
            color: colorScheme.surfaceContainerLow,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.privacy_tip_outlined, color: colorScheme.tertiary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "仅在你授权后读取你选择的目录，用于扫描本地音频文件。",
                      style: theme.textTheme.bodyMedium,
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
}

// ==================== 2. 权限页组件 ====================

class _PermissionStep extends StatelessWidget {
  final bool busy;
  final Map<AppPermissionKey, AppPermissionState> states;
  final ValueChanged<AppPermissionKey> onRequest;
  final VoidCallback onRequestAll;
  final VoidCallback onRefresh;

  const _PermissionStep({
    required this.busy,
    required this.states,
    required this.onRequest,
    required this.onRequestAll,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      children: [
        Row(
          children: [
            Icon(Icons.security_rounded, color: colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(child: Text("系统权限", style: theme.textTheme.headlineSmall)),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          "Android 不同版本对媒体权限的要求不一样。你只需要授予“音频媒体”或“存储”之一即可扫描音乐。",
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        _PermissionCard(
          title: "音频媒体",
          subtitle: "用于读取你的本地音频文件列表（Android 13+ 常见）",
          icon: Icons.audio_file_rounded,
          state: states[AppPermissionKey.audio],
          onRequest: busy ? null : () => onRequest(AppPermissionKey.audio),
          onOpenSettings: busy
              ? null
              : () => PermissionService.openSystemSettings(),
        ),
        const SizedBox(height: 12),
        _PermissionCard(
          title: "存储访问",
          subtitle: "用于读取你选择的目录（Android 12- 常见）",
          icon: Icons.folder_open_rounded,
          state: states[AppPermissionKey.storage],
          onRequest: busy ? null : () => onRequest(AppPermissionKey.storage),
          onOpenSettings: busy
              ? null
              : () => PermissionService.openSystemSettings(),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: busy ? null : onRequestAll,
          icon: const Icon(Icons.check_circle_outline_rounded),
          label: const Text("一键申请"),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: busy ? null : onRefresh,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text("刷新状态"),
        ),
      ],
    );
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final statusText = _getStatusText(state?.status);
    final statusColor = _getStatusColor(colorScheme, state?.status);

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(title, style: theme.textTheme.titleMedium),
                ),
                _StatusChip(label: statusText, color: statusColor),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
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

  String _getStatusText(PermissionStatus? s) {
    if (s == null) return "未知";
    if (s.isGranted || s.isLimited) return "已授予";
    if (s.isPermanentlyDenied) return "已永久拒绝";
    if (s.isDenied) return "未授予";
    if (s.isRestricted) return "受限制";
    return "未知";
  }

  Color _getStatusColor(ColorScheme scheme, PermissionStatus? s) {
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: ShapeDecoration(
        color: color.withOpacity(0.12),
        shape: StadiumBorder(side: BorderSide(color: color, width: 1)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ==================== 3. 目录设置页组件 ====================

class _FolderStep extends StatelessWidget {
  final bool busy;
  final List<String> paths;
  final VoidCallback onAddFolder;
  final ValueChanged<List<String>> onSavePaths;

  const _FolderStep({
    required this.busy,
    required this.paths,
    required this.onAddFolder,
    required this.onSavePaths,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      children: [
        Row(
          children: [
            Icon(Icons.folder_special_rounded, color: colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text("选择扫描目录", style: theme.textTheme.headlineSmall),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          Platform.isAndroid
              ? "建议选择包含音乐文件的文件夹。若你不希望授予存储权限，可以只授予音频媒体权限后再尝试扫描。"
              : "选择包含音乐文件的文件夹。",
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        if (paths.isEmpty)
          Card(
            elevation: 0,
            color: colorScheme.surfaceContainerLow,
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
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Card(
            elevation: 0,
            color: colorScheme.surfaceContainerLow,
            child: Column(
              children: paths
                  .map(
                    (path) => ListTile(
                      title: Text(
                        path,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      leading: const Icon(Icons.folder_rounded),
                      trailing: IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: busy
                            ? null
                            : () {
                                final next = [...paths]..remove(path);
                                onSavePaths(next);
                              },
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: busy ? null : onAddFolder,
          icon: const Icon(Icons.add_rounded),
          label: const Text("添加目录"),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: busy || paths.isEmpty ? null : () => onSavePaths([]),
          icon: const Icon(Icons.delete_outline_rounded),
          label: const Text("清空目录"),
        ),
      ],
    );
  }
}
