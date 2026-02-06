import 'package:dio/dio.dart';

/// API 异常
class APIException implements Exception {
  final int code;
  final String message;

  APIException(this.code, this.message);

  @override
  String toString() => 'APIException(code: $code, message: $message)';

  /// 从 Dio 错误创建 API 异常
  factory APIException.fromDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return APIException(-1, 'Connection timeout. Please check your network.');
      case DioExceptionType.sendTimeout:
        return APIException(-1, 'Send timeout. Please try again.');
      case DioExceptionType.receiveTimeout:
        return APIException(-1, 'Receive timeout. Please try again.');
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode ?? -1;
        switch (statusCode) {
          case 400:
            return APIException(400, 'Invalid request parameters');
          case 401:
            return APIException(401, 'Unauthorized. Please log in again.');
          case 403:
            return APIException(403, 'Access denied');
          case 404:
            return APIException(404, 'The requested resource was not found.');
          case 500:
            return APIException(500, 'Internal server error');
          default:
            return APIException(statusCode, 'Request failed: $statusCode');
        }
      case DioExceptionType.cancel:
        return APIException(-1, 'Request cancelled');
      case DioExceptionType.connectionError:
        return APIException(-1, 'Network connection error');
      case DioExceptionType.badCertificate:
        return APIException(-1, 'Certificate verification failed');
      case DioExceptionType.unknown:
      default:
        return APIException(-1, 'Unknown error: ${error.message}');
    }
  }
}

/// 网络错误类型
enum NetworkErrorType {
  /// 连接超时
  connectionTimeout,

  /// 发送超时
  sendTimeout,

  /// 接收超时
  receiveTimeout,

  /// 请求取消
  cancel,

  /// 网络连接错误
  connectionError,

  /// 证书错误
  badCertificate,

  /// 服务器响应错误
  badResponse,

  /// 未知错误
  unknown,
}
