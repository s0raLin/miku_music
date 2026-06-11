import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/components/Shared/index.dart';
import 'package:myapp/model/Music/index.dart';
import 'package:myapp/providers/MusicProvider/index.dart';
import 'package:myapp/views/MusicDetail/layout/narrow_layout.dart';
import 'package:myapp/views/MusicDetail/layout/wide_layout.dart';

import 'package:provider/provider.dart';

// ─── 主页面 ───────────────────────────────────────────────────────────────────

class MusicDetailPage extends StatefulWidget {
  const MusicDetailPage({super.key});

  @override
  State<MusicDetailPage> createState() => _MusicDetailPageState();
}

class _MusicDetailPageState extends State<MusicDetailPage> {
  bool _hadMusic = false;

  @override
  Widget build(BuildContext context) {
    final music = context.select<MusicProvider, Music?>((p) => p.currentMusic);

    // 记录曾经有过歌曲，用于区分"首次进入但播放未就绪" vs "清空队列"
    if (music != null) {
      _hadMusic = true;
    }

    if (music == null) {
      // 只有之前有歌曲（说明是清空队列导致），才自动返回上一页
      // 首次进入时 currentMusic 可能尚未就绪（如网络搜索异步加载中），不自动 pop
      if (_hadMusic) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            GoRouter.of(context).pop();
          }
        });
      }
      return AppEmptyState(
        icon: Icons.music_note_rounded,
        title: "未选择歌曲",
        subtitle: _hadMusic ? "队列已清空" : "正在加载...",
      );
    }
    final isWide = MediaQuery.sizeOf(context).width > 700;

    return isWide
        ? WideLayout(music: music)
        : NarrowLayout(music: music);
  }
}
