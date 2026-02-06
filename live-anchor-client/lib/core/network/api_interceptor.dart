import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;
import 'api_client.dart';

/// API 日志拦截器
/// 对应 Swift 版本的 BHIAPILoggingPlugin
class APILoggingInterceptor extends Interceptor {
  /// 输出日志（确保在 iOS 上也能显示）
  void _log(String message) {
    if (kDebugMode) {
      // 同时使用 debugPrint 和 print，确保在 Android Studio 中也能看到
      debugPrint(message);
      print(message); // iOS 上 print 更可靠
      // 也使用 developer.log 确保日志被记录
      developer.log(message, name: 'API');
    }
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!kDebugMode) {
      handler.next(options);
      return;
    }
    
    _log('');
    _log('┌${'─' * 60}');
    _log('│ 📤 API Request');
    _log('├${'─' * 60}');
    _log('│ ${options.method} ${options.uri}');
    
    // 打印请求头（重要信息）
    if (options.headers.isNotEmpty) {
      _log('│ Headers:');
      options.headers.forEach((key, value) {
        // 隐藏敏感信息
        if (key.toLowerCase().contains('authorization') || 
            key.toLowerCase().contains('token')) {
          _log('│   $key: ${value.toString().substring(0, value.toString().length > 20 ? 20 : value.toString().length)}...');
        } else {
          _log('│   $key: $value');
        }
      });
    }

    // 解密请求体用于日志
    if (options.data is String) {
      final decrypted = APIClient.shared.decryptResponse(options.data);
      _log('│ Body:');
      _logJson(decrypted, tag: 'REQ');
    } else if (options.data != null) {
      _log('│ Body:');
      _logJson(options.data, tag: 'REQ');
    }
    _log('└${'─' * 60}');

    handler.next(options);
  }
  
  /// 输出 JSON 日志
  void _logJson(dynamic data, {String? tag}) {
    try {
      String jsonStr;
      if (data is String) {
        final decoded = json.decode(data);
        jsonStr = const JsonEncoder.withIndent('  ').convert(decoded);
      } else {
        jsonStr = const JsonEncoder.withIndent('  ').convert(data);
      }
      // 分段输出，避免被截断
      final lines = jsonStr.split('\n');
      for (final line in lines) {
        _log('│   $line');
      }
    } catch (e) {
      _log('│   ${data.toString()}');
    }
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (!kDebugMode) {
      handler.next(response);
      return;
    }
    
    final url = response.requestOptions.uri.toString();
    final method = response.requestOptions.method;

    _log('');
    _log('┌${'─' * 60}');
    _log('│ 📥 API Response');
    _log('├${'─' * 60}');
    _log('│ $method $url');
    _log('│ Status: ${response.statusCode}');

    final decrypted = APIClient.shared.decryptResponse(response.data);
    if (decrypted != null) {
      final code = decrypted['code'] ?? -1;
      final msg = decrypted['msg'] ?? '';
      _log('│ Code: $code');
      _log('│ Msg: $msg');
      _log('│ Data:');
      _logJson(decrypted['data'], tag: 'RSP');
    } else {
      _log('│ Raw:');
      final rawData = response.data.toString();
      if (rawData.length > 500) {
        _log('│   ${rawData.substring(0, 500)}...');
      } else {
        _log('│   $rawData');
      }
    }
    _log('└${'─' * 60}');

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final url = err.requestOptions.uri.toString();
    final method = err.requestOptions.method;

    _log('');
    _log('┌${'─' * 60}');
    _log('│ ❌ API Error');
    _log('├${'─' * 60}');
    _log('│ $method $url');
    _log('│ Error: ${err.message}');
    _log('│ Type: ${err.type}');
    if (err.response != null) {
      _log('│ Status: ${err.response?.statusCode}');
      _log('│ Data:');
      final errorData = err.response?.data?.toString() ?? '';
      if (errorData.length > 500) {
        _log('│   ${errorData.substring(0, 500)}...');
      } else {
        _log('│   $errorData');
      }
    }
    _log('└${'─' * 60}');

    handler.next(err);
  }
}

/// 认证拦截器
class AuthInterceptor extends Interceptor {
  final Function()? onUnauthorized;

  AuthInterceptor({this.onUnauthorized});

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // 未授权，执行回调
      onUnauthorized?.call();
    }
    handler.next(err);
  }
}

/// 重试拦截器
class RetryInterceptor extends Interceptor {
  final Dio dio;
  final int maxRetries;

  RetryInterceptor({
    required this.dio,
    this.maxRetries = 3,
  });

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;

    // 获取当前重试次数
    int retryCount = options.extra['retryCount'] ?? 0;

    // 判断是否需要重试
    if (_shouldRetry(err) && retryCount < maxRetries) {
      retryCount++;
      options.extra['retryCount'] = retryCount;

      print('API 重试第 $retryCount 次: ${options.uri}');

      // 延迟重试
      await Future.delayed(Duration(seconds: retryCount));

      try {
        final response = await dio.fetch(options);
        handler.resolve(response);
        return;
      } catch (e) {
        // 重试失败，继续传递错误
      }
    }

    handler.next(err);
  }

  /// 判断是否应该重试
  bool _shouldRetry(DioException err) {
    return err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError;
  }
}
