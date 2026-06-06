import 'package:flutter_dotenv/flutter_dotenv.dart';

class Config {
  // 1. 私有构造函数，防止外部直接实例化
  Config._privateConstructor();

  // 2. 内部唯一的实例
  static final Config _instance = Config._privateConstructor();

  // 3. 工厂构造函数，返回唯一实例
  factory Config() {
    return _instance;
  }

  // 使用 getter 确保每次读取时 dotenv 已经就绪
  String get baseUrl =>
      dotenv.get("GO_BACKEND_URL", fallback: "http://localhost:8000");
}

// 使用方式：
// final url = Config().baseUrl;
