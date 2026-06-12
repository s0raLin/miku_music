import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:myapp/api/Client/Auth/index.dart';
import 'package:myapp/utils/Http/index.dart';

/// 邮箱验证码模态窗口
///
/// 用法:
/// ```dart
/// final result = await showEmailVerificationModal(
///   context,
///   email: 'user@example.com',
///   purpose: 'register', // 或 'login'
/// );
/// if (result != null) {
///   // result 包含 { 'code': '123456', 'email': 'user@example.com' }
/// }
/// ```
///
/// 流程:
/// 1. 显示已输入的邮箱
/// 2. 自动发送验证码（如果 initialCountdown 为 0 或未指定）
/// 3. 用户输入 6 位验证码
/// 4. 点击验证后关闭模态窗口并返回验证码
///
/// [initialCountdown] 默认 0，表示进入后立即自动发送。
/// 如果调用方已提前发送了验证码，可传入 60 直接进入倒计时状态。
Future<Map<String, String>?> showEmailVerificationModal(
  BuildContext context, {
  required String email,
  required String purpose, // "register" 或 "login"
  int initialCountdown = 0,
}) {
  return showDialog<Map<String, String>>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _EmailVerificationDialog(
      email: email,
      purpose: purpose,
      initialCountdown: initialCountdown,
    ),
  );
}

class _EmailVerificationDialog extends StatefulWidget {
  final String email;
  final String purpose;
  final int initialCountdown;

  const _EmailVerificationDialog({
    required this.email,
    required this.purpose,
    required this.initialCountdown,
  });

  @override
  State<_EmailVerificationDialog> createState() =>
      _EmailVerificationDialogState();
}

class _EmailVerificationDialogState extends State<_EmailVerificationDialog> {
  final _codeController = TextEditingController();
  final _codeFocusNode = FocusNode();
  bool _isSending = false;
  final bool _isVerifying = false;
  bool _codeSent = false;
  int _countdown = 0;
  Timer? _timer;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    if (widget.initialCountdown > 0) {
      // 调用方已经发送了验证码，直接进入已发送状态
      _codeSent = true;
      _countdown = widget.initialCountdown;
      _startCountdown();
      _codeFocusNode.requestFocus();
    } else {
      // 默认行为：自动发送验证码
      _sendCode();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeController.dispose();
    _codeFocusNode.dispose();
    super.dispose();
  }

  /// 发送验证码
  Future<void> _sendCode() async {
    if (_countdown > 0 || _isSending) return; // 倒计时中不允许重复发送

    setState(() {
      _isSending = true;
      _errorMsg = null;
    });

    try {
      await UserApi.sendCode(
        email: widget.email,
        purpose: widget.purpose,
      );

      if (!mounted) return;
      setState(() {
        _codeSent = true;
        _countdown = 60; // 60秒后可重发
      });

      // 启动倒计时
      _startCountdown();

      // 自动聚焦输入框
      _codeFocusNode.requestFocus();
    } on DioException catch (e) {
      if (!mounted) return;
      final msg = HttpUtils.extractErrorMessage(e);
      setState(() => _errorMsg = msg);
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  void _startCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_countdown > 0) {
          _countdown--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  /// 点击验证按钮
  Future<void> _verify() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      setState(() => _errorMsg = '请输入6位验证码');
      return;
    }

    // 直接返回验证码，由调用方完成注册/登录
    Navigator.of(context).pop({
      'code': code,
      'email': widget.email,
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.email_outlined,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            widget.purpose == 'register' ? '验证邮箱' : '登录验证',
          ),
        ],
      ),
      content: SizedBox(
        width: 340,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 已输入的邮箱提示
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.email, size: 18, color: colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.email,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 说明文字
            Text(
              _codeSent
                  ? '验证码已发送至上述邮箱，请在下方输入6位验证码'
                  : '正在发送验证码...',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),

            // 验证码输入框
            TextField(
              controller: _codeController,
              focusNode: _codeFocusNode,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: textTheme.headlineMedium?.copyWith(
                letterSpacing: 8,
              ),
              decoration: InputDecoration(
                hintText: '000000',
                counterText: '',
                errorText: _errorMsg,
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                setState(() => _errorMsg = null);
              },
            ),
            const SizedBox(height: 12),

            // 重发按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '没有收到验证码？',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                TextButton(
                  onPressed: _countdown > 0 || _isSending
                      ? null
                      : () => _sendCode(),
                  child: Text(
                    _countdown > 0
                        ? '${_countdown}s 后重发'
                        : '重新发送',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _isVerifying ? null : _verify,
          child: _isVerifying
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('验证'),
        ),
      ],
    );
  }
}
