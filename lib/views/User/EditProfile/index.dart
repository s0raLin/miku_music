import 'package:flutter/material.dart';
import 'package:myapp/api/Model/User/index.dart';
import 'package:myapp/components/Shared/index.dart';
import 'package:myapp/constants/Assets/index.dart';
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

  @override
  void initState() {
    super.initState();
    final user = context.read<UserProvider>().user;
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
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: colorScheme.primaryContainer, width: 4),
            ),
            child: const CircleAvatar(
              radius: 60,
              backgroundImage: AssetImage(MyAssets.mikulogo),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Material(
              color: colorScheme.primary,
              shape: const CircleBorder(),
              elevation: 4,
              child: IconButton(
                onPressed: () => _showSimpleSnackBar('即将支持上传图片'),
                icon: Icon(
                  Icons.camera_alt_rounded,
                  color: colorScheme.onPrimary,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
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
            onTap: () => _showSimpleSnackBar('密码修改功能开发中'),
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
            onTap: () => _showSimpleSnackBar('账户注销功能暂未开放。'),
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

  // 增加一点触感反馈
  void _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final userProvider = context.read<UserProvider>();
    final currentUser = userProvider.user;
    if (currentUser == null) return;

    // 更新用户信息
    final updatedUser = User(
      username: _usernameController.text,
      email: _emailController.text,
      avatarURL: currentUser.avatarURL,
      token: currentUser.token,
    );

    await userProvider.updateUserInfo(updatedUser);

    if (mounted) {
      AppToast.success(
        context,
        message: '个人资料已更新',
        title: '保存成功',
      );
    }
  }
}
