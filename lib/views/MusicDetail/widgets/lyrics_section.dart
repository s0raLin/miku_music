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
  final int durationMs;
  final String text;
  final String? translation;
  final List<LyricWord> words;

  bool get hasWordTiming => words.length > 1;
  bool get hasTranslation =>
      translation != null && translation!.trim().isNotEmpty;
  bool get isEmpty =>
      text.trim().isEmpty &&
      (translation == null || translation!.trim().isEmpty);

  const _LyricGroup({
    required this.timeMs,
    this.durationMs = 0,
    required this.text,
    this.translation,
    this.words = const [],
  });

  double getProgress(int currentMs) {
    if (durationMs <= 0) return 0.0;
    final end = timeMs + durationMs;
    if (currentMs < timeMs) return 0.0;
    if (currentMs >= end) return 1.0;
    return (currentMs - timeMs) / durationMs;
  }
}

/// 优化版：局部高频平滑渲染组件
/// 采用更高效的逐词微型 ShaderMask 解决多行同时高亮问题
/// 借助 Implicit Animation 缓解快歌语速导致的跟不上、跳跃感
class _ActiveLyricItem extends StatefulWidget {
  final _LyricGroup group;
  final TextStyle baseStyle;
  final ColorScheme cs;
  final Stream<PositionData> positionStream;

  const _ActiveLyricItem({
    required this.group,
    required this.baseStyle,
    required this.cs,
    required this.positionStream,
  });

  @override
  State<_ActiveLyricItem> createState() => _ActiveLyricItemState();
}

class _ActiveLyricItemState extends State<_ActiveLyricItem> {
  StreamSubscription? _sub;
  int _currentPosMs = 0;

  @override
  void initState() {
    super.initState();
    _currentPosMs = widget.group.timeMs;
    _subscribeStream();
  }

