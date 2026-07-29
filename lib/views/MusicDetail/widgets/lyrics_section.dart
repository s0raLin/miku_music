import 'dart:async';
import 'package:flutter/material.dart';
import 'package:myapp/components/Shared/index.dart';
import 'package:myapp/providers/MusicProvider/index.dart';
import 'package:myapp/src/rust/api/audio_info.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class _LyricGroup {
  final int timeMs;
  final int durationMs;
  final String text;
  final String? translation;
  final List<LyricWord> words;
  final bool isEmpty;
  final bool isLongGap;

  bool get hasWordTiming => words.length > 1;
  bool get hasTranslation =>
      translation != null && translation!.trim().isNotEmpty;

  const _LyricGroup({
    required this.timeMs,
    this.durationMs = 0,
    this.text = '',
    this.translation,
    this.words = const [],
    this.isEmpty = false,
    this.isLongGap = false,
  });

  double getProgress(int currentMs) {
    if (durationMs <= 0) return 0.0;
    final end = timeMs + durationMs;
    if (currentMs < timeMs) return 0.0;
    if (currentMs >= end) return 1.0;
    return (currentMs - timeMs) / durationMs;
  }
}

class _ActiveLyricItem extends StatefulWidget {
  final _LyricGroup group;
  final TextStyle baseStyle;
  final Color activeColor;
  final Color inactiveColor;
  final Stream<PositionData> positionStream;

  const _ActiveLyricItem({
    required this.group,
    required this.baseStyle,
    required this.activeColor,
    required this.inactiveColor,
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
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        widget.group.hasWordTiming
            ? Wrap(
                alignment: WrapAlignment.center,
                runSpacing: 4,
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
                duration: const Duration(milliseconds: 60),
                curve: Curves.linear,
                builder: (context, val, child) {
                  return LinearProgressIndicator(
                    value: val,
                    minHeight: 3,
                    backgroundColor: widget.inactiveColor.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation(widget.activeColor),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  List<Widget> _buildSpacedWords() {
    final list = <Widget>[];
    final totalWords = widget.group.words.length;
    if (totalWords == 0) return list;
    final double estimatedWordDuration =
        widget.group.durationMs / totalWords;

    for (int i = 0; i < totalWords; i++) {
      final word = widget.group.words[i];
      final int wordStart =
          widget.group.timeMs + (i * estimatedWordDuration).toInt();
      final int wordEnd = wordStart + estimatedWordDuration.toInt();

      double wordProgress = 0.0;
      if (_currentPosMs >= wordEnd) {
        wordProgress = 1.0;
      } else if (_currentPosMs < wordStart) {
        wordProgress = 0.0;
      } else {
        wordProgress =
            (_currentPosMs - wordStart) / (wordEnd - wordStart);
      }

      list.add(
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: wordProgress, end: wordProgress),
          duration: const Duration(milliseconds: 40),
          curve: Curves.linear,
          builder: (context, progress, child) {
            return ShaderMask(
              shaderCallback: (Rect rect) {
                return LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    widget.activeColor,
                    widget.inactiveColor.withValues(alpha: 0.35),
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

  static const _longGapThreshold = 3000;

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
    if (lyrics.isEmpty) return const [];

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
      final text = current.text.trim();
      final transTrimmed = translation?.trim() ?? '';
      final isEmpty = text.isEmpty && transTrimmed.isEmpty;
      merged.add(
        _LyricGroup(
          timeMs: current.timeMs,
          durationMs: current.durationMs,
          text: current.text,
          translation: translation,
          words: current.words,
          isEmpty: isEmpty,
        ),
      );
    }

    final result = <_LyricGroup>[];
    _LyricGroup? lastNonEmpty;
    for (final group in merged) {
      if (!group.isEmpty) {
        result.add(group);
        lastNonEmpty = group;
      } else if (lastNonEmpty != null) {
        final gap = group.timeMs - lastNonEmpty.timeMs;
        if (gap >= _longGapThreshold) {
          result.add(
            _LyricGroup(
              timeMs: group.timeMs,
              durationMs: 0,
              text: '',
              translation: null,
              words: const [],
              isEmpty: true,
              isLongGap: true,
            ),
          );
        }
      }
    }
    return result;
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

    final currentLyricsEmpty = _lyricGroups.isEmpty;
    final currentIndex = _isUserInteracting ? _focusedIndex : _currentIndex;

    return Stack(
      children: [
        if (currentLyricsEmpty)
          _buildEmptyState(mp, context)
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final halfHeight = constraints.maxHeight / 2;
              return _buildLyricsList(currentIndex, cs, halfHeight);
            },
          ),
        if (_isUserInteracting && _focusedIndex >= 0)
          _buildCenterInteractionBar(cs),
      ],
    );
  }

  Widget _buildEmptyState(MusicProvider mp, BuildContext context) {
    return AppEmptyState(
      icon: Icons.lyrics_rounded,
      title: "暂无歌词",
      subtitle: "点击右上角「歌词」图标切换来源",
    );
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

    final activeColor = cs.onSurface;
    final inactiveColor = cs.onSurfaceVariant;

    final baseStyle = isActive || isNear
        ? TextStyle(
            fontSize: isActive ? 23 : 18,
            fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
            color: isActive ? activeColor : inactiveColor.withValues(alpha: 0.9),
            height: 1.45,
          )
        : TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: inactiveColor.withValues(alpha: 0.75),
            height: 1.45,
          );

    final translationStyle = isActive
        ? TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: inactiveColor.withValues(alpha: 0.85),
            height: 1.4,
          )
        : TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w400,
            color: inactiveColor.withValues(alpha: 0.65),
            height: 1.4,
          );

    if (group.isEmpty && !group.isLongGap) {
      return const SizedBox.shrink();
    }

    if (group.isEmpty && group.isLongGap) {
      return _buildLongGapItem(cs);
    }

    final mp = context.read<MusicProvider>();
    final targetOpacity = isActive ? 1.0 : (isNear ? 0.9 : 0.7);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOut,
      opacity: targetOpacity,
      child: DefaultTextStyle(
        style: baseStyle,
        child: InkWell(
          onTap: () {
            mp.player.seek(Duration(milliseconds: group.timeMs));
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  isActive && isCurrentPlaying
                      ? _ActiveLyricItem(
                          group: group,
                          baseStyle: baseStyle,
                          activeColor: activeColor,
                          inactiveColor: inactiveColor,
                          positionStream: mp.positionDataStream,
                        )
                      : Text(
                          group.text,
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
                          backgroundColor: activeColor.withValues(alpha: 0.2),
                          valueColor: AlwaysStoppedAnimation(activeColor),
                        ),
                      ),
                    ),
                ],
              ),
          ),
        ),
      ),
    );
  }

  Widget _buildLongGapItem(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Center(
        child: Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            color: cs.onSurfaceVariant.withValues(alpha: 0.35),
            shape: BoxShape.circle,
          ),
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
}
