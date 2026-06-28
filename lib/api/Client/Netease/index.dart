
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:myapp/api/Model/NeteaseSong/index.dart';
import 'package:myapp/api/Model/NeteasePlaylist/index.dart';

class NeteaseApi {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: dotenv.get("JS_BACKEND_URL", fallback: 'http://localhost:3000'),
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  /// Search songs from Netease Cloud Music via local proxy server
  static Future<List<NeteaseSong>> search(String keyword) async {
    if (keyword.trim().isEmpty) return [];

    final response = await _dio.get(
      '/api/search',
      queryParameters: {'keyword': keyword, 'limit': 50},
    );

    if (response.statusCode == 200 && response.data['code'] == 200) {
      final List<dynamic> data = response.data['data'] ?? [];
      return data.map((item) {
        final song = NeteaseSong.fromJson(item);
        // Fix: convert http:// to https:// for Netease CDN images (avoids 403)
        final fixedPic = song.pic.replaceFirst('http://', 'https://');
        return NeteaseSong(
          id: song.id,
          title: song.title,
          author: song.author,
          pic: fixedPic,
          url: song.url,
          source: song.source,
        );
      }).toList();
    }
    throw Exception('搜索失败: ${response.statusMessage}');
  }

  /// Get the real playable URL for a song.
  /// The static URL from search results may be invalid for direct access.
  static Future<String?> getRealUrl(
    String id, {
    String source = 'netease',
  }) async {
    try {
      final response = await _dio.get(
        '/api/url',
        queryParameters: {'id': id, 'source': source},
      );

      if (response.statusCode == 200 && response.data['code'] == 200) {
        return response.data['url'] as String?;
      }
      return null;
    } catch (e) {
      debugPrint('获取真实URL失败 [$id]: $e');
      return null;
    }
  }

  /// Get lyrics for a song
  static Future<Map<String, String?>> getLyric(
    String id, {
    String source = 'netease',
  }) async {
    try {
      final response = await _dio.get(
        '/api/lyric',
        queryParameters: {'id': id, 'source': source},
      );

      if (response.statusCode == 200 && response.data['code'] == 200) {
        return {
          'lyric': response.data['lyric'] as String?,
          'tlyric': response.data['tlyric'] as String?,
        };
      }
      return {'lyric': null, 'tlyric': null};
    } catch (e) {
      debugPrint('获取歌词失败 [$id]: $e');
      return {'lyric': null, 'tlyric': null};
    }
  }

  /// Download cover image from URL to the specified path.
  /// Returns the save path on success, null on failure.
  static Future<String?> downloadCover(
    String coverUrl,
    String savePath, {
    void Function(int received, int total)? onProgress,
  }) async {
    try {
      await Dio().download(
        coverUrl,
        savePath,
        onReceiveProgress: onProgress,
        options: Options(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(minutes: 5),
          // ─── 核心修复：注入防盗链请求头 ───
          headers: {
            'Referer': 'https://music.163.com/',
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          },
        ),
      );
      return savePath;
    } catch (e) {
      debugPrint('下载封面失败: $e');
      return null;
    }
  }

  /// Check if a URL is accessible by sending a HEAD request
  static Future<bool> isUrlAccessible(String url) async {
    try {
      final response = await Dio().head(
        url,
        options: Options(
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
          followRedirects: true,
        ),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Filter out songs with inaccessible URLs.
  /// Returns only songs whose URLs respond with 200.
  static Future<List<NeteaseSong>> filterAccessible(
    List<NeteaseSong> songs,
  ) async {
    if (songs.isEmpty) return [];

    final results = <NeteaseSong>[];
    // Check in parallel batches to avoid overwhelming the network
    final chunkSize = 5;
    for (int i = 0; i < songs.length; i += chunkSize) {
      final end = (i + chunkSize).clamp(0, songs.length);
      final chunk = songs.sublist(i, end);
      final futures = chunk.map((song) async {
        // Skip URLs that are already invalid patterns
        if (song.url.isEmpty) return null;
        // Try to get the real URL first (which validates accessibility)
        final realUrl = await getRealUrl(song.id, source: song.source);
        if (realUrl != null && realUrl.isNotEmpty) {
          return NeteaseSong(
            id: song.id,
            title: song.title,
            author: song.author,
            pic: song.pic,
            url: realUrl,
            source: song.source,
          );
        }
        return null;
      });
      final batchResults = await Future.wait(futures);
      results.addAll(batchResults.whereType<NeteaseSong>());
    }
    return results;
  }

  /// Download a song file to a local path
  static Future<String?> downloadSong(
    String url,
    String savePath, {
    void Function(int received, int total)? onProgress,
  }) async {
    try {
      await Dio().download(
        url,
        savePath,
        onReceiveProgress: onProgress,
        options: Options(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(minutes: 10),
        ),
      );
      return savePath;
    } catch (e) {
      debugPrint('下载失败: $e');
      return null;
    }
  }

  /// Search playlists from Netease Cloud Music via local proxy server
  /// Calls /api/search?keyword=xxx&type=playlist
  static Future<List<NeteasePlaylistItem>> searchPlaylists(
    String keyword,
  ) async {
    if (keyword.trim().isEmpty) return [];

    // 使用独立 Dio 实例，避免与歌曲搜索共用实例时参数互相干扰
    final dio = Dio(BaseOptions(
      baseUrl: dotenv.get("JS_BACKEND_URL", fallback: 'http://localhost:3000'),
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));

    final response = await dio.get(
      '/api/search',
      queryParameters: {'keyword': keyword, 'type': 'playlist', 'limit': 50},
    );

    if (response.statusCode == 200 && response.data['code'] == 200) {
      final List<dynamic> data = response.data['data'] ?? [];
      return data
          .map((item) => NeteasePlaylistItem.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    throw Exception('歌单搜索失败: ${response.statusMessage}');
  }

  /// Fetch playlist detail (song list) by playlist id
  /// Calls /api/playlist?id=xxx
  ///
  /// 注意：后端返回的 url 字段是相对路径（如 /api/url?id=xxx&source=netease），
  /// 这里直接存储 id，播放时再通过 getRealUrl 获取真实可用链接。
  static Future<NeteasePlaylistDetail> getPlaylistDetail(String id) async {
    final response = await _dio.get(
      '/api/playlist',
      queryParameters: {'id': id},
    );

    if (response.statusCode == 200 && response.data['code'] == 200) {
      final List<dynamic> data = response.data['data'] ?? [];
      final baseUrl = dotenv.get("JS_BACKEND_URL", fallback: 'http://localhost:3000');
      final songs = data.map((item) {
        final map = item as Map<String, dynamic>;
        // 修复相对路径 url：拼接 base URL 变成完整可访问地址
        String rawUrl = map['url'] as String? ?? '';
        if (rawUrl.startsWith('/')) {
          rawUrl = '$baseUrl$rawUrl';
        }
        return NeteasePlaylistSong(
          id: map['id'] as String? ?? '',
          title: map['title'] as String? ?? '未知歌名',
          author: map['author'] as String? ?? '未知歌手',
          pic: (map['pic'] as String? ?? '').replaceFirst('http://', 'https://'),
          url: rawUrl,
          source: map['source'] as String? ?? 'netease',
        );
      }).toList();
      return NeteasePlaylistDetail(
        playlistName: response.data['playlistName'] as String? ?? '未知歌单',
        count: (response.data['count'] as num?)?.toInt() ?? songs.length,
        songs: songs,
      );
    }
    throw Exception('获取歌单详情失败: ${response.statusMessage}');
  }
}
