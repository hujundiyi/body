/// 文件上传请求模型
/// 对应 /system/getPutFileUrl 请求，参数：type, fileName, contentLength
class FileUploadRequest {
  final String type; // 业务类型，如 "video"、"picture"、"user"
  final String fileName;
  final int contentLength; // 文件大小（字节）

  FileUploadRequest({required this.type, required this.fileName, required this.contentLength});

  Map<String, dynamic> toJson() {
    return {'type': type, 'fileName': fileName, 'contentLength': contentLength};
  }
}

/// 文件上传响应模型
/// 对应 /system/getPutFileUrl 响应
class FileUploadResponse {
  final String? putUrl; // PUT 上传地址
  final String? getUrl; // GET 访问地址

  FileUploadResponse({this.putUrl, this.getUrl});

  factory FileUploadResponse.fromJson(Map<String, dynamic> json) {
    return FileUploadResponse(putUrl: json['preUrl'] as String?, getUrl: json['url'] as String?);
  }

  Map<String, dynamic> toJson() {
    return {'putUrl': putUrl, 'getUrl': getUrl};
  }
}

/// 批量文件上传请求项
class BatchFileUploadItem {
  final String type; // 业务类型，如 "picture"
  final String fileName; // 文件名
  final int contentLength; // 文件大小（字节）

  BatchFileUploadItem({required this.type, required this.fileName, required this.contentLength});

  Map<String, dynamic> toJson() {
    return {'type': type, 'fileName': fileName, 'contentLength': contentLength};
  }
}

/// 批量文件上传请求模型
/// 对应 /system/getPutFileUrls 请求
/// 参数格式：[{type: "picture", fileName: "string", contentLength: 1}]
class BatchFileUploadRequest {
  final List<BatchFileUploadItem> files;

  BatchFileUploadRequest({required this.files});

  List<Map<String, dynamic>> toJson() {
    return files.map((file) => file.toJson()).toList();
  }
}

/// 批量文件上传响应模型
class BatchFileUploadResponse {
  final List<FileUploadResponse>? files;

  BatchFileUploadResponse({this.files});

  factory BatchFileUploadResponse.fromJson(Map<String, dynamic> json) {
    return BatchFileUploadResponse(
      files: (json['files'] as List<dynamic>?)
          ?.map((e) => FileUploadResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'files': files?.map((e) => e.toJson()).toList()};
  }
}