  @override
  void didUpdateWidget(covariant _ActiveLyricItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.group.timeMs != widget.group.timeMs ||
        oldWidget.positionStream != widget.positionStream) {
      _currentPosMs = widget.group.timeMs;
      _subscribeStream();
    }
  }

  void _subscribeStream() {
    _sub?.cancel();
    _sub = widget.positionStream.listen((data) {
      if (!mounted) return;
      final ms = data.position.inMilliseconds;
      if (ms >= widget.group.timeMs &&
          (widget.group.durationMs == 0 ||
              ms <= widget.group.timeMs + widget.group.durationMs)) {
        setState(() {
          _currentPosMs = ms;
        });
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final overallProgress = widget.group.getProgress(_currentPosMs);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        widget.group.hasWordTiming
            ? Wrap(
                alignment: WrapAlignment.center,
                runSpacing: 4, // 控制折行后的两行间距
                children: _buildSpacedWords(),
              )
            : Text(
                widget.group.text,
                style: widget.baseStyle,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
        if (widget.group.durationMs > 0)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(
                  begin: overallProgress,
                  end: overallProgress,
                ),
                duration: const Duration(milliseconds: 60), // 利用微小动画平滑突变进度
                curve: Curves.linear,
                builder: (context, val, child) {
                  return LinearProgressIndicator(
                    value: val,
                    minHeight: 3,
                    backgroundColor: widget.cs.onSurface.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation(widget.cs.primary),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  /// 核心逻辑：将一整句话拆分为一个个独立的词或字组件，单独施加高亮
  List<Widget> _buildSpacedWords() {
    final list = <Widget>[];
    final totalWords = widget.group.words.length;

    // 估算每个词的时间跨度（若模型 LyricWord 中本身带有精确时间，直接替换为 word.durationMs 更好）
    final double estimatedWordDuration = widget.group.durationMs / totalWords;

    for (int i = 0; i < totalWords; i++) {
      final word = widget.group.words[i];

      // 计算当前词对应的绝对生命周期时间段
      // 优先读取你的底层数据结构提供的时间，若无则使用均分估算
      final int wordStart =
          widget.group.timeMs + (i * estimatedWordDuration).toInt();
      final int wordEnd = wordStart + estimatedWordDuration.toInt();

      double wordProgress = 0.0;
      if (_currentPosMs >= wordEnd) {
        wordProgress = 1.0; // 已唱完
      } else if (_currentPosMs < wordStart) {
        wordProgress = 0.0; // 还没到
      } else {
        // 正在唱当前词
        wordProgress = (_currentPosMs - wordStart) / (wordEnd - wordStart);
      }

      list.add(
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: wordProgress, end: wordProgress),
          duration: const Duration(milliseconds: 40), // 针对高频快速歌词进行的平滑插值
          curve: Curves.linear,
          builder: (context, progress, child) {
            return ShaderMask(
              shaderCallback: (Rect rect) {
                return LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    widget.cs.primary,
                    widget.cs.onSurface.withValues(alpha: 0.35),
                  ],
                  stops: [progress, progress],
                ).createShader(rect);
              },
              blendMode: BlendMode.srcIn,
              child: Text(
                '${word.text} ',
                style: widget.baseStyle.copyWith(color: Colors.white),
              ),
            );
          },
        ),
      );
    }
    return list;
  }
}

class LyricsSection extends StatefulWidget {
  const LyricsSection({super.key});

  @override
  State<LyricsSection> createState() => _LyricsSectionState();
}

class _LyricsSectionState extends State<LyricsSection>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  final ItemScrollController _scrollController = ItemScrollController();
  final ItemPositionsListener _positionsListener =
      ItemPositionsListener.create();

  bool _isUserInteracting = false;
  int _focusedIndex = -1;
  Timer? _interactionTimeout;

  List<LyricLine> _prevLyrics = [];
  List<_LyricGroup> _lyricGroups = [];
  int _lastAutoScrollIndex = -1;

  int _positionMs = 0;
  int _currentIndex = 0;
  StreamSubscription<PositionData>? _positionSub;

  late AnimationController _breatheController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _positionsListener.itemPositions.addListener(_updateFocusedIndex);
    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

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
          durationMs: current.durationMs,
          text: current.text,
          translation: translation,
          words: current.words,
        ),
      );
    }
    return merged;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final mp = context.read<MusicProvider>();
    final lyrics = mp.currentLyrics;

    if (!_lyricsEqual(lyrics, _prevLyrics)) {
      _prevLyrics = List.from(lyrics);
      _lyricGroups = _mergeLyrics(lyrics);
      _lastAutoScrollIndex = -1;
      _focusedIndex = -1;
      _positionMs = 0;
      _currentIndex = 0;
    }

    _positionSub?.cancel();
    _positionSub = mp.positionDataStream.listen((data) {
      if (!mounted) return;
      final newPos = data.position.inMilliseconds;
      if (newPos == _positionMs) return;

      _positionMs = newPos;
      final newIndex = _calculateCurrentIndex(newPos);

      if (newIndex != _currentIndex) {
        setState(() => _currentIndex = newIndex);
      }
      _handleAutoScroll(_currentIndex);
    });
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _positionsListener.itemPositions.removeListener(_updateFocusedIndex);
    _interactionTimeout?.cancel();
    _breatheController.dispose();
    super.dispose();
  }

  void _updateFocusedIndex() {
    if (!_isUserInteracting) return;
    final positions = _positionsListener.itemPositions.value;
    if (positions.isEmpty) return;

    int closest = _focusedIndex;
    double minDelta = double.infinity;
    for (var pos in positions) {
      final center = (pos.itemLeadingEdge + pos.itemTrailingEdge) / 2;
      final delta = (center - 0.5).abs();
      if (delta < minDelta) {
        minDelta = delta;
        closest = pos.index;
      }
    }
    if (closest != _focusedIndex) {
      setState(() => _focusedIndex = closest);
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
      if (mounted) setState(() => _isUserInteracting = false);
    });
  }

  bool _lyricsEqual(List<LyricLine> a, List<LyricLine> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].timeMs != b[i].timeMs || a[i].text != b[i].text) return false;
    }
    return true;
  }

  String _formatTime(int ms) {
    final dur = Duration(milliseconds: ms);
    final min = dur.inMinutes.toString().padLeft(2, '0');
    final sec = (dur.inSeconds % 60).toString().padLeft(2, '0');
    return '$min:$sec';
  }

  int _calculateCurrentIndex(int positionMs) {
    final groups = _lyricGroups;
    for (int i = groups.length - 1; i >= 0; i--) {
      final g = groups[i];
      if (positionMs >= g.timeMs &&
          (g.durationMs == 0 || positionMs < g.timeMs + g.durationMs)) {
        return i;
      }
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
    _scrollController.scrollTo(
      index: currentIndex,
      alignment: 0.33,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutQuad,
    );
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

    final currentIndex = _isUserInteracting ? _focusedIndex : _currentIndex;

    return Stack(
      children: [
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

  Widget _buildLyricsList(
    int currentIndex,
    ColorScheme cs,
    double verticalPadding,
  ) {
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
          padding: EdgeInsets.symmetric(vertical: verticalPadding),
          itemCount: _lyricGroups.length,
          itemBuilder: (context, index) =>
              _buildLyricItem(_lyricGroups[index], index, currentIndex, cs),
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
    final isCurrentPlaying = (index == _currentIndex);

    final isActive = _isUserInteracting
        ? (index == _focusedIndex)
        : (index == currentIndex);
    final isNear = _isUserInteracting
        ? (index - _focusedIndex).abs() == 1
        : (index - currentIndex).abs() == 1;

    final baseStyle = isActive
        ? TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: cs.primary,
            height: 1.4,
          )
        : isNear
        ? TextStyle(
            fontSize: 17.5,
            fontWeight: FontWeight.w600,
            color: cs.onSurface.withValues(alpha: 0.9),
            height: 1.4,
          )
        : TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.w400,
            color: cs.onSurfaceVariant.withValues(alpha: 0.85),
            height: 1.4,
          );

    final translationStyle = isActive
        ? TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            color: cs.primary.withValues(alpha: 0.75),
            height: 1.4,
          )
        : TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: cs.onSurfaceVariant.withValues(alpha: 0.6),
            height: 1.4,
          );

    if (group.isEmpty) {
      return _buildEmptyLyricItem(group, isActive, cs);
    }

    final mp = context.read<MusicProvider>();

    return InkWell(
      onTap: () {
        mp.player.seek(Duration(milliseconds: group.timeMs));
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            isActive && isCurrentPlaying
                ? _ActiveLyricItem(
                    group: group,
                    baseStyle: baseStyle,
                    cs: cs,
                    positionStream: mp.positionDataStream,
                  )
                : Text(
                    group.text,
                    style: baseStyle,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
            if (group.hasTranslation) ...[
              const SizedBox(height: 4),
              Text(
                group.translation!,
                style: translationStyle,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (isActive && !isCurrentPlaying && group.durationMs > 0)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: group.getProgress(_positionMs),
                    minHeight: 3,
                    backgroundColor: cs.onSurface.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation(cs.primary),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyLyricItem(
    _LyricGroup group,
    bool isActive,
    ColorScheme cs,
  ) {
    return InkWell(
      onTap: () {
        context.read<MusicProvider>().player.seek(
          Duration(milliseconds: group.timeMs),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: AnimatedBuilder(
          animation: _breatheController,
          builder: (context, child) {
            final scale = 0.96 + _breatheController.value * 0.08;
            return Transform.scale(
              scale: isActive ? scale : 1.0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.music_note_rounded,
                    size: isActive ? 28 : 24,
                    color: isActive
                        ? cs.primary
                        : cs.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "• • •",
                    style: TextStyle(
                      fontSize: isActive ? 24 : 19,
                      letterSpacing: 8,
                      fontWeight: isActive
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isActive
                          ? cs.primary
                          : cs.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCenterInteractionBar(ColorScheme cs) {
    if (_focusedIndex < 0 || _focusedIndex >= _lyricGroups.length) {
      return const SizedBox.shrink();
    }
    final focusedGroup = _lyricGroups[_focusedIndex];

    return IgnorePointer(
      ignoring: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  context.read<MusicProvider>().player.seek(
                    Duration(milliseconds: focusedGroup.timeMs),
                  );
                  setState(() => _isUserInteracting = false);
                },
                child: Icon(
                  Icons.play_circle_filled_rounded,
                  color: cs.primary,
                  size: 36,
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
                  fontSize: 14,
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
          height: 100,
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
