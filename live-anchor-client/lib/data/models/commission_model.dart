/// 佣金记录模型
/// 对应 /anchorWork/getCommissionList 响应
class CommissionRecord {
  final DateTime? createTime;
  final int? id;
  final String? title;
  final String? image;
  final String? remark;
  final int? formUserId;
  final String? countDescribe;
  final double? money;
  final int? coinChangeType;
  final String? data;

  CommissionRecord({
    this.createTime,
    this.id,
    this.title,
    this.image,
    this.remark,
    this.formUserId,
    this.countDescribe,
    this.money,
    this.coinChangeType,
    this.data,
  });

  factory CommissionRecord.fromJson(Map<String, dynamic> json) {
    DateTime? parseCreateTime(dynamic value) {
      if (value == null) return null;

      // 如果是数字（秒级时间戳）
      if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value * 1000);
      }
      if (value is num) {
        return DateTime.fromMillisecondsSinceEpoch((value.toInt() * 1000));
      }

      // 如果是字符串，尝试解析
      if (value is String) {
        // 尝试解析为 ISO 8601 格式
        final parsed = DateTime.tryParse(value);
        if (parsed != null) return parsed;

        // 尝试解析为秒级时间戳字符串
        final timestamp = int.tryParse(value);
        if (timestamp != null) {
          return DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
        }
      }

      return null;
    }

    return CommissionRecord(
      createTime: parseCreateTime(json['createTime']),
      id: json['id'] as int?,
      title: json['title'] as String?,
      image: json['image'] as String?,
      remark: json['remark'] as String?,
      formUserId: json['formUserId'] as int?,
      countDescribe: json['countDescribe'] as String?,
      money: (json['money'] as num?)?.toDouble(),
      coinChangeType: json['coinChangeType'] as int?,
      data: json['data'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'createTime': createTime?.toIso8601String(),
      'id': id,
      'title': title,
      'image': image,
      'remark': remark,
      'formUserId': formUserId,
      'countDescribe': countDescribe,
      'money': money,
      'coinChangeType': coinChangeType,
      'data': data,
    };
  }
}

/// 月度账单模型
/// 对应 /anchorWork/getMonthCommissionList 响应
class MonthCommission {
  final int? month; // 时间戳（秒级）
  final double? income;
  final double? withdrawal;

  MonthCommission({this.month, this.income, this.withdrawal});

  factory MonthCommission.fromJson(Map<String, dynamic> json) {
    return MonthCommission(
      month: json['month'] is int
          ? json['month'] as int?
          : (json['month'] is String ? int.tryParse(json['month'] as String) : null),
      income: (json['income'] as num?)?.toDouble(),
      withdrawal: (json['withdrawal'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'month': month, 'income': income, 'withdrawal': withdrawal};
  }
}

/// 工作统计报表模型
/// 对应 /anchorWork/getWorkReport 响应
class WorkReport {
  final int? onlineTime; // 在线时长(分钟)
  final int? callNum; // 通话次数
  final int? callingNum; // 接通次数
  final double? callIncome; // 通话收益
  final double? giftIncome; // 礼物收益
  final double? videoIncome; // 视频收益
  final double? matchConversion; // 匹配转化率
  final double? matchConversionRewards; // 匹配转化奖励
  final double? connectionRate; // 接通率
  final double? totalIncome; // 总收益

  WorkReport({
    this.onlineTime,
    this.callNum,
    this.callingNum,
    this.callIncome,
    this.giftIncome,
    this.videoIncome,
    this.matchConversion,
    this.matchConversionRewards,
    this.connectionRate,
    this.totalIncome,
  });

  factory WorkReport.fromJson(Map<String, dynamic> json) {
    return WorkReport(
      onlineTime: json['onlineTime'] as int?,
      callNum: json['callNum'] as int?,
      callingNum: json['callingNum'] as int?,
      callIncome: (json['callIncome'] as num?)?.toDouble(),
      giftIncome: (json['giftIncome'] as num?)?.toDouble(),
      videoIncome: (json['videoIncome'] as num?)?.toDouble(),
      matchConversion: (json['matchConversion'] as num?)?.toDouble(),
      matchConversionRewards: (json['matchConversionRewards'] as num?)?.toDouble(),
      connectionRate: (json['connectionRate'] as num?)?.toDouble(),
      totalIncome: (json['totalIncome'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'onlineTime': onlineTime,
      'callNum': callNum,
      'callingNum': callingNum,
      'callIncome': callIncome,
      'giftIncome': giftIncome,
      'videoIncome': videoIncome,
      'matchConversion': matchConversion,
      'matchConversionRewards': matchConversionRewards,
      'connectionRate': connectionRate,
      'totalIncome': totalIncome,
    };
  }

  /// 格式化在线时长
  String get formattedOnlineTime {
    if (onlineTime == null || onlineTime == 0) return '0h 0m';
    final hours = onlineTime! ~/ 60;
    final minutes = onlineTime! % 60;
    return '${hours}h ${minutes}m';
  }
}

/// 提现请求模型
/// 对应 /anchorWork/withdrawal 请求
class WithdrawalRequest {
  final int payType; // 支付方式
  final double money; // 提现金额
  final String payUsername; // 收款人姓名
  final String payAccount; // 收款账号

  WithdrawalRequest({required this.payType, required this.money, required this.payUsername, required this.payAccount});

  Map<String, dynamic> toJson() {
    return {'payType': payType, 'money': money, 'payUsername': payUsername, 'payAccount': payAccount};
  }
}

/// 实际到账金额响应
/// 对应 /anchorWork/getActualAmountReceived 响应
class ActualAmountReceived {
  final double? commission; // 手续费
  final double? actualMoney; // 实际到账金额

  ActualAmountReceived({this.commission, this.actualMoney});

  factory ActualAmountReceived.fromJson(Map<String, dynamic> json) {
    return ActualAmountReceived(
      commission: (json['commission'] as num?)?.toDouble(),
      actualMoney: (json['actualMoney'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'commission': commission, 'actualMoney': actualMoney};
  }
}

/// 获取佣金记录请求
class GetCommissionListRequest {
  final int page;
  final int size;
  final DateTime? filterTime;

  /// 月份时间戳（秒级），与 bill_page 请求下来的 month 字段一致，优先传此值作为 filterTime
  final int? filterTimeStamp;
  final List<int>? coinChangeType;

  GetCommissionListRequest({
    required this.page,
    required this.size,
    this.filterTime,
    this.filterTimeStamp,
    this.coinChangeType,
  });

  Map<String, dynamic> toJson() {
    return {
      'page': page,
      'size': size,
      if (filterTimeStamp != null) 'filterTime': filterTimeStamp,
      if (filterTimeStamp == null && filterTime != null) 'filterTime': filterTime!.toIso8601String(),
      if (coinChangeType != null) 'coinChangeType': coinChangeType,
    };
  }
}
