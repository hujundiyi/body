/// 上传响应模型
/// 对应 Swift 版本的 BHIUploadResponse
class UploadResponse {
  final String uploadUrl;
  final String url;
  final String contentType;

  UploadResponse({
    required this.uploadUrl,
    required this.url,
    required this.contentType,
  });

  factory UploadResponse.fromJson(Map<String, dynamic> json) {
    return UploadResponse(
      uploadUrl: json['preUrl'] ?? '',
      url: json['url'] ?? '',
      contentType: json['contentType'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'preUrl': uploadUrl,
      'url': url,
      'contentType': contentType,
    };
  }
}

/// API 响应模型
/// 对应 Swift 版本的 BHIResponse
class ApiResponse<T> {
  final int code;
  final String msg;
  final T? data;

  ApiResponse({
    this.code = 200,
    this.msg = '',
    this.data,
  });

  bool get isSuccess => code == 200;

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic json)? fromJsonT,
  ) {
    return ApiResponse(
      code: json['code'] ?? 200,
      msg: json['msg'] ?? '',
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : json['data'],
    );
  }

  Map<String, dynamic> toJson(Object? Function(T value)? toJsonT) {
    return {
      'code': code,
      'msg': msg,
      'data': data != null && toJsonT != null ? toJsonT(data as T) : data,
    };
  }

  @override
  String toString() {
    return 'ApiResponse(code: $code, msg: $msg, data: $data)';
  }
}

/// 待上传任务模型
class PendingUpload {
  final String imagePath;
  final String uploadUrl;

  PendingUpload({
    required this.imagePath,
    required this.uploadUrl,
  });

  factory PendingUpload.fromJson(Map<String, dynamic> json) {
    return PendingUpload(
      imagePath: json['imagePath'] ?? '',
      uploadUrl: json['uploadUrl'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'imagePath': imagePath,
      'uploadUrl': uploadUrl,
    };
  }
}
