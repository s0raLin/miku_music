import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

// import 'package:metadata_god/metadata_god.dart';
import 'package:mime/mime.dart';
import 'package:myapp/model/Music/index.dart';
import 'package:myapp/src/rust/api/audio_info.dart';
import 'package:myapp/src/rust/api/scanner.dart';

// import 'package:on_audio_query_forked/on_audio_query.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart'; // 用于 md5

import 'package:path/path.dart' as p; // 推荐使用 path 库处理后缀

import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:permission_handler/permission_handler.dart';

class ScanProgress {
  final String currentPath; //正在处理的路径
  final MusicInfo? music; //如果解析了音乐,则返回对象
  // final int currentIndex; // 新增：当前第几首
  // final int totalCount; // 新增：总共多少首

  ScanProgress({
    required this.currentPath,
    this.music,
    // required this.currentIndex,
    // required this.totalCount,
  });
}

class MusicService {
  static Future<bool> ensureAndroidAudioPermission() async {
    if (!Platform.isAndroid) return true;

    final audioStatus = await Permission.audio.request();
    final storageStatus = await Permission.manageExternalStorage.request();

    return audioStatus.isGranted && storageStatus.isGranted;
  }

  static Future<MusicInfo> parse(String path) async {
    final song = await getAudioInfo(path: path);
    final title = song.title;
    final artist = song.artist;
    final album = song.album;
    final duration = Duration(seconds: song.durationSeconds);
    final coverBytes = song.coverArt;

    debugPrint(
      "封面: ${coverBytes != null ? '${coverBytes.length} bytes' : 'null'} → $path",
    );

    // 2. 手动寻找并读取外部 .lrc 文件
    String lyrics = "";
    final baseName = p.withoutExtension(path);
    final lrcPath = "$baseName.lrc";
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

  static Stream<ScanProgress> scanDirectories(
    List<String> selectedDirectories,
  ) async* {
    if (kIsWeb) return;

    for (final directoryPath in selectedDirectories) {
      // 1. 调用 Rust 的并行扫描，直接获取 Rust 返回的 Stream
      // 注意：FRB 会把 Rust 的 `StreamSink<AudioMetadata>` 自动转换为 Dart 的 `Stream<AudioMetadata>`
      final rustStream = scanDirectoryParallel(dirPath: directoryPath);

      await for (final rustMeta in rustStream) {
        // 2. 收到 Rust 传回的基础元数据，先汇报路径
        yield ScanProgress(currentPath: rustMeta.path);

        try {
          // 3. 补全 Dart 端的业务逻辑：查找外部歌词
          String lyrics = "";
          final baseName = p.withoutExtension(rustMeta.path);
          final lrcFile = File("$baseName.lrc");
          if (await lrcFile.exists()) {
            lyrics = await lrcFile.readAsString();
          }

          // 4. 组装成前端需要的 MusicInfo
          final music = MusicInfo(
            title: rustMeta.path,
            artist: rustMeta.artist,
            album: rustMeta.album,
            duration: Duration(seconds: rustMeta.durationSeconds),
            coverBytes: null,
            lyrics: lyrics,
            id: rustMeta.path,
          );

          yield ScanProgress(currentPath: rustMeta.path, music: music);
        } catch (e, stack) {
          debugPrint("处理数据失败: ${rustMeta.path}, 错误: $e\n$stack");
          continue;
        }
      }
    }
  }

  //保存歌词
  static Future<void> saveLyrics(String? lrcContent, String path) async {
    if (lrcContent == null || lrcContent.isEmpty) return;

    try {
      if (path.startsWith("/") && await File(path).exists()) {
        final lrcPath = path.contains(RegExp(r'\.([^./\\]+)$'))
            ? path.replaceFirstMapped(
                RegExp(r'\.([^./\\]+)$'),
                (match) => '.lrc',
              )
            : '$path.lrc';
        final lrcFile = File(lrcPath);
        await lrcFile.writeAsString(lrcContent);
        debugPrint("歌词已成功保存至: $lrcPath");
      }
    } catch (e) {
      debugPrint("歌词保存本地失败: $e");
    }
  }

  /// 将内存中的二进制封面数据（Uint8List）转换为本地临时文件 Uri
  static Future<Uri?> getAudioServiceCoverFromBytes(
    Uint8List? imageBytes,
    String musicId,
  ) async {
    if (imageBytes == null || imageBytes.isEmpty) return null;

    try {
      final tmpDir = await getTemporaryDirectory();

      // 为防止 musicId 含有特殊字符导致文件名非法，将其转为 MD5 安全文件名
      final safeFileName = md5.convert(utf8.encode(musicId)).toString();
      final file = File("${tmpDir.path}/cover_$safeFileName.jpg");

      if (await file.exists()) {
        return file.uri;
      }
      // 直接将内存中的二进制数据写入磁盘文件
      await file.writeAsBytes(imageBytes);

      debugPrint('🎵 成功将内存封面保存至本地缓存: ${file.path}');
      return file.uri; // 返回标准的 file://... 路径
    } catch (e) {
      debugPrint("转换本地文件失败: $e");
      return null;
    }
  }
}
