/// 通话历史记录模型
/// 对应 /call/getCallHistory 响应
class CallHistory {
  final int? id;               // 记录 ID
  final String? callId;        // 通话 ID（如 "TRTC_xxx"）
  final int? userId;           // 用户 ID
  final int? createUserId;     // 发起通话的用户 ID（用于区分拨出/接听）
  final String? nickname;      // 昵称
  final String? avatar;        // 头像
  final int? createTime;       // 创建时间（时间戳秒）
  final int? callTime;         // 通话时长（秒）
  final int? spendCoin;        // 花费金币
  final int? coinBalance;      // 金币余额
  final int? intimacy;         // 亲密度
  final bool? converted;       // 是否转换
  final bool? matchCall;       // 是否匹配通话
  final int? callStatus;       // 通话状态 (30: 未接听等)
  final int? onlineStatus;     // 在线状态 (1: 在线)
  final int? followStatus;     // 关注状态
  final int? blackStatus;      // 拉黑状态
  final int? country;          // 国家代码
  final int? callPrice;        // 通话价格
  final int? anchorCategory;   // 主播分类
  final int? anchorVirtual;    // 是否虚拟主播 (1: 是)
  final int? isFreeCall;       // 是否免费通话 (1: 是)
  final int? age;              // 年龄
  final int? callDirection;    // 通话方向 (1: 来电 In Call, 2: 拨出 Outgoing)

  CallHistory({
    this.id,
    this.callId,
    this.userId,
    this.createUserId,
    this.nickname,
    this.avatar,
    this.createTime,
    this.callTime,
    this.spendCoin,
    this.coinBalance,
    this.intimacy,
    this.converted,
    this.matchCall,
    this.callStatus,
    this.onlineStatus,
    this.followStatus,
    this.blackStatus,
    this.country,
    this.callPrice,
    this.anchorCategory,
    this.anchorVirtual,
    this.isFreeCall,
    this.age,
    this.callDirection,
  }); 

  factory CallHistory.fromJson(Map<String, dynamic> json) {
    return CallHistory(
      id: json['id'] as int?,
      callId: json['callId'] as String?,
      userId: json['userId'] as int?,
      createUserId: json['createUserId'] as int? ?? json['create_user_id'] as int?,
      nickname: json['nickname'] as String?,
      avatar: json['avatar'] as String?,
      createTime: json['createTime'] as int?,
      callTime: json['callTime'] as int?,
      spendCoin: json['spendCoin'] as int?,
      coinBalance: json['coinBalance'] as int?,
      intimacy: json['intimacy'] as int?,
      converted: json['converted'] as bool?,
      matchCall: json['matchCall'] as bool?,
      callStatus: json['callStatus'] as int?,
      onlineStatus: json['onlineStatus'] as int?,
      followStatus: json['followStatus'] as int?,
      blackStatus: json['blackStatus'] as int?,
      country: json['country'] as int?,
      callPrice: json['callPrice'] as int?,
      anchorCategory: json['anchorCategory'] as int?,
      anchorVirtual: json['anchorVirtual'] as int?,
      isFreeCall: json['isFreeCall'] as int?,
      age: json['age'] as int?,
      callDirection: json['callDirection'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'callId': callId,
      'userId': userId,
      'createUserId': createUserId,
      'nickname': nickname,
      'avatar': avatar,
      'createTime': createTime,
      'callTime': callTime,
      'spendCoin': spendCoin,
      'coinBalance': coinBalance,
      'intimacy': intimacy,
      'converted': converted,
      'matchCall': matchCall,
      'callStatus': callStatus,
      'onlineStatus': onlineStatus,
      'followStatus': followStatus,
      'blackStatus': blackStatus,
      'country': country,
      'callPrice': callPrice,
      'anchorCategory': anchorCategory,
      'anchorVirtual': anchorVirtual,
      'isFreeCall': isFreeCall,
      'age': age,
      'callDirection': callDirection,
    };
  }

  /// 获取 DateTime 格式的创建时间
  DateTime? get createDateTime {
    if (createTime == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(createTime! * 1000);
  }

  /// 格式化通话时长 (HH:MM:SS)
  String get formattedDuration {
    if (callTime == null || callTime == 0) return '00:00:00';
    final hours = callTime! ~/ 3600;
    final minutes = (callTime! % 3600) ~/ 60;
    final seconds = callTime! % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// 是否在线
  bool get isOnline => onlineStatus == 1;

  /// 是否为匹配通话
  bool get isMatchCallType => matchCall == true;

  /// 是否为免费通话
  bool get isFree => isFreeCall == 1;

  /// 是否为虚拟主播
  bool get isVirtual => anchorVirtual == 1;

  /// 是否为来电 (用户打给主播)
  bool get isIncoming => callDirection == 1;

  /// 是否为拨出 (主播打给用户)
  bool get isOutgoing => callDirection == 2;

  /// 通话方向文本
  String get callDirectionText => isIncoming ? 'In Call' : 'Outgoing';

  /// 是否已接听（有通话时长）
  bool get isAnswered => callTime != null && callTime! > 0;

  /// 是否未接听
  bool get isMissed => callStatus == 30;

  /// 是否被拒接
  bool get isDeclined => callStatus == 50 || callStatus == 60;

  /// 是否被取消
  bool get isCancelled => callStatus == 40 || callStatus == 70;

  /// 获取通话结果状态文本
  String get callResultText {
    // 已接听 - 显示时长
    if (isAnswered) {
      return formattedDuration;
    }
    // 未接听
    if (isMissed) {
      return 'Missed';
    }
    // 拒接
    if (isDeclined) {
      return 'Declined';
    }
    // 取消
    if (isCancelled) {
      return 'Canceled';
    }
    // 默认
    return callStatusText;
  }

  /// 通话状态描述
  String get callStatusText {
    switch (callStatus) {
      case 10:
        return 'Calling';
      case 20:
        return 'Connected';
      case 30:
        return 'Missed';
      case 40:
        return 'Ended';
      case 50:
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }
}

/// 获取通话历史请求
class GetCallHistoryRequest {
  final int page;
  final int size;
  final int? callType;   // 通话类型筛选

  GetCallHistoryRequest({
    required this.page,
    required this.size,
    this.callType,
  });

  Map<String, dynamic> toJson() {
    return {
      'page': page,
      'size': size,
      if (callType != null) 'callType': callType,
    };
  }
}

/// 通话创建请求
class CallCreateRequest {
  final int toUserId;

  CallCreateRequest({
    required this.toUserId,
  });

  Map<String, dynamic> toJson() {
    return {
      'toUserId': toUserId,
    };
  }
}

/// 通话结束请求
class CallEndRequest {
  final String callNo;
  final int duration;

  CallEndRequest({
    required this.callNo,
    required this.duration,
  });

  Map<String, dynamic> toJson() {
    return {
      'callNo': callNo,
      'duration': duration,
    };
  }
}

/// 通话评价请求
class CallCommentRequest {
  final String callNo;
  final int score;        // 评分
  final String? comment;  // 评价内容

  CallCommentRequest({
    required this.callNo,
    required this.score,
    this.comment,
  });

  Map<String, dynamic> toJson() {
    return {
      'callNo': callNo,
      'score': score,
      if (comment != null) 'comment': comment,
    };
  }
}
