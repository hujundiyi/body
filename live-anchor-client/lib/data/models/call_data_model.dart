import 'dart:convert';
import 'package:weeder/core/constants/call_constants.dart';
import 'package:weeder/data/models/anchor_model.dart';
import 'package:weeder/data/models/user_model_entity.dart';

/// 通话数据模型
class CallData {
  /// 通话编号
  final String callNo;
  /// 主叫用户ID
  final int? createUserId;
  /// 被叫用户ID
  final int? toUserId;
  /// 通话价格（每分钟）
  final double? callPrice;
  /// 通话状态
  final CallStatus? callStatus;
  /// 通话类型
  final String? callType;
  /// 创建时间
  final DateTime? createTime;
  /// 音视频类型（TRTC / ARTC）
  final String? rtcType;
  /// TRTC Token（创建者）- 当前APP使用
  final String? createUserSign;
  /// TRTC Token（接受者）- 当前APP使用
  final String? toUserSign;
  /// 主播信息
  final AnchorModel? anchorInfo;
  /// 用户信息
  final UserModelEntity? userInfo;

  CallData({
    required this.callNo,
    this.createUserId,
    this.toUserId,
    this.callPrice,
    this.callStatus,
    this.callType,
    this.createTime,
    this.rtcType,
    this.createUserSign,
    this.toUserSign,
    this.anchorInfo,
    this.userInfo,
  });

  /// 是否使用 TRTC
  bool get isTRTC => rtcType?.toUpperCase() == 'TRTC';

  /// 是否使用 ARTC
  bool get isARTC => rtcType?.toUpperCase() == 'ARTC';

  factory CallData.fromJson(Map<String, dynamic> json) {
    return CallData(
      callNo: json['callNo'] as String? ?? '',
      createUserId: json['createUserId'] as int?,
      toUserId: json['toUserId'] as int?,
      callPrice: (json['callPrice'] as num?)?.toDouble(),
      callStatus: json['callStatus'] != null 
          ? CallStatus.fromCode(json['callStatus'] as int)
          : null,
      callType: json['callType'] as String? ?? '',
      createTime: json['createTime'] != null 
          ? DateTime.tryParse(json['createTime'].toString())
          : null,
      rtcType: json['rtcType'] as String?,
      createUserSign: json['createUserSign'] as String?,
      toUserSign: json['toUserSign'] as String?,
      anchorInfo: json['anchorInfo'] != null 
          ? AnchorModel.fromJson(json['anchorInfo'] as Map<String, dynamic>)
          : null,
      userInfo: json['userInfo'] != null 
          ? UserModelEntity.fromJson(json['userInfo'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'callNo': callNo,
      'createUserId': createUserId,
      'toUserId': toUserId,
      'callPrice': callPrice,
      'callStatus': callStatus?.code,
      'callType': callType,
      'createTime': createTime?.toIso8601String(),
      'rtcType': rtcType,
      'createUserSign': createUserSign,
      'toUserSign': toUserSign,
      'anchorInfo': anchorInfo?.toJson(),
      'userInfo': userInfo?.toJson(),
    };
  }

  CallData copyWith({
    String? callNo,
    int? createUserId,
    int? toUserId,
    double? callPrice,
    CallStatus? callStatus,
    String? callType,
    DateTime? createTime,
    String? rtcType,
    String? createUserSign,
    String? toUserSign,
    String? createUserRtcToken,
    String? answerUserRtcToken,
    AnchorModel? anchorInfo,
    UserModelEntity? userInfo,
  }) {
    return CallData(
      callNo: callNo ?? this.callNo,
      createUserId: createUserId ?? this.createUserId,
      toUserId: toUserId ?? this.toUserId,
      callPrice: callPrice ?? this.callPrice,
      callStatus: callStatus ?? this.callStatus,
      callType: callType ?? this.callType,
      createTime: createTime ?? this.createTime,
      rtcType: rtcType ?? this.rtcType,
      createUserSign: createUserSign ?? this.createUserSign,
      toUserSign: toUserSign ?? this.toUserSign,
      anchorInfo: anchorInfo ?? this.anchorInfo,
      userInfo: userInfo ?? this.userInfo,
    );
  }
}
/// 通话状态变更消息
class CallStatusChangeMessage {
  final int? customType;
  final String? callNo;
  final int? callStatus;
  final String? callStatusMsg;
  final int? callTime;
  final double? spendCoin;
  final String? desc;
  final int? actionType;
  final CallData? callInvite;


  CallStatusChangeMessage({
    this.customType,
    this.callNo,
    this.callStatus,
    this.callStatusMsg,
    this.callTime,
    this.spendCoin,
    this.desc,
    this.callInvite,
    this.actionType,
  });

  factory CallStatusChangeMessage.fromJson(Map<String, dynamic> json) {
    return CallStatusChangeMessage(
      customType: json['customType'] as int?,
      actionType: json['actionType'] as int?,
      callNo: json['callNo'] as String?,
      callStatus: json['callStatus'] as int?,
      callStatusMsg: json['callStatusMsg'] as String?,
      callTime: json['callTime'] as int?,
      spendCoin: (json['spendCoin'] as num?)?.toDouble(),
      desc: json['desc'] as String?,
      callInvite: json['callInvite'] != null
          ? CallData.fromJson(json['callInvite'] as Map<String, dynamic>)
          : null,
    );
  }

  /// 从 JSON 字符串解析
  static CallStatusChangeMessage? fromJsonString(String jsonString) {
    try {
      final Map<String, dynamic> json = 
          Map<String, dynamic>.from(jsonDecode(jsonString));
      return CallStatusChangeMessage.fromJson(json);
    } catch (e) {
      return null;
    }
  }

  /// 格式化通话时长 (HH:MM:SS)
  String get formattedDuration {
    if (callTime == null || callTime! <= 0) return '00:00:00';
    final h = callTime! ~/ 3600;
    final m = (callTime! % 3600) ~/ 60;
    final s = callTime! % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  /// 是否有有效通话时长
  bool get hasValidCallTime => callTime != null && callTime! > 0;

  /// 是否为未接听/超时
  bool get isMissed => callStatus == 32;

  /// 是否为取消
  bool get isCanceled => callStatus == 37;

  /// 是否为拒绝
  bool get isDeclined => callStatus == 30;

  /// 获取通话状态枚举
  CallStatus? get status => callStatus != null ? CallStatus.fromCode(callStatus!) : null;

  // /// 是否为通话正常结束
  // bool get isCallDone => callStatus == CallStatus.callDone.code;
  //
  // /// 是否为通话异常结束
  // bool get isCallingErrorDone => callStatus == CallStatus.callingErrorDone.code;
  //
  // /// 是否为拒绝通话
  // // bool get isRefuse => callStatus == CallStatus.refuse.code;

  /// 格式化通话时长文本
  String get formattedTypeText {
    if (callStatus == null) return '';
    
    switch (callStatus) {
      case 31: // CALL_DONE
      case 34: // CALLING_ERROR_DONE
        if (callTime != null && callTime! > 0) {
          final h = callTime! ~/ 3600;
          final m = (callTime! % 3600) ~/ 60;
          final s = callTime! % 60;
          return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
        }
        return '';
      case 37: // CANCEL_CALL
        return 'Canceled';
      case 30: // REFUSE
        return 'Declined';
      case 32: // CALL_TIMEOUT_DONE
        return 'Missed';
      default:
        return desc ?? '';
    }
  }
}
