import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:myapp/api/Model/NeteaseSong/index.dart';
import 'package:myapp/api/Model/NeteasePlaylist/index.dart';
import 'package:myapp/providers/UserProvider/index.dart';

class NeteaseApi {
  // 注入 Cookie 的回调函数（可以设为全局赋值，例如在 main.dart 中初始化）
  static String Function()? getCookieHandler;

  static final Dio _dio =
      Dio(
          BaseOptions(
            baseUrl: dotenv.get(
              "JS_BACKEND_URL",
              fallback: 'http://localhost:3000',
            ),
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
          ),
        )
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              // 核心点：每次发起请求前自动把本地保存的 Cookie 注入 Header
              final cookie = getCookieHandler?.call() ?? '';
              if (cookie.isNotEmpty) {
                options.headers['cookie'] = cookie;
              }
              return handler.next(options);
            },
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

  /// 1. 获取二维码 key
  static Future<String?> getQrKey() async {
    try {
      final response = await _dio.get('/api/login/qr/key');
      if (response.statusCode == 200 && response.data['code'] == 200) {
        return response.data['data']?['unikey'] as String?;
      }
      return null;
    } catch (e) {
      debugPrint('获取 QR Key 失败: $e');
      return null;
    }
  }

  /// 2. 获取二维码图片 Base64
  static Future<String?> getQrImage(String key) async {
    try {
      final response = await _dio.get(
        '/api/login/qr/create',
        queryParameters: {'key': key},
      );
      if (response.statusCode == 200 && response.data['code'] == 200) {
        return response.data['data']?['qrimg'] as String?;
      }
      return null;
    } catch (e) {
      debugPrint('生成 QR 二维码失败: $e');
      return null;
    }
  }

  /// 3. 检查二维码扫描状态
  static Future<Map<String, dynamic>> checkQrStatus(String key) async {
    try {
      final response = await _dio.get(
        '/api/login/qr/check',
        queryParameters: {'key': key},
      );

      final data = response.data;
      final code = data['code'];

      // 核心修正：规范提取跨域/Set-Cookie 里的登录凭证
      List<String>? setCookies = response.headers['set-cookie'];
      String cookie = '';

      if (setCookies != null && setCookies.isNotEmpty) {
        // 提取 key=value 部分，过滤 Path/Expires 等多余指令
        cookie = setCookies
            .map((c) => c.split(';').first)
            .where((c) => c.isNotEmpty)
            .join('; ');
      } else if (data['cookie'] != null) {
        cookie = data['cookie'].toString();
      }

      return {
        'code': code,
        'nickname': data['nickname'],
        'cookie': cookie, // 必须确认此 cookie 包含 MUSIC_U=xxx
      };
    } catch (e) {
      debugPrint('轮询二维码状态异常: $e');
      return {'code': -1};
    }
  }

  /// 修改点 1：适配后端的 /api/url (支持携带 Cookie 以及音质 level 参数)
  static Future<String?> getRealUrl(
    String id, {
    String level = 'exhigh', // 支持设置音质: standard, higher, exhigh, lossy等
    String? cookie,
  }) async {
    debugPrint('当前注入的 Cookie: ${getCookieHandler?.call()}');
    debugPrint('请求参数: id=$id, level=$level');
    try {
      final options = Options();
      // 如果调用时手动传了 cookie，优先使用；否则由 Interceptor 自动注入
      if (cookie != null && cookie.isNotEmpty) {
        options.headers = {'cookie': cookie};
      }

      final response = await _dio.get(
        '/api/url',
        queryParameters: {'id': id, 'level': level},
        options: options,
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

  /// Download cover image from URL
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

  /// Check if a URL is accessible
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

  // /// Filter out songs with inaccessible URLs.
  // static Future<List<NeteaseSong>> filterAccessible(
  //   List<NeteaseSong> songs,
  // ) async {
  //   if (songs.isEmpty) return [];

  //   final results = <NeteaseSong>[];
  //   final chunkSize = 5;
  //   for (int i = 0; i < songs.length; i += chunkSize) {
  //     final end = (i + chunkSize).clamp(0, songs.length);
  //     final chunk = songs.sublist(i, end);
  //     final futures = chunk.map((song) async {
  //       if (song.url.isEmpty) return null;
  //       final realUrl = await getRealUrl(song.id);
  //       if (realUrl != null && realUrl.isNotEmpty) {
  //         return NeteaseSong(
  //           id: song.id,
  //           title: song.title,
  //           author: song.author,
  //           pic: song.pic,
  //           url: realUrl,
  //           source: song.source,
  //         );
  //       }
  //       return null;
  //     });
  //     final batchResults = await Future.wait(futures);
  //     results.addAll(batchResults.whereType<NeteaseSong>());
  //   }
  //   return results;
  // }

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

  /// Search playlists
  static Future<List<NeteasePlaylistItem>> searchPlaylists(
    String keyword,
  ) async {
    if (keyword.trim().isEmpty) return [];

    final response = await _dio.get(
      '/api/search',
      queryParameters: {'keyword': keyword, 'type': 1000, 'limit': 50},
    );

    if (response.statusCode == 200 && response.data['code'] == 200) {
      final List<dynamic> data = response.data['data'] ?? [];
      return data
          .map(
            (item) =>
                NeteasePlaylistItem.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    }
    throw Exception('歌单搜索失败: ${response.statusMessage}');
  }

  /// Fetch playlist detail
  static Future<NeteasePlaylistDetail> getPlaylistDetail(String id) async {
    final response = await _dio.get(
      '/api/playlist',
      queryParameters: {'id': id},
    );

    if (response.statusCode == 200 && response.data['code'] == 200) {
      final List<dynamic> data = response.data['data'] ?? [];
      final baseUrl = dotenv.get(
        "JS_BACKEND_URL",
        fallback: 'http://localhost:3000',
      );
      final songs = data.map((item) {
        final map = item as Map<String, dynamic>;
        String rawUrl = map['url'] as String? ?? '';
        if (rawUrl.startsWith('/')) {
          rawUrl = '$baseUrl$rawUrl';
        }
        return NeteasePlaylistSong(
          id: map['id'] as String? ?? '',
          title: map['title'] as String? ?? '未知歌名',
          author: map['author'] as String? ?? '未知歌手',
          pic: (map['pic'] as String? ?? '').replaceFirst(
            'http://',
            'https://',
          ),
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
