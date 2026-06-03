import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:myapp/api/Client/Auth/index.dart';
import 'package:myapp/api/Model/User/index.dart';
import 'package:myapp/components/Shared/index.dart';
import 'package:myapp/providers/UserProvider/index.dart';
import 'package:provider/provider.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _usernameController;
  late final TextEditingController _emailController;
  late final TextEditingController _bioController; // 新增：个性签名
  final _imagePicker = ImagePicker();

  /// 已存在的服务器头像 URL
  String? _existingAvatarUrl;

  /// 本地新选择的头像文件
  XFile? _avatarImage;

  /// 是否正在上传头像
  bool _isUploadingAvatar = false;

  Future<void> _pickAvatar() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 500,
      maxHeight: 500,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() {
        _avatarImage = picked;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    final user = context.read<UserProvider>().user;
    _existingAvatarUrl = user?.avatarURL;
    _usernameController = TextEditingController(text: user?.username ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _bioController = TextEditingController(text: '这是一段默认的个性签名...');
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('编辑资料'),
        actions: [
          // 使用 TextButton 会比 FilledButton 在 AppBar 中更显轻盈
          TextButton(
            onPressed: _saveProfile,
            child: const Text(
              '保存',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  // --- 1. 头像编辑预览区 ---
                  _buildAvatarSection(colorScheme),
                  const SizedBox(height: 32),

                  // --- 2. 基础表单区 ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      children: [
                        _buildTextField(
                          controller: _usernameController,
                          label: '用户名',
                          icon: Icons.person_outline_rounded,
                          validator: (v) =>
                              (v == null || v.isEmpty) ? '名号还是得有一个的' : null,
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
                          controller: _emailController,
                          label: '邮箱',
                          icon: Icons.alternate_email_rounded,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) =>
                              !RegExp(r'\S+@\S+\.\S+').hasMatch(v ?? '')
                              ? '邮箱格式不太对哦'
                              : null,
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
                          controller: _bioController,
                          label: '个性签名',
                          icon: Icons.auto_awesome_motion_rounded,
                          maxLines: 3, // 支持多行
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // --- 3. 账户安全区 ---
                  _buildAccountSettings(colorScheme),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 构建大头像预览
  Widget _buildAvatarSection(ColorScheme colorScheme) {
    return Center(
      child: GestureDetector(
        onTap: _pickAvatar,
        child: Stack(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: colorScheme.primaryContainer,
              backgroundImage: _isUploadingAvatar
                  ? null
                  : _avatarImage != null
                  ? FileImage(File(_avatarImage!.path))
                  : _existingAvatarUrl != null && _existingAvatarUrl!.isNotEmpty
                  ? NetworkImage(_existingAvatarUrl!)
                  : null,
              child: _isUploadingAvatar
                  ? SizedBox(
                      width: 30,
                      height: 30,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    )
                  : _avatarImage == null &&
                        (_existingAvatarUrl == null ||
                            _existingAvatarUrl!.isEmpty)
                  ? Icon(
                      Icons.person,
                      size: 50,
                      color: colorScheme.onPrimaryContainer,
                    )
                  : null,
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.camera_alt,
                  size: 20,
                  color: colorScheme.onPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 统一的输入框构建
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      ),
    );
  }

  // 底部列表设置区
  Widget _buildAccountSettings(ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.lock_reset_rounded),
            title: const Text('修改密码'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _showChangePasswordDialog(),
          ),
          const Divider(height: 1, indent: 56),
          ListTile(
            leading: const Icon(
              Icons.delete_forever_rounded,
              color: Colors.redAccent,
            ),
            title: const Text(
              '注销账号',
              style: TextStyle(color: Colors.redAccent),
            ),
            onTap: () => _showDeleteAccountDialog(),
          ),
        ],
      ),
    );
  }

  void _showSimpleSnackBar(String msg) {
    AppToast.show(
      context,
      message: msg,
      title: '功能提示',
      tone: AppToastTone.neutral,
    );
  }

  // ──────────────────────── 修改密码弹窗 ────────────────────────

  void _showChangePasswordDialog() {
    final oldPwdController = TextEditingController();
    final newPwdController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('修改密码'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPwdController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: '当前密码',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPwdController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: '新密码（至少6位）',
                prefixIcon: Icon(Icons.lock_reset),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              final oldPwd = oldPwdController.text.trim();
              final newPwd = newPwdController.text.trim();
              if (oldPwd.isEmpty || newPwd.isEmpty) {
                AppToast.error(ctx, message: '请填写完整', title: '提示');
                return;
              }
              if (newPwd.length < 6) {
                AppToast.error(ctx, message: '新密码至少6位', title: '提示');
                return;
              }
              try {
                await UserApi.changePassword(
                  oldPassword: oldPwd,
                  newPassword: newPwd,
                );
                if (!mounted) return;
                Navigator.of(ctx).pop();
                AppToast.success(
                  mounted ? context : ctx,
                  message: '密码修改成功',
                  title: '完成',
                );
              } on DioException catch (e) {
                final msg = e.message ?? '修改失败';
                AppToast.error(ctx, message: msg, title: '修改失败');
              }
            },
            child: const Text('确认修改'),
          ),
        ],
      ),
    );
  }

  // ──────────────────────── 注销账号弹窗 ────────────────────────

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('注销账号'),
        content: const Text('注销后您的账号数据将被永久删除，此操作不可撤销。确定要继续吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await UserApi.deleteAccount();
                if (!mounted) return;
                Navigator.of(ctx).pop();
                // 清除本地状态并跳转到登录页
                await context.read<UserProvider>().logout();
                if (!mounted) return;
                AppToast.success(context, message: '账号已注销', title: '再见');
                context.go('/login');
              } on DioException catch (e) {
                final msg = e.message ?? '注销失败';
                AppToast.error(ctx, message: msg, title: '注销失败');
              }
            },
            child: const Text('确认注销'),
          ),
        ],
      ),
    );
  }

  void _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final userProvider = context.read<UserProvider>();
    final currentUser = userProvider.user;
    if (currentUser == null) return;

    setState(() => _isUploadingAvatar = true);
    try {
      String avatarUrl = currentUser.avatarURL ?? '';

      // 如果有新选择的头像，先上传到 OSS
      if (_avatarImage != null) {
        final bytes = await File(_avatarImage!.path).readAsBytes();
        final fileName = _avatarImage!.name;
        try {
          avatarUrl = await UserApi.uploadAvatar(
            avatarBytes: bytes,
            fileName: fileName,
          );
          // 上传成功后清除本地选择标记，改用服务器 URL
          _existingAvatarUrl = avatarUrl;
          _avatarImage = null;
        } catch (e) {
          if (!mounted) return;
          AppToast.error(context, message: '头像上传失败: $e', title: '上传失败');
          return;
        }
      }

      // 更新用户信息
      final updatedUser = User(
        username: _usernameController.text,
        email: _emailController.text,
        avatarURL: avatarUrl,
        token: currentUser.token,
      );

      await userProvider.updateUserInfo(updatedUser);

      if (mounted) {
        AppToast.success(context, message: '个人资料已更新', title: '保存成功');
      }
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }
}
