import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:myapp/api/Client/index.dart';
import 'package:myapp/api/Model/User/index.dart';
import 'package:myapp/components/Shared/index.dart';
import 'package:myapp/providers/UserProvider/index.dart';
import 'package:myapp/utils/Http/index.dart';
import 'package:provider/provider.dart';

/// 登录/注册页面
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // ── 表单控制器 ──
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // ── UI 状态 ──
  bool _obscurePassword = true;
  bool _isLoading = false;

  /// 当前模式: 'code' = 验证码登录, 'password' = 密码登录, 'register' = 注册
  String _mode = 'code';

  /// 发送验证码的冷却倒计时（秒），>0 时不允许再次发送
  int _sendCooldown = 0;
  Timer? _cooldownTimer;

  /// 注册时可选的本地头像
  final _imagePicker = ImagePicker();
  XFile? _avatarImage;

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  /// 启动倒计时并更新 UI
  void _startCooldown() {
    _sendCooldown = 60;
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_sendCooldown > 0) {
          _sendCooldown--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  // ─────────────────── 处理函数 ───────────────────

  /// 邮箱+验证码登录：立即弹窗，验证码在模态框内异步发送
  Future<void> _loginByCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      AppToast.error(context, message: '请输入有效的邮箱地址', title: '提示');
      return;
    }

    // 冷却中不允许重复打开（防刷）
    if (_sendCooldown > 0) {
      AppToast.neutral(
        context,
        // ✨ 1. 修复拼写错误，并去掉了不必要的括号以响应 Lint 规范
        message: '$_sendCooldown秒后可重新发送验证码',
        title: '请稍候',
      );
      return;
    }
    _startCooldown();

    // 立即弹出模态框，sendCode 在模态框内部异步执行
    final result = await showEmailVerificationModal(
      context,
      email: email,
      purpose: 'login',
    );

    if (result == null || !mounted) return;

    // 验证码验证通过，调用登录接口
    setState(() => _isLoading = true);
    try {
      final user = await UserApi.loginByCode(
        email: email,
        code: result['code']!,
      );

      // ✨ 2. 异步请求回来后，必须进行 mounted 安全校验，防止跨异步 gap 导致内存崩溃
      if (!mounted) return;

      await context.read<UserProvider>().updateUserInfo(user);

      if (!mounted) return;
      AppToast.success(
        context,
        message: '欢迎回来，${user.username}',
        title: '登录成功',
      );
      context.go('/home');
    } on DioException catch (e) {
      if (!mounted) return;
      final msg = HttpUtils.extractErrorMessage(e);
      AppToast.error(context, message: msg, title: '登录失败');
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, message: "发生未知错误: $e", title: '登录失败');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// 邮箱+密码登录
  Future<void> _loginByPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final user = await UserApi.loginByPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      await context.read<UserProvider>().updateUserInfo(user);

      if (!mounted) return;
      AppToast.success(
        context,
        message: '欢迎回来，${user.username}',
        title: '登录成功',
      );
      context.go('/home');
    } on DioException catch (e) {
      if (!mounted) return;
      final msg = HttpUtils.extractErrorMessage(e);
      AppToast.error(context, message: msg, title: '登录失败');
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, message: "发生未知错误: $e", title: '登录失败');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// 选择注册头像
  Future<void> _pickAvatar() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 500,
      maxHeight: 500,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() => _avatarImage = picked);
    }
  }

  /// 注册：立即弹窗，验证码在模态框内异步发送
  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();

    // 冷却中不允许重复打开（防刷）
    if (_sendCooldown > 0) {
      AppToast.neutral(
        context,
        message: '$_sendCooldown秒后可重新发送验证码',
        title: '请稍候',
      );
      return;
    }
    _startCooldown();

    // 立即弹出模态框，sendCode 在模态框内部异步执行
    final result = await showEmailVerificationModal(
      context,
      email: email,
      purpose: 'register',
    );

    if (result == null || !mounted) return;

    setState(() => _isLoading = true);
    try {
      final user = await UserApi.register(
        email: email,
        code: result['code']!,
        username: _usernameController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      await context.read<UserProvider>().updateUserInfo(user);

      if (!mounted) return;

      // 注册成功后，如果有选择本地头像，上传到 OSS
      if (_avatarImage != null) {
        try {
          final bytes = await File(_avatarImage!.path).readAsBytes();
          final avatarUrl = await UserApi.uploadAvatar(
            avatarBytes: bytes,
            fileName: _avatarImage!.name,
          );
          // 用新的头像 URL 创建 updatedUser 并持久化
          final updatedUser = User(
            username: user.username,
            email: user.email,
            avatarURL: avatarUrl,
            token: user.token,
          );
          if (!mounted) return;
          await context.read<UserProvider>().updateUserInfo(updatedUser);
        } catch (_) {
          // 头像上传失败不影响注册流程
        }
      }

      if (!mounted) return;
      AppToast.success(
        context,
        message: '注册成功，欢迎 ${user.username}',
        title: '欢迎加入',
      );
      context.go('/home');
    } on DioException catch (e) {
      if (!mounted) return;
      final msg = HttpUtils.extractErrorMessage(e);
      AppToast.error(context, message: msg, title: '注册失败');
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, message: "发生未知错误: $e", title: '注册失败');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─────────────────── UI 构建 ───────────────────

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_mode == 'register' ? '注册' : '欢迎回来'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ── 头像区 ──
                    _buildAvatarPreview(colorScheme),
                    const SizedBox(height: 24),

                    // ── 模式切换按钮 ──
                    _buildModeSwitcher(colorScheme, textTheme),
                    const SizedBox(height: 24),

                    // ── 邮箱输入 ──
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: '邮箱',
                        prefixIcon: Icon(Icons.email_outlined),
                        hintText: 'example@mail.com',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入邮箱';
                        }
                        if (!value.contains('@') || !value.contains('.')) {
                          return '请输入有效的邮箱地址';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // ── 用户名输入 ──
                    if (_mode == 'register') ...[
                      TextFormField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          labelText: '用户名',
                          prefixIcon: Icon(Icons.person_outline),
                          hintText: '给自己起个名字吧',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '请输入用户名';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ── 密码输入 ──
                    if (_mode == 'password' || _mode == 'register') ...[
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: '密码',
                          prefixIcon: const Icon(Icons.lock_outline),
                          hintText: '至少6位',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(
                                () => _obscurePassword = !_obscurePassword,
                              );
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '请输入密码';
                          }
                          if (value.length < 6) {
                            return '密码至少6位';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                    ],

                    if (_mode == 'register')
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          '点击注册后将发送邮箱验证码',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),

                    // ── 主操作按钮 ──
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                switch (_mode) {
                                  case 'code':
                                    _loginByCode();
                                    break;
                                  case 'password':
                                    _loginByPassword();
                                    break;
                                  case 'register':
                                    _register();
                                    break;
                                }
                              },
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(_getButtonLabel()),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── 底部导航链接 ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _mode == 'register' ? '已有账号？' : '没有账号？',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _mode = _mode == 'register' ? 'code' : 'register';
                            });
                          },
                          child: Text(_mode == 'register' ? '去登录' : '立即注册'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 构建模式切换按钮组
  Widget _buildModeSwitcher(ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      // ✨ 4. 适配最新 Material 3 规范：将旧版的废弃属性 surfaceContainerHighest 改为最佳实践 surfaceContainerHigh
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          if (_mode != 'register')
            Expanded(
              child: _ModeButton(
                label: '验证码登录',
                icon: Icons.sms_outlined,
                isSelected: _mode == 'code',
                colorScheme: colorScheme,
                onTap: () => setState(() => _mode = 'code'),
              ),
            ),
          if (_mode != 'register')
            Expanded(
              child: _ModeButton(
                label: '密码登录',
                icon: Icons.lock_outline,
                isSelected: _mode == 'password',
                colorScheme: colorScheme,
                onTap: () => setState(() => _mode = 'password'),
              ),
            ),
          if (_mode == 'register')
            Expanded(
              child: _ModeButton(
                label: '邮箱注册',
                icon: Icons.person_add_outlined,
                isSelected: true,
                colorScheme: colorScheme,
                onTap: () {},
              ),
            ),
        ],
      ),
    );
  }

  String _getButtonLabel() {
    switch (_mode) {
      case 'code':
        return '发送验证码并登录';
      case 'password':
        return '登录';
      case 'register':
        return '获取验证码并注册';
      default:
        return '登录';
    }
  }

  Widget _buildAvatarPreview(ColorScheme colorScheme) {
    if (_mode == 'register') {
      return GestureDetector(
        onTap: _pickAvatar,
        child: CircleAvatar(
          radius: 40,
          backgroundColor: colorScheme.primaryContainer,
          backgroundImage: _avatarImage != null
              ? FileImage(File(_avatarImage!.path))
              : null,
          child: _avatarImage == null
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.camera_alt_rounded,
                      size: 28,
                      color: colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '设置头像',
                      style: TextStyle(
                        fontSize: 10,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                )
              : null,
        ),
      );
    }
    return Icon(
      Icons.account_circle_rounded,
      size: 80,
      color: colorScheme.primary,
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.colorScheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurfaceVariant,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
