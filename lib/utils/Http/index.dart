import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:myapp/service/LocalAuth/index.dart';

/// HTTP 错误事件类型
enum HttpErrorType {
  unauthorized, // 401 认证失败/过期
  network, // 网络超时/连接断开
  badResponse, // 后端返回非 2xx 状态码
  unknown, // 其他未知错误
}

/// HTTP 错误事件载荷
class HttpErrorEvent {
  final HttpErrorType type;
  final String message;
  final int? statusCode;
  final DioException exception;

  HttpErrorEvent({
    required this.type,
    required this.message,
    this.statusCode,
    required this.exception,
  });
}

class HttpUtils {
  static String _baseUrl = dotenv.get(
    "GO_BACKEND_URL",
    fallback: "http://localhost:8000",
  );

  static final HttpUtils _instance = HttpUtils._internal();
  late final Dio _dio;

  /// 全局 JWT Token
  static String? _authToken;

  /// 刷新锁与并发挂起队列
  bool _isRefreshing = false;
  final List<void Function(String)> _refreshQueue = [];

  /// 全局 HTTP 异常广播流（UI 根节点订阅此流做 Toast 或路由跳转）
  static final StreamController<HttpErrorEvent> _errorEventController =
      StreamController<HttpErrorEvent>.broadcast();

  /// 供外部监听的全局错误事件流
  static Stream<HttpErrorEvent> get errorStream => _errorEventController.stream;

  /// 设置认证 Token
  static void setAuthToken(String token) {
    _authToken = token;
  }

  /// 清除认证 Token
  static void clearAuthToken() {
    _authToken = null;
  }

  void setBaseUrl(String url) {
    _baseUrl = url;
    _dio.options.baseUrl = url;
  }

  String get currentBaseUrl => _dio.options.baseUrl;

  factory HttpUtils() => _instance;

  HttpUtils._internal() {
    BaseOptions options = BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    );

