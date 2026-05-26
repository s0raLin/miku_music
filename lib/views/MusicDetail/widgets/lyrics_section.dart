// ─── 歌词区域 ─────────────────────────────────────────────────────────────────

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:myapp/api/Client/Music/index.dart';
import 'package:myapp/components/Shared/index.dart';
import 'package:myapp/providers/MusicProvider/index.dart';
import 'package:myapp/src/rust/api/audio_info.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class LyricsSection extends StatefulWidget {
  const LyricsSection({super.key});

  @override
  State<LyricsSection> createState() => _LyricsSectionState();
}

class _LyricsSectionState extends State<LyricsSection>
    with AutomaticKeepAliveClientMixin {
  final ItemScrollController _scrollController = ItemScrollController();
  // 1. 引入位置监听器
  final ItemPositionsListener _positionsListener =
      ItemPositionsListener.create();

  int _lastAutoScrollIndex = -1;
  List<LyricLine> _prevLyrics = [];

  // 2. 新增：控制是否处于用户手动拖动聚焦状态
  bool _isUserDragging = false;
  int _focusedIndex = -1; // 当前被拖动到中间的歌词行索引
  Timer? _dragEndTimer; // 用于拖动结束后的倒计时恢复

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // 3. 监听滚动位置，找出最靠近中心的歌词
    _positionsListener.itemPositions.addListener(_updateFocusedIndex);
  }

  @override
  void dispose() {
    _positionsListener.itemPositions.removeListener(_updateFocusedIndex);
    _dragEndTimer?.cancel();
    super.dispose();
  }

  void _updateFocusedIndex() {
    if (!_isUserDragging) return;

    final positions = _positionsListener.itemPositions.value;
    if (positions.isEmpty) return;

    // 寻找到屏幕中间（alignment 接近 0.5）的 Item
    double minDelta = double.infinity;
    int closestIndex = _focusedIndex;

    for (var position in positions) {
      // item 的中心点相对于视口的位置
      final itemCenter =
          (position.itemLeadingEdge + position.itemTrailingEdge) / 2;
      final delta = (itemCenter - 0.5).abs();
      if (delta < minDelta) {
        minDelta = delta;
        closestIndex = position.index;
      }
    }

    if (closestIndex != _focusedIndex) {
      setState(() {
        _focusedIndex = closestIndex;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final lyrics = context.read<MusicProvider>().currentLyrics;
    if (!_lyricsEqual(lyrics, _prevLyrics)) {
      _prevLyrics = List.from(lyrics);
      _lastAutoScrollIndex = -1;
    }
  }

  bool _lyricsEqual(List<LyricLine> a, List<LyricLine> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].timeMs != b[i].timeMs || a[i].text != b[i].text) {
        return false;
      }
    }
    return true;
  }

  // 将毫秒转为 00:00 格式
  String _formatDuration(int ms) {
    final duration = Duration(milliseconds: ms);
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final mp = context.watch<MusicProvider>();
    final music = mp.currentMusic;
    final lyrics = mp.currentLyrics;

    final cs = Theme.of(context).colorScheme;

    if (lyrics.isEmpty) {
      return AppEmptyState(
        icon: Icons.music_note_rounded,
        title: "暂无歌词",
        subtitle: "点击下方按钮查找",
        action: FilledButton.icon(
          onPressed: () async {
            AppToast.neutral(context, message: "正在查找中...");
            try {
              final result = await MusicApi.searchLyrics(
                music?.artist,
                music?.title,
              );
              final isOk = result.$2;

              if (!context.mounted) return;
              if (!isOk) {
                AppToast.neutral(context, message: "暂未找到歌词");
                return;
              }
              mp.setCurrentLrc(result.$1);
              AppToast.neutral(context, message: "歌词获取成功");
            } catch (e) {
              AppToast.error(context, message: "歌词获取失败");
            }
          },
          label: const Text("下载歌词"),
          icon: const Icon(Icons.download_rounded),
        ),
      );
    }

    return StreamBuilder<PositionData>(
      stream: context.read<MusicProvider>().positionDataStream,
      builder: (context, snapshot) {
        final positionMs = snapshot.data?.position.inMilliseconds ?? 0;

        int currentIndex = 0;
        for (var i = 0; i < lyrics.length; i++) {
          if (positionMs >= lyrics[i].timeMs) {
            currentIndex = i;
          } else {
            break;
          }
        }

        // 4. 只有当用户没有拖动歌词时，才允许系统自动随进度条滚动
        if (!_isUserDragging &&
            currentIndex != _lastAutoScrollIndex &&
            _scrollController.isAttached) {
          _lastAutoScrollIndex = currentIndex;
          final isNearEnd = currentIndex >= lyrics.length - 3;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _scrollController.scrollTo(
              index: currentIndex,
              alignment: isNearEnd ? 0.1 : 0.5,
              duration: Duration(milliseconds: isNearEnd ? 340 : 300),
              curve: Curves.easeOutCubic,
            );
          });
        }

        Widget fadeGradient(Alignment alignment) => IgnorePointer(
          child: Align(
            alignment: alignment,
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: alignment,
                  end: alignment == Alignment.topCenter
                      ? Alignment.bottomCenter
                      : Alignment.topCenter,
                  colors: [cs.surface, cs.surface.withValues(alpha: 0)],
                ),
              ),
            ),
          ),
        );

        return Stack(
          children: [
            // 5. 包裹 NotificationListener 用于捕获用户的滚动开始和结束手势
            NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification is ScrollStartNotification) {
                  if (notification.dragDetails != null) {
                    _dragEndTimer?.cancel();
                    setState(() {
                      _isUserDragging = true;
                    });
                  }
                } else if (notification is ScrollEndNotification) {
                  // 用户松开手 3 秒后，恢复自动滚动
                  _dragEndTimer?.cancel();
                  _dragEndTimer = Timer(const Duration(seconds: 3), () {
                    if (mounted) {
                      setState(() {
                        _isUserDragging = false;
                      });
                    }
                  });
                }
                return false;
              },
              child: ScrollablePositionedList.builder(
                itemScrollController: _scrollController,
                itemPositionsListener: _positionsListener, // 注入位置监听器
                itemCount: lyrics.length,
                padding: const EdgeInsets.symmetric(
                  vertical: 240,
                ), // 增加上下边距，让首尾歌词也能滚到正中间
                itemBuilder: (context, index) {
                  final item = lyrics[index];
                  final isTextEmpty = item.text.trim().isEmpty;

                  // 如果在拖动中，被聚焦的行高亮；否则正在播放的行高亮
                  final isActive = _isUserDragging
                      ? (index == _focusedIndex)
                      : (index == currentIndex);
                  final isNear = _isUserDragging
                      ? ((index - _focusedIndex).abs() == 1)
                      : ((index - currentIndex).abs() == 1);

                  // 基础样式分级分配
                  var style = isActive
                      ? TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: cs.primary,
                          height: 1.4,
                        )
                      : isNear
                      ? TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: cs.onSurface.withValues(alpha: 0.6),
                          height: 1.4,
                        )
                      : TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.8),
                          height: 1.4,
                        );

                  // 💡 视觉调优：如果当前行为波浪号（~）且非当前高亮激活行，将其色彩调淡并转换为细体，防止背景杂乱
                  if (isTextEmpty && !isActive) {
                    style = style.copyWith(
                      color: style.color?.withValues(alpha: 0.25),
                      fontWeight: FontWeight.w300,
                    );
                  }

                  return InkWell(
                    onTap: () => context.read<MusicProvider>().player.seek(
                      Duration(milliseconds: item.timeMs),
                    ),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 24,
                      ),
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                        style: style,
                        child: Text(
                          // 如果歌词文本为空或者全是空格，则替换为 '~'
                          isTextEmpty ? '~' : item.text,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // 正中间的划线与播放控制层（仅在用户拖动时显现）
            if (_isUserDragging &&
                _focusedIndex >= 0 &&
                _focusedIndex < lyrics.length)
              IgnorePointer(
                // 保证这层修饰不会挡住歌词本身的点击事件
                ignoring: false, // 改为 false，允许点击上面的播放按钮
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      children: [
                        // 左侧播放按钮
                        GestureDetector(
                          onTap: () {
                            final targetTime = lyrics[_focusedIndex].timeMs;
                            context.read<MusicProvider>().player.seek(
                              Duration(milliseconds: targetTime),
                            );
                            _dragEndTimer?.cancel();
                            setState(() {
                              _isUserDragging = false;
                            });
                          },
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: Icon(
                              Icons.play_circle_filled_rounded,
                              color: cs.primary,
                              size: 28,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // 中间的横线
                        Expanded(
                          child: Divider(
                            color: cs.primary.withValues(alpha: 0.4),
                            thickness: 1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // 右侧显示该行歌词的时间点
                        Text(
                          _formatDuration(lyrics[_focusedIndex].timeMs),
                          style: TextStyle(
                            color: cs.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            fadeGradient(Alignment.topCenter),
            fadeGradient(Alignment.bottomCenter),
          ],
        );
      },
    );
  }
}
