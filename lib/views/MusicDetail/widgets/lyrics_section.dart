// ─── 歌词区域 ─────────────────────────────────────────────────────────────────

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
  int _lastAutoScrollIndex = -1;
  List<LyricLine> _prevLyrics = [];

  @override
  bool get wantKeepAlive => true;

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

        if (currentIndex != _lastAutoScrollIndex &&
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
            ScrollablePositionedList.builder(
              itemScrollController: _scrollController,
              itemCount: lyrics.length,
              padding: const EdgeInsets.symmetric(vertical: 80),
              itemBuilder: (context, index) {
                final item = lyrics[index];
                final isActive = index == currentIndex;
                final isNear = (index - currentIndex).abs() == 1;

                final style = isActive
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

                return InkWell(
                  onTap: () => context.read<MusicProvider>().player.seek(
                    // item['time'] as Duration,
                    Duration(milliseconds: item.timeMs),
                  ),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 24,
                    ),
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      style: style,
                      child: Text(
                        item.text.isEmpty ? '\u00a0' : item.text,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                );
              },
            ),
            fadeGradient(Alignment.topCenter),
            fadeGradient(Alignment.bottomCenter),
          ],
        );
      },
    );
  }
}
