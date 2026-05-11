import 'package:flutter/material.dart';
import 'package:myapp/router/Extensions/router.dart';
import 'package:myapp/service/Music/index.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SetupStep {
  final String title;
  final String description;
  final IconData icon;
  final Widget content;

  SetupStep({
    required this.title,
    required this.description,
    required this.icon,
    required this.content,
  });
}

class SetupWizardScreen extends StatefulWidget {
  const SetupWizardScreen({super.key});

  @override
  State<SetupWizardScreen> createState() => _SetupWizardScreenState();
}

class _SetupWizardScreenState extends State<SetupWizardScreen> {
  final PageController _controller = PageController();
  int _currentIndex = 0;
  late List<SetupStep> _steps;

  @override
  void initState() {
    super.initState();
    _steps = [
      SetupStep(
        title: "欢迎使用",
        description: "初始化播放器",
        icon: Icons.celebration,
        content: const Text("隐私政策摘要..."),
      ),
      SetupStep(
        title: "系统权限",
        description: "我们需要存储权限以维持运行",
        icon: Icons.security,
        content: ElevatedButton(
          onPressed: () async {
            await MusicService.ensureAndroidAudioPermission();
          },
          child: const Text("立即授权"),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            LinearProgressIndicator(value: (_currentIndex + 1) / _steps.length),

            //中间内容区
            Expanded(
              child: PageView.builder(
                controller: _controller,
                physics: const NeverScrollableScrollPhysics(), //禁止手动滑动,必须点按钮
                onPageChanged: (i) => setState(() {
                  _currentIndex = i;
                }),
                itemCount: _steps.length,
                itemBuilder: (context, index) => _buildStepPage(_steps[index]),
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

                  ElevatedButton(
                    onPressed: () {
                      if (_currentIndex < _steps.length - 1) {
                        _controller.nextPage(
                          duration: Duration(milliseconds: 300),
                          curve: Curves.ease,
                        );
                      } else {
                        //完成配置
                        _finishSetup();
                      }
                    },
                    child: Text(
                      _currentIndex == _steps.length - 1 ? "开始" : "下一步",
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

  Widget _buildStepPage(SetupStep step) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(step.icon, size: 80, color: Theme.of(context).primaryColor),
          const SizedBox(height: 24),
          Text(step.title, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          Text(step.description, textAlign: TextAlign.center),
          const SizedBox(height: 48),
          step.content,
        ],
      ),
    );
  }

  Future<void> _finishSetup() async {
    final pfs = await SharedPreferences.getInstance();
    await pfs.setBool("is_first_run", false);

    if (!mounted) return;
    //跳转到主页
    context.toHome();
  }
}
