import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// 日志工具类
class Logger {
  static const String _tag = 'Weeder';
  static const int _maxLength = 800; // 单条日志最大长度

  /// 调试日志
  static void debug(String message, {String? tag}) {
    developer.log(
      message,
      name: tag ?? _tag,
      level: 500, // DEBUG level
    );
  }

  /// 信息日志
  static void info(String message, {String? tag}) {
    developer.log(
      message,
      name: tag ?? _tag,
      level: 800, // INFO level
    );
  }

  /// 警告日志
  static void warning(String message, {String? tag}) {
    developer.log(
      message,
      name: tag ?? _tag,
      level: 900, // WARNING level
    );
  }

  /// 错误日志
  static void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: tag ?? _tag,
      level: 1000, // ERROR level
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// 网络请求日志
  static void network(String message, {String? tag}) {
    developer.log('🌐 $message', name: tag ?? '${_tag}_Network', level: 800);
  }

  /// 数据库日志
  static void database(String message, {String? tag}) {
    developer.log('💾 $message', name: tag ?? '${_tag}_Database', level: 800);
  }

  /// 用户操作日志
  static void userAction(String message, {String? tag}) {
    developer.log('👤 $message', name: tag ?? '${_tag}_UserAction', level: 800);
  }

  /// ========== 长日志处理（解决截断问题）==========

  /// 打印长文本（自动分段，不会被截断）
  static void printLong(String text, {String? tag}) {
    final prefix = tag != null ? '[$tag] ' : '';

    if (text.length <= _maxLength) {
      debugPrint('$prefix$text');
      return;
    }

    debugPrint('$prefix${'═' * 30} START ${'═' * 30}');

    int start = 0;
    int end = _maxLength;
    int index = 0;

    while (start < text.length) {
      if (end > text.length) end = text.length;
      debugPrint('$prefix[$index] ${text.substring(start, end)}');
      start = end;
      end = start + _maxLength;
      index++;
    }

    debugPrint('$prefix${'═' * 30} END ${'═' * 30}');
  }

  /// 打印 JSON（格式化 + 不截断）
  static void json(dynamic data, {String? tag}) {
    if (!kDebugMode) return;

    try {
      String jsonStr;
      if (data is String) {
        final decoded = jsonDecode(data);
        jsonStr = const JsonEncoder.withIndent('  ').convert(decoded);
      } else {
        jsonStr = const JsonEncoder.withIndent('  ').convert(data);
      }
      printLong(jsonStr, tag: tag ?? 'JSON');
    } catch (e) {
      printLong(data.toString(), tag: tag ?? 'JSON');
    }
  }

  /// 打印 API 响应（完整显示）
  static void api(String path, dynamic response, {bool showRequest = false, dynamic request}) {
    if (!kDebugMode) return;

    debugPrint('\n${'═' * 60}');
    debugPrint('📡 API: $path');
    debugPrint('─' * 60);

    if (showRequest && request != null) {
      debugPrint('📤 Request:');
      json(request, tag: 'REQ');
      debugPrint('─' * 60);
    }

    debugPrint('📥 Response:');
    json(response, tag: 'RSP');
    debugPrint('${'═' * 60}\n');
  }
}
