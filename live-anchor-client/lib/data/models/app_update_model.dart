/// init/getAppUpdate 接口返回的 data 结构
class AppUpdateModel {
  final int? id;
  final String? updateTitle;
  final bool? isForce;
  final num? fileSize;
  final String? fileUrl;
  final String? content;

  AppUpdateModel({this.id, this.updateTitle, this.isForce, this.fileSize, this.fileUrl, this.content});

  factory AppUpdateModel.fromJson(Map<String, dynamic> json) {
    return AppUpdateModel(
      id: json['id'] as int?,
      updateTitle: json['updateTitle'] as String?,
      isForce: json['isForce'] as bool?,
      fileSize: json['fileSize'] as num?,
      fileUrl: json['fileUrl'] as String?,
      content: json['content'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'updateTitle': updateTitle,
      'isForce': isForce,
      'fileSize': fileSize,
      'fileUrl': fileUrl,
      'content': content,
    };
  }
}
