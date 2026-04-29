import 'dart:io';
import 'dart:typed_data';

// import 'package:audiotags/audiotags.dart';
import 'package:metadata_god/metadata_god.dart';
import 'package:mime/mime.dart';
import 'package:myapp/model/Music/index.dart';
import 'package:on_audio_query_forked/on_audio_query.dart';

import 'package:path/path.dart' as p; // 推荐使用 path 库处理后缀

import 'package:flutter/foundation.dart' show kIsWeb;

class ScanProgress {
  final String currentPath; //正在处理的路径
  final MusicInfo? music; //如果解析了音乐,则返回对象

  ScanProgress({required this.currentPath, this.music});
}

class MusicService {
  static final OnAudioQuery _audioQuery = OnAudioQuery();

  static Future<bool> requestPermission() async {
    if (kIsWeb) return true;
    if (!await _audioQuery.permissionsRequest()) {
      return await _audioQuery.permissionsRequest();
    }
    return true;
  }

  static Future<List<MusicInfo>> getAllAndroidSongs() async {
    final List<SongModel> songs = await _audioQuery.querySongs(
      sortType: SongSortType.DISPLAY_NAME,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
    );

    return songs
        .map(
          (song) => MusicInfo(
            id: song.id.toString(),
            title: song.title,
            artist: song.artist ?? "未知歌手",
            album: song.album ?? "未知专辑",
            duration: Duration(milliseconds: song.duration ?? 0),
            coverBytes: null,
            lyrics: '',
            // coverBytes: 可以后面用 queryArtwork 单独获取
          ),
        )
        .toList();
  }

  static Future<MusicInfo> getSongById(String id) async {
    //模拟本地延迟
    await Future.delayed(const Duration(milliseconds: 500));

    return MusicInfo(
      id: '',
      title: '千本桜',
      artist: '黒うさP / 初音ミク',
      album: 'ALL THAT 千本桜',
      duration: const Duration(seconds: 245),
      coverBytes: null, // 实际开发中通过文件读取或网络获取
      lyrics:
          "[00:00.00]千本桜 夜ニ紛レ\n[00:05.00]君ノ声モ届カナイヨ\n[00:10.00]此処は宴 鋼の檻\n[00:15.00]その断頭台で見下ろして",
    );
  }

  // 增加初始化标志，避免重复初始化
  static bool _isMetadataInitialized = false;

  static Future<void> _ensureInitialized() async {
    if (!_isMetadataInitialized) {
      await MetadataGod.initialize();
      _isMetadataInitialized = true;
    }
  }

  static Future<MusicInfo> parse(String path) async {
    await _ensureInitialized();
    // final Tag? tag = await AudioTags.read(path);
    final metadata = await MetadataGod.readMetadata(file: path);

    final title = metadata.title ?? p.basename(path);
    final artist = metadata.artist ?? "未知歌手";
    final album = metadata.album ?? "未知专辑";
    final duration = metadata.duration ?? Duration.zero;
    final Uint8List? coverBytes = metadata.picture?.data;

    // 2. 手动寻找并读取外部 .lrc 文件
    String lyrics = "";
    final baseName = p.withoutExtension(path);
    final lrcPath = "$baseName.lrc.txt";
    final file = File(lrcPath);

    if (await file.exists()) {
      lyrics = await file.readAsString();
    }

    return MusicInfo(
      id: path,
      title: title,
      artist: artist,
      album: album,
      duration: duration,
      coverBytes: coverBytes,
      lyrics: lyrics,
    );
  }

  static Future<List<FileSystemEntity>> scanDirectory(
    String selectedDirectory,
  ) async {
    // 遍历文件夹
    final dir = Directory(selectedDirectory);

    try {
      List<FileSystemEntity> entities = dir.listSync(recursive: true);

      final List<File> musicFiles = entities.whereType<File>().where((file) {
        final mimeType = lookupMimeType(file.path);
        return mimeType != null && mimeType.startsWith("audio/");
      }).toList();
      return musicFiles;
    } catch (e) {
      return [];
    }
  }

  static Stream<ScanProgress> scanDirectories(
    List<String> selectedDirectories,
  ) async* {
    if (kIsWeb) return;
    for (final directoryPath in selectedDirectories) {
      final dir = Directory(directoryPath);

      await for (final entity in dir.list(
        recursive: true,
        followLinks: false,
      )) {
        yield ScanProgress(currentPath: entity.path);
        if (entity is File) {
          final mimeType = lookupMimeType(entity.path);
          if (mimeType != null && mimeType.startsWith("audio/")) {
            try {
              final music = await parse(entity.path);

              //汇报解析成功的音乐数据
              yield ScanProgress(currentPath: entity.path, music: music);
            } catch (e) {
              continue;
            }
          }
        }
      }
    }
  }
}
