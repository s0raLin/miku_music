import 'dart:async';
import 'package:flutter/material.dart';
import 'package:myapp/api/Client/Music/index.dart';
import 'package:myapp/components/Shared/index.dart';
import 'package:myapp/providers/MusicProvider/index.dart';
import 'package:myapp/src/rust/api/audio_info.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

/// 合并了原始歌词和翻译歌词的内部数据结构
class _LyricGroup {
  final int timeMs;
  final String text;
  final String? translation;

  const _LyricGroup({
    required this.timeMs,
    required this.text,
    this.translation,
  });

  bool get hasTranslation =>
      translation != null && translation!.trim().isNotEmpty;
  bool get isEmpty =>
      text.trim().isEmpty &&
      (translation == null || translation!.trim().isEmpty);
}

class LyricsSection extends StatefulWidget {
  const LyricsSection({super.key});

  @override
  State<LyricsSection> createState() => _LyricsSectionState();
}

class _LyricsSectionState extends State<LyricsSection>
    with AutomaticKeepAliveClientMixin {
  final ItemScrollController _scrollController = ItemScrollController();
  final ItemPositionsListener _positionsListener =
      ItemPositionsListener.create();

  bool _isUserInteracting = false;
  int _focusedIndex = -1;
  Timer? _interactionTimeout;
  List<LyricLine> _prevLyrics = [];
  List<_LyricGroup> _lyricGroups = [];
  int _lastAutoScrollIndex = -1;

  @override
  bool get wantKeepAlive => true;

  /// 将原始 [LyricLine] 列表按相同时间戳合并为 [_LyricGroup]。
  static List<_LyricGroup> _mergeLyrics(List<LyricLine> lyrics) {
    if (lyrics.isEmpty) return [];
    final merged = <_LyricGroup>[];
    int i = 0;
    while (i < lyrics.length) {
      final current = lyrics[i];
      String? translation;
      if (i + 1 < lyrics.length && lyrics[i + 1].timeMs == current.timeMs) {
        translation = lyrics[i + 1].text;
        i += 2;
      } else {
        i += 1;
      }
      merged.add(
        _LyricGroup(
          timeMs: current.timeMs,
          text: current.text,
          translation: translation,
        ),
      );
    }
    return merged;
  }

  @override
  void initState() {
    super.initState();
    _positionsListener.itemPositions.addListener(_updateFocusedIndex);
  }

  @override
  void dispose() {
    _positionsListener.itemPositions.removeListener(_updateFocusedIndex);
    _interactionTimeout?.cancel();
    super.dispose();
  }

  void _updateFocusedIndex() {
    if (!_isUserInteracting) return;
    final positions = _positionsListener.itemPositions.value;
    if (positions.isEmpty) return;

    int closestIndex = _focusedIndex;
    double minDelta = double.infinity;

    for (var pos in positions) {
      final center = (pos.itemLeadingEdge + pos.itemTrailingEdge) / 2;
      final delta = (center - 0.5).abs();
      if (delta < minDelta) {
        minDelta = delta;
        closestIndex = pos.index;
      }
    }

    if (closestIndex != _focusedIndex) {
      setState(() => _focusedIndex = closestIndex);
    }
  }

  void _startUserInteraction() {
    _interactionTimeout?.cancel();
    if (!_isUserInteracting) {
      setState(() => _isUserInteracting = true);
    }
  }

  void _scheduleResumeAutoScroll() {
    _interactionTimeout?.cancel();
    _interactionTimeout = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _isUserInteracting = false);
      }
    });
  }

  bool _lyricsEqual(List<LyricLine> a, List<LyricLine> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].timeMs != b[i].timeMs || a[i].text != b[i].text) {
        return false;
      }
    }
    return true;
  }

  String _formatTime(int ms) {
    final dur = Duration(milliseconds: ms);
    final min = dur.inMinutes.toString().padLeft(2, '0');
    final sec = (dur.inSeconds % 60).toString().padLeft(2, '0');
    return '$min:$sec';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final lyrics = context.read<MusicProvider>().currentLyrics;
    if (!_lyricsEqual(lyrics, _prevLyrics)) {
      _prevLyrics = List.from(lyrics);
      _lyricGroups = _mergeLyrics(lyrics);
      _lastAutoScrollIndex = -1;
      _focusedIndex = -1;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final mp = context.watch<MusicProvider>();
    final lyrics = mp.currentLyrics;
    final cs = Theme.of(context).colorScheme;

    if (_lyricGroups.isEmpty && lyrics.isNotEmpty) {
      _lyricGroups = _mergeLyrics(lyrics);
    }

    if (_lyricGroups.isEmpty) {
      return _buildEmptyState(mp, context);
    }

    return StreamBuilder<PositionData>(
      stream: mp.positionDataStream,
      builder: (context, snapshot) {
        final positionMs = snapshot.data?.position.inMilliseconds ?? 0;
        final currentIndex = _calculateCurrentIndex(positionMs);
        _handleAutoScroll(currentIndex);

        return Stack(
          children: [
            // 使用 LayoutBuilder 动态获取容器高度，以实现精准的居中 Padding
            LayoutBuilder(
              builder: (context, constraints) {
                final halfHeight = constraints.maxHeight / 2;
                return _buildLyricsList(currentIndex, cs, halfHeight);
              },
            ),
            if (_isUserInteracting && _focusedIndex >= 0)
              _buildCenterInteractionBar(cs),
            _buildFadeGradient(Alignment.topCenter, cs),
            _buildFadeGradient(Alignment.bottomCenter, cs),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(MusicProvider mp, BuildContext context) {
    return AppEmptyState(
      icon: Icons.music_note_rounded,
      title: "暂无歌词",
      subtitle: "点击下方按钮查找",
      action: FilledButton.icon(
        onPressed: () => _searchLyrics(mp, context),
        label: const Text("下载歌词"),
        icon: const Icon(Icons.download_rounded),
      ),
    );
  }

  Future<void> _searchLyrics(MusicProvider mp, BuildContext context) async {
    AppToast.neutral(context, message: "正在查找中...");
    try {
      final music = mp.currentMusic;
      final result = await MusicApi.searchLyrics(music?.artist, music?.title);
      if (!context.mounted) return;
      if (!result.$2) {
        AppToast.neutral(context, message: "暂未找到歌词");
        return;
      }
      mp.setCurrentLrc(result.$1);
      AppToast.neutral(context, message: "歌词获取成功");
    } catch (e) {
      AppToast.error(context, message: "歌词获取失败");
    }
  }

  int _calculateCurrentIndex(int positionMs) {
    final groups = _lyricGroups;
    for (int i = groups.length - 1; i >= 0; i--) {
      if (positionMs >= groups[i].timeMs) return i;
    }
    return 0;
  }

  void _handleAutoScroll(int currentIndex) {
    if (_isUserInteracting ||
        currentIndex == _lastAutoScrollIndex ||
        !_scrollController.isAttached) {
      return;
    }
    _lastAutoScrollIndex = currentIndex;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scrollController.scrollTo(
        index: currentIndex,
        alignment: 0.5, // 始终保持正中心对齐
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Widget _buildLyricsList(
    int currentIndex,
    ColorScheme cs,
    double verticalPadding,
  ) {
    final groups = _lyricGroups;
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollStartNotification &&
              notification.dragDetails != null) {
            _startUserInteraction();
          } else if (notification is ScrollEndNotification) {
            _scheduleResumeAutoScroll();
          }
          return false;
        },
        child: ScrollablePositionedList.builder(
          itemScrollController: _scrollController,
          itemPositionsListener: _positionsListener,
          // 核心改动：动态设置上下 Padding 为视图的一半高度，使首尾行可达正中间
          padding: EdgeInsets.symmetric(vertical: verticalPadding),
          itemCount: groups.length,
          itemBuilder: (context, index) =>
              _buildLyricItem(groups[index], index, currentIndex, cs),
        ),
      ),
    );
  }

  Widget _buildLyricItem(
    _LyricGroup group,
    int index,
    int currentIndex,
    ColorScheme cs,
  ) {
    final isActive = _isUserInteracting
        ? (index == _focusedIndex)
        : (index == currentIndex);
    final isNear = _isUserInteracting
        ? (index - _focusedIndex).abs() == 1
        : (index - currentIndex).abs() == 1;

    // 1. 如果是空白行（间奏/纯音乐部分）的特殊渲染
    if (group.isEmpty) {
      return InkWell(
        onTap: () {
          context.read<MusicProvider>().player.seek(
            Duration(milliseconds: group.timeMs),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          // 给空白行一个固定的高度，确保滚动到这里时能完美居中停顿
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          alignment: Alignment.center,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 180),
            // 如果正在播放这一行，就让间奏标识变亮，否则淡化
            opacity: isActive ? 1.0 : (isNear ? 0.5 : 0.2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.music_note_rounded,
                  size: isActive ? 20 : 16,
                  color: isActive ? cs.primary : cs.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  "• • •",
                  style: TextStyle(
                    fontSize: isActive ? 16 : 14,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    color: isActive ? cs.primary : cs.onSurfaceVariant,
                    letterSpacing: 4,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 2. 以下是正常有歌词行的渲染（保持原有逻辑，仅微调间距）
    final TextStyle originalStyle = isActive
        ? TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: cs.primary,
            height: 1.35,
          )
        : isNear
        ? TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w500,
            color: cs.onSurface.withValues(alpha: 0.75),
            height: 1.35,
          )
        : TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: cs.onSurfaceVariant.withValues(alpha: 0.85),
            height: 1.35,
          );

    final TextStyle translationStyle = isActive
        ? TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: cs.primary.withValues(alpha: 0.65),
            height: 1.3,
          )
        : isNear
        ? TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: cs.onSurface.withValues(alpha: 0.45),
            height: 1.3,
          )
        : TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w300,
            color: cs.onSurfaceVariant.withValues(alpha: 0.5),
            height: 1.3,
          );

    return InkWell(
      onTap: () {
        context.read<MusicProvider>().player.seek(
          Duration(milliseconds: group.timeMs),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              style: originalStyle,
              child: Text(
                group.text,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (group.hasTranslation) ...[
              const SizedBox(height: 2),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                style: translationStyle,
                child: Text(
                  group.translation!,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCenterInteractionBar(ColorScheme cs) {
    final groups = _lyricGroups;
    if (_focusedIndex >= groups.length) return const SizedBox.shrink();
    final focusedGroup = groups[_focusedIndex];

    return IgnorePointer(
      ignoring: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  context.read<MusicProvider>().player.seek(
                    Duration(milliseconds: focusedGroup.timeMs),
                  );
                  setState(() => _isUserInteracting = false);
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Icon(
                    Icons.play_circle_filled_rounded,
                    color: cs.primary,
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Divider(
                  color: cs.primary.withValues(alpha: 0.35),
                  thickness: 1.5,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _formatTime(focusedGroup.timeMs),
                style: TextStyle(
                  color: cs.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFadeGradient(Alignment alignment, ColorScheme cs) {
    return IgnorePointer(
      child: Align(
        alignment: alignment,
        child: Container(
          height: 90,
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
  }
}
