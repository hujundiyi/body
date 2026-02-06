import 'package:flutter/material.dart';

/// Say Hi 消息模型
/// 对应 /anchorWork/getSayHiMessage 响应
class SayHiMessage {
  final int? id;
  final String? image;          // 图片URL
  final String? content;        // 文案内容（注意：Swagger中是content，不是text）
  final int? auditStatus;      // 审核状态，字典：audit_status
  final String? auditReason;   // 审核原因
  final bool? isDefault;        // 是否默认

  SayHiMessage({
    this.id,
    this.image,
    this.content,
    this.auditStatus,
    this.auditReason,
    this.isDefault,
  });

  factory SayHiMessage.fromJson(Map<String, dynamic> json) {
    return SayHiMessage(
      id: json['id'] as int?,
      image: json['image'] as String?,
      content: json['content'] as String?,
      auditStatus: json['auditStatus'] as int?,
      auditReason: json['auditReason'] as String?,
      isDefault: json['isDefault'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'image': image,
      'content': content,
      'auditStatus': auditStatus,
      'auditReason': auditReason,
      'isDefault': isDefault,
    };
  }

  /// 获取状态文本
  String get statusText {
    switch (auditStatus) {
      case 0:
        return 'Approved';
      case 1:
        return 'Not submitted';
      case 2:
        return 'In review';
      case 3:
        return 'Review failed';
      default:
        return 'Unknown';
    }
  }

  /// 获取状态图标
  IconData get statusIcon {
    switch (auditStatus) {
      case 0:
        return Icons.check_circle; // 已通过 - 绿色勾选
      case 1:
        return Icons.info_outline; // 未提交 - 信息图标
      case 2:
        return Icons.access_time; // 审核中 - 时钟图标
      case 3:
        return Icons.cancel; // 审核失败 - 取消图标
      default:
        return Icons.help_outline; // 未知 - 帮助图标
    }
  }

  /// 获取状态颜色
  Color get statusColor {
    switch (auditStatus) {
      case 0:
        return const Color(0xFF4CAF50); // 已通过 - 绿色
      case 1:
        return Colors.grey; // 未提交 - 灰色
      case 2:
        return Colors.orange; // 审核中 - 橙色
      case 3:
        return const Color(0xFFE53935); // 审核失败 - 红色
      default:
        return Colors.grey; // 未知 - 灰色
    }
  }

  /// 是否在审核中
  bool get isUnderReview => auditStatus == 2;

  /// 用于界面预览的四种状态示例（仅展示样式，不参与删除等操作）
  static List<SayHiMessage> get previewStatusItems => [
    SayHiMessage(
      id: null,
      content: 'Preview: Approved',
      auditStatus: 0,
    ),
    SayHiMessage(
      id: null,
      content: 'Preview: Not submitted',
      auditStatus: 1,
    ),
    SayHiMessage(
      id: null,
      content: 'Preview: In review',
      auditStatus: 2,
    ),
    SayHiMessage(
      id: null,
      content: 'Preview: Review failed',
      auditStatus: 3,
    ),
  ];
}

/// 添加Say Hi消息请求模型
/// 对应 /anchorWork/addSayHiMessage 请求
class AddSayHiMessageRequest {
  final int? id;         // 消息id（新增传null，修改传id）
  final String image;    // 图片URL（必需）
  final String content;  // 文案内容（必需，注意：Swagger中是content，不是text）
  final int? type;      // 素材类型，字典:anchor_src_type（可选，0普通的，1性感的）

  AddSayHiMessageRequest({
    this.id,
    required this.image,
    required this.content,
    this.type,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'image': image,
      'content': content,
    };
    if (id != null) {
      json['id'] = id;
    }
    if (type != null) {
      json['type'] = type;
    }
    return json;
  }
}

/// 删除Say Hi消息请求模型
/// 对应 /anchorWork/delSayHiMessage 请求
class DelSayHiMessageRequest {
  final int id;  // 消息id（必需）

  DelSayHiMessageRequest({
    required this.id,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
    };
  }
}

/// 设置 Say Hi 消息为默认请求模型
/// 对应 /anchorWork/setSayHiMessageDefault 请求
class SetSayHiMessageDefaultRequest {
  final int id;  // 消息id（必需）

  SetSayHiMessageDefaultRequest({
    required this.id,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
    };
  }
}
