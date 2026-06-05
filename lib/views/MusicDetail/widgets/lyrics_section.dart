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
  final ItemPositionsListener _positionsListener =
      ItemPositionsListener.create();

  bool _isUserInteracting = false; // 用户是否正在手动操作
  int _focusedIndex = -1; // 拖动时中间聚焦的行
  Timer? _interactionTimeout; // 超时后恢复自动滚动

  List<LyricLine> _prevLyrics = [];
  int _lastAutoScrollIndex = -1;

  @override
  bool get wantKeepAlive => true;

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

    if (lyrics.isEmpty) {
      return _buildEmptyState(mp, context);
    }

    return StreamBuilder<PositionData>(
      stream: mp.positionDataStream,
      builder: (context, snapshot) {
        final positionMs = snapshot.data?.position.inMilliseconds ?? 0;
        final currentIndex = _calculateCurrentIndex(lyrics, positionMs);

        _handleAutoScroll(currentIndex, lyrics);

        return Stack(
          children: [
            _buildLyricsList(lyrics, currentIndex, cs),
            if (_isUserInteracting && _focusedIndex >= 0)
              _buildCenterInteractionBar(lyrics, cs),
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

  int _calculateCurrentIndex(List<LyricLine> lyrics, int positionMs) {
    for (int i = lyrics.length - 1; i >= 0; i--) {
      if (positionMs >= lyrics[i].timeMs) return i;
    }
    return 0;
  }

  void _handleAutoScroll(int currentIndex, List<LyricLine> lyrics) {
    if (_isUserInteracting ||
        currentIndex == _lastAutoScrollIndex ||
        !_scrollController.isAttached) {
      return;
    }

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

  Widget _buildLyricsList(
    List<LyricLine> lyrics,
    int currentIndex,
    ColorScheme cs,
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
          padding: const EdgeInsets.symmetric(vertical: 180), // 适当减小
          itemCount: lyrics.length,
          itemBuilder: (context, index) =>
              _buildLyricItem(lyrics[index], index, currentIndex, cs),
        ),
      ),
    );
  }

  Widget _buildLyricItem(
    LyricLine item,
    int index,
    int currentIndex,
    ColorScheme cs,
  ) {
    final isTextEmpty = item.text.trim().isEmpty;
    final isActive = _isUserInteracting
        ? (index == _focusedIndex)
        : (index == currentIndex);
    final isNear = _isUserInteracting
        ? (index - _focusedIndex).abs() == 1
        : (index - currentIndex).abs() == 1;

    TextStyle style = isActive
        ? TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: cs.primary,
            height: 1.45,
          )
        : isNear
        ? TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w500,
            color: cs.onSurface.withValues(alpha: 0.75),
            height: 1.45,
          )
        : TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: cs.onSurfaceVariant.withValues(alpha: 0.85),
            height: 1.45,
          );

    if (isTextEmpty && !isActive) {
      style = style.copyWith(
        color: style.color?.withValues(alpha: 0.3),
        fontWeight: FontWeight.w300,
      );
    }

    return InkWell(
      onTap: () => context.read<MusicProvider>().player.seek(
        Duration(milliseconds: item.timeMs),
      ),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          style: style,
          child: Text(
            isTextEmpty ? '~' : item.text,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildCenterInteractionBar(List<LyricLine> lyrics, ColorScheme cs) {
    final focusedLyric = lyrics[_focusedIndex];

    return IgnorePointer(
      ignoring: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              // 播放按钮
              GestureDetector(
                onTap: () {
                  context.read<MusicProvider>().player.seek(
                    Duration(milliseconds: focusedLyric.timeMs),
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

              // 分割线
              Expanded(
                child: Divider(
                  color: cs.primary.withValues(alpha: 0.35),
                  thickness: 1.5,
                ),
              ),
              const SizedBox(width: 12),

              // 时间
              Text(
                _formatTime(focusedLyric.timeMs),
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
