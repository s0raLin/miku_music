import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class HttpUtils {
  static String _baseUrl = "http://localhost:8080";

  static final HttpUtils _instance = HttpUtils._internal();
  late final Dio _dio;

  /// 全局 JWT Token，登录后设置，登出时清除
  static String? _authToken;

  /// 设置认证 Token（登录/注册成功后调用）
  static void setAuthToken(String token) {
    _authToken = token;
  }

  /// 清除认证 Token（登出/注销时调用）
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

    // 3. 添加拦截器
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // 统一添加 JWT Token
          if (_authToken != null && _authToken!.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $_authToken';
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          // 对响应数据做统一处理
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          // 集中式错误处理
          _handleError(e);
          return handler.next(e);
        },
      ),
    );

    // 如果是调试模式，打印日志
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(requestBody: true, responseBody: true),
      );
    }
  }

  // 4. 封装常用请求方法
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    return await _dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(String path, {dynamic data}) async {
    return await _dio.post(path, data: data);
  }

  // 专门用于表单/文件上传
  Future<Response> postForm(
    String path, {
    // Map<String, dynamic> data,
    required FormData formData,
    ProgressCallback? onSendProgress,
  }) async {
    // 自动转换 Map 为 FormData
    // final formData = FormData.fromMap(data);
    return await _dio.post(
      path,
      data: formData,
      onSendProgress: onSendProgress, // 方便外面显示上传百分比
    );
  }

  /// 从 DioException 中提取后端返回的错误消息
  /// 优先读取 response body 中的 msg 字段，fallback 到 e.message
  static String extractErrorMessage(DioException e) {
    if (e.response?.data is Map) {
      final data = e.response!.data as Map;
      if (data.containsKey('msg') && data['msg'] != null) {
        return data['msg'].toString();
      }
    }
    return e.message ?? '网络请求失败';
  }

  // 错误处理逻辑
  void _handleError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        debugPrint("连接超时");
        break;
      case DioExceptionType.badResponse:
        debugPrint("服务器响应错误: ${e.response?.statusCode}");
        break;
      default:
        debugPrint("未知网络错误: ${e.message}");
    }
  }
}
