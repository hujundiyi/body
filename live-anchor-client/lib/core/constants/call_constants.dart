/// 通话相关常量
/// 参照 H5 SDK Constant.js

/// 通话状态枚举
enum CallStatus {
  /// 通话创建
  create(code: 0, value: 'create'),
  /// 接听
  answer(code: 1, value: 'answer'),
  /// 通话中
  calling(code: 2, value: 'calling'),
  /// 拒接
  refuse(code: 30, value: 'refuse'),
  /// 通话正常结束
  callDone(code: 31, value: 'callDone'),
  /// 超时未接听
  callTimeoutDone(code: 32, value: 'callTimeoutDone'),
  /// 异常挂断（未接通）
  callErrorDone(code: 33, value: 'callErrorDone'),
  /// 异常挂断（已接通）
  callingErrorDone(code: 34, value: 'callingErrorDone'),
  /// 余额不足结束
  notBalanceDone(code: 35, value: 'notBalanceDone'),
  /// 系统终止
  systemStop(code: 36, value: 'systemStop'),
  /// 取消拨号
  cancelCall(code: 37, value: 'cancelCall');

  final int code;
  final String value;

  const CallStatus({required this.code, required this.value});

  /// 根据 code 查找状态
  static CallStatus? fromCode(int code) {
    return CallStatus.values.cast<CallStatus?>().firstWhere(
      (status) => status?.code == code,
      orElse: () => null,
    );
  }

  /// 根据 value 查找状态
  static CallStatus? fromValue(String value) {
    return CallStatus.values.cast<CallStatus?>().firstWhere(
      (status) => status?.value == value,
      orElse: () => null,
    );
  }

  /// 是否为结束状态
  bool get isEndStatus {
    return code >= 30;
  }

  /// 是否为通话中状态
  bool get isCallingStatus {
    return this == CallStatus.calling;
  }
}

/// 本地通话状态枚举
enum LocalCallStatus {
  /// 无通话状态
  none(code: 0, value: 'localCallNone'),
  /// 等待接听（拨打中/来电中）
  waiting(code: 1, value: 'localCallWaiting'),
  /// 通话中
  calling(code: 2, value: 'localCallCalling'),
  /// 通话结束
  end(code: 3, value: 'localCallEnd');

  final int code;
  final String value;

  const LocalCallStatus({required this.code, required this.value});

  static LocalCallStatus? fromCode(int code) {
    return LocalCallStatus.values.cast<LocalCallStatus?>().firstWhere(
      (status) => status?.code == code,
      orElse: () => null,
    );
  }
}

/// 自定义消息类型 - 1000-1999段 通话业务
class CallMessageType {
  /// 用户状态变更
  static const int onlineStatusChange = 1001;
  /// 通话邀请消息
  static const int callInvite = 1002;
  /// 通话状态变更
  static const int callStatusChange = 1003;
  /// 通话不足一分钟提示（充值提醒）
  static const int lessThanOneMinute = 1004;

  /// 礼物消息
  static const int gift = 2000;
  /// 金币变更
  static const int coinChange = 2001;
  /// VIP变更
  static const int vipChange = 2002;
}

/// 通话事件类型
class CallEventType {
  /// 通话创建
  static const String create = 'create';
  /// 接听通话
  static const String answer = 'answer';
  /// 拒绝通话
  static const String refuse = 'refuse';
  /// 取消通话
  static const String cancel = 'cancel';
  /// 通话结束
  static const String end = 'end';
  /// 通话超时
  static const String timeout = 'timeout';
}

/// 通话角色
enum CallRole {
  /// 主播（被叫方）
  anchor,
  /// 用户（主叫方）
  user,
}

/// 通话配置
class CallConfig {
  /// 来电/去电等待超时时间（毫秒），超过未接通则超时
  static const int incomingTimeout = 60000;
  
  /// 挂断按钮禁用时间（毫秒）
  static const int hangupDisableTime = 5000;
  
  /// 充值提醒显示后收起时间（毫秒）
  static const int rechargeReminderCollapseTime = 3000;
  
  /// 充值提醒最后闪烁时间（秒）
  static const int rechargeReminderFlashTime = 20;
}
