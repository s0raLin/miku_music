import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:myapp/model/Music/index.dart';
import 'package:myapp/service/Music/index.dart';
import 'dart:ui' as ui;

class AlbumDetailPage extends StatelessWidget {
  final String albumName;
  final List<MusicInfo> songs;
  const AlbumDetailPage({
    super.key,
    required this.albumName,
    required this.songs,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(albumName)),
      body: ListTileTheme(
        data: ListTileThemeData(
          selectedTileColor: Theme.of(context).colorScheme.secondaryContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: ListView.builder(
          itemCount: songs.length,
          itemBuilder: (context, index) {
            final music = songs[index];
            return ObservableMusicListItem(music: music);
          },
        ),
      ),
    );
  }
}

class MusicListItem extends StatelessWidget {
  const MusicListItem({
    super.key,
    required this.id,
    required this.title,
    required this.artist,
    required this.duration,
    this.coverBytes,
    this.lyrics,
    this.album,
    this.onTap, // 1. 定义点击回调
  });

  final String id;
  final String title;
  final String artist;
  final Duration duration;
  final Uint8List? coverBytes;
  final String? lyrics;
  final String? album;
  final VoidCallback? onTap; // 2. 回调类型

  @override
  Widget build(BuildContext context) {
    // 3. 使用 Material 和 InkWell 以获得水波纹点击效果
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent, // 保持背景透明
      child: InkWell(
        onTap: onTap, // 4. 绑定点击事件
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: SizedBox(
            height: 72,
            child: Row(
              children: <Widget>[
                // 封面
                AspectRatio(
                  aspectRatio: 1.0,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.0),
                      color: colorScheme.surfaceContainerHighest,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: coverBytes != null
                        ? Image(image: MemoryImage(coverBytes!))
                        : Icon(
                            Icons.music_note,
                            color: colorScheme.onSurfaceVariant,
                          ),
                  ),
                ),
                // 信息
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: _MusicDescription(
                      title: title,
                      artist: artist,
                      album: album,
                      duration: duration,
                      colorScheme: colorScheme,
                    ),
                  ),
                ),
                // 尾部图标
                Icon(Icons.more_vert, size: 20, color: colorScheme.outline),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ObservableMusicListItem extends StatefulWidget {
  final MusicInfo music;
  final VoidCallback? onTap;

  const ObservableMusicListItem({super.key, required this.music, this.onTap});

  @override
  State<ObservableMusicListItem> createState() =>
      _ObservableMusicListItemState();
}

class _ObservableMusicListItemState extends State<ObservableMusicListItem> {
  Uint8List? _coverBytes;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    debugPrint('initState: ${widget.music.title}');
    _loadCover();
  }

  // 加这个方法
  Future<Uint8List?> _resizeImage(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(
      bytes,
      targetWidth: 144,
      targetHeight: 144,
    );
    final frame = await codec.getNextFrame();
    final byteData = await frame.image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    frame.image.dispose();
    return byteData?.buffer.asUint8List();
  }

  void _loadCover() async {
    if (widget.music.coverBytes != null &&
        widget.music.coverBytes!.isNotEmpty) {
      // 已有封面也压缩后再用
      final small = await _resizeImage(widget.music.coverBytes!);
      if (!mounted) return;
      setState(() {
        _coverBytes = small;
        widget.music.coverBytes = small; // 回写小图，下次直接用
      });
      return;
    }

    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final updatedMusic = await MusicService.parse(widget.music.id);
      final small = await _resizeImage(updatedMusic.coverBytes!);
      if (mounted) {
        setState(() {
          _coverBytes = small;
          widget.music.coverBytes = small; // 回写小图
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {

    return MusicListItem(
      id: widget.music.id,
      title: widget.music.title,
      artist: widget.music.artist,
      duration: widget.music.duration,
      coverBytes: _coverBytes,
      onTap: widget.onTap,
    );
  }
}

class _MusicDescription extends StatelessWidget {
  const _MusicDescription({
    required this.title,
    required this.artist,
    this.album,
    required this.duration,
    required this.colorScheme,
  });

  final String title;
  final String artist;
  final String? album;
  final Duration duration;
  final ColorScheme colorScheme;

  Widget _durationText(Duration d) => Text(
    '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}',
    style: TextStyle(fontSize: 12.0, color: colorScheme.outline),
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // 标题
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16.0,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4.0),
        // 歌手 & 专辑
        Expanded(
          child: Text(
            '$artist ${album != null ? "· $album" : ""}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13.0,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        // 时长
        _durationText(duration),
      ],
    );
  }
}
