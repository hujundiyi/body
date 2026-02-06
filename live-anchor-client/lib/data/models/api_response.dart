import 'package:json_annotation/json_annotation.dart';

part 'api_response.g.dart';

/// API响应模型
@JsonSerializable(genericArgumentFactories: true)
class ApiResponse<T> {
  final int code;
  final String message;
  final T? data;
  final bool success;
  
  const ApiResponse({
    required this.code,
    required this.message,
    this.data,
    required this.success,
  });
  
  /// 从JSON创建API响应模型
  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) => _$ApiResponseFromJson(json, fromJsonT);
  
  /// 转换为JSON
  Map<String, dynamic> toJson(Object Function(T value) toJsonT) => 
      _$ApiResponseToJson(this, toJsonT);
  
  /// 创建成功响应
  factory ApiResponse.success({
    required T data,
    String message = 'Success',
  }) {
    return ApiResponse<T>(
      code: 200,
      message: message,
      data: data,
      success: true,
    );
  }
  
  /// 创建失败响应
  factory ApiResponse.error({
    required String message,
    int code = 500,
  }) {
    return ApiResponse<T>(
      code: code,
      message: message,
      data: null,
      success: false,
    );
  }
  
  @override
  String toString() {
    return 'ApiResponse(code: $code, message: $message, data: $data, success: $success)';
  }
}
