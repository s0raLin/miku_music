import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:myapp/components/Shared/index.dart';
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
