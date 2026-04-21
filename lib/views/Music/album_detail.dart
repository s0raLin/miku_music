import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/model/Music/index.dart';
import 'package:myapp/providers/MusicProvider/index.dart';
import 'package:provider/provider.dart';

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
    final musicProvider = context.read<MusicProvider>();
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
            return MusicListItem(
              id: music.id,
              title: music.title,
              artist: music.artist,
              duration: music.duration,
              coverBytes: music.coverBytes,
              onTap: () {
                if (musicProvider.currentMusic?.id != music.id) {
                  musicProvider.replaceQueue(songs, startIndex: index);
                }
                context.push("/music-detail", extra: music);
              },
            );
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
                        ? Image.memory(coverBytes!, fit: BoxFit.cover)
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