    _dio = Dio(options);

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_authToken != null && _authToken!.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $_authToken';
          }
          return handler.next(options);
        },

        // ─────────────────── 1. 响应拦截器：捕获 HTTP 200 下的业务 401 ───────────────────
        onResponse: (response, handler) async {
          final data = response.data;

          // 如果后端 HTTP 返回 200，但业务 code 提示 Token 无效/过期
          if (data is Map && data['code'] != 0 && data['code'] != 200) {
            final msg = data['msg']?.toString() ?? '';

            if (msg.contains('Token') || msg.contains('令牌')) {
              // 伪造一个 401 状态码的 DioException，强制抛给 onError 统一处理无感刷新
              return handler.reject(
                DioException(
                  requestOptions: response.requestOptions,
                  response: Response(
                    requestOptions: response.requestOptions,
                    statusCode: 401, // 强行置为 401
                    data: data,
                  ),
                  type: DioExceptionType.badResponse,
                  error: msg,
                ),
              );
            }
          }
          return handler.next(response);
        },

        // ─────────────────── HttpUtils.dart 修复片段 ───────────────────
        onError: (DioException e, handler) async {
          final options = e.requestOptions;

          // 1. 拦截 401（排除刷新接口本身）
          if (e.response?.statusCode == 401 &&
              !options.path.contains('/api/auth/refresh')) {
            if (_isRefreshing) {
              _refreshQueue.add((newToken) async {
                // 使用 copyWith 强制写入新的 headers
                final newOptions = options.copyWith(
                  headers: Map<String, dynamic>.from(options.headers)
                    ..['Authorization'] = 'Bearer $newToken',
                );
                try {
                  final response = await _dio.fetch(newOptions);
                  handler.resolve(response);
                } catch (err) {
                  handler.reject(err as DioException);
                }
              });
              return;
            }

            _isRefreshing = true;
            final newAccessToken = await _tryRefreshToken();
            _isRefreshing = false;

            if (newAccessToken != null) {
              // 2. 关键：确保更新了内存中的静态变量！
              setAuthToken(newAccessToken);

              // 执行队列中的挂起请求
              for (var callback in _refreshQueue) {
                callback(newAccessToken);
              }
              _refreshQueue.clear();

              // 3. 关键：构造带有新 Token 的全新 Options 发起重试
              final newOptions = options.copyWith(
                headers: Map<String, dynamic>.from(options.headers)
                  ..['Authorization'] = 'Bearer $newAccessToken',
              );

              try {
                final response = await _dio.fetch(newOptions);
                return handler.resolve(response); // 成功重试，返回数据
              } catch (err) {
                _handleError(e);
                return handler.next(e);
              }
            } else {
              _refreshQueue.clear();
            }
          }

          _handleError(e);
          return handler.next(e);
        },
      ),
    );

    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(requestBody: true, responseBody: true),
      );
    }
  }

  /// 尝试请求后端刷新 Token
  Future<String?> _tryRefreshToken() async {
    try {
      final localAuth = LocalAuth();
      final refreshToken = await localAuth.readRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) return null;

      // 使用独立 Dio 发起请求，正确匹配 Go 后端 /api/auth/refresh 接口
      final response = await Dio().post(
        '$_baseUrl/api/auth/refresh',
        data: {'refresh_token': refreshToken},
      );

      // 解包后端统一响应结构 ApiResponse
      final data = response.data;
      if (response.statusCode == 200 &&
          (data['code'] == 0 || data['code'] == 200)) {
        final resData = data['data'];
        final newAccessToken = resData['access_token'] as String;
        final newRefreshToken = resData['refresh_token'] as String?;

        // 同步更新内存 Token
        setAuthToken(newAccessToken);

        // 持久化更新本地加密存储
        if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
          await localAuth.saveTokens(
            accessToken: newAccessToken,
            refreshToken: newRefreshToken,
          );
        } else {
          await localAuth.saveToken(newAccessToken);
        }

        debugPrint('[HttpUtils] 无感刷新令牌成功');
        return newAccessToken;
      }
    } catch (e) {
      debugPrint('[HttpUtils] 刷新 Token 失败: $e');
    }
    return null;
  }

  // ─────────────────── 常用请求方法 ───────────────────

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    return await _dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(String path, {dynamic data}) async {
    return await _dio.post(path, data: data);
  }

  Future<Response> postForm(
    String path, {
    required FormData formData,
    ProgressCallback? onSendProgress,
  }) async {
    return await _dio.post(
      path,
      data: formData,
      onSendProgress: onSendProgress,
    );
  }

  // ─────────────────── 纯数据逻辑与事件分发 ───────────────────

  /// 从 DioException 中安全提取错误消息
  static String extractErrorMessage(DioException e) {
    if (e.response?.data is Map) {
      final data = e.response!.data as Map;
      if (data['msg'] != null && data['msg'].toString().isNotEmpty) {
        return data['msg'].toString();
      }
      if (data['message'] != null && data['message'].toString().isNotEmpty) {
        return data['message'].toString();
      }
    }

    if (e.message != null && e.message!.isNotEmpty) {
      return e.message!;
    }

    return '服务响应异常，请稍后再试';
  }

  /// 集中式错误判定与 Event 发射（不依赖任何 Context / UI）
  void _handleError(DioException e) {
    final statusCode = e.response?.statusCode;
    final msg = extractErrorMessage(e);

    // 1. 拦截 401 认证失效
    if (statusCode == 401) {
      clearAuthToken();
      _errorEventController.add(
        HttpErrorEvent(
          type: HttpErrorType.unauthorized,
          message: "登录已过期，请重新登录",
          statusCode: 401,
          exception: e,
        ),
      );
      return;
    }

    // 2. 拦截网络连接/超时异常
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      _errorEventController.add(
        HttpErrorEvent(
          type: HttpErrorType.network,
          message: "网络连接超时或无法连接到服务器",
          statusCode: statusCode,
          exception: e,
        ),
      );
      return;
    }

    // 3. 兜底响应异常广播
    _errorEventController.add(
      HttpErrorEvent(
        type: HttpErrorType.badResponse,
        message: msg,
        statusCode: statusCode,
        exception: e,
      ),
    );
  }
}
