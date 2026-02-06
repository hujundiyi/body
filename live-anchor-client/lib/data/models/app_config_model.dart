/// 应用配置模型
class AppConfigModel {
  static String? _configString(dynamic v) {
    if (v == null) return null;
    if (v is String) return v;
    if (v is num) return v.toString();
    return v.toString();
  }

  final String? baseSpringLiveUrl;
  final String? defUrlUserAgreement;
  final String? defAgoraAppId;
  final String? defUrlEula;
  final String? defTencentChatPushId;
  final String? defOperationalStatus;
  final String? defUrlPrivacyAgreement;
  final String? defAppCustomerEmail;
  final int? defTencentChatAppId;
  final int? defTencentRtcAppId;
  final String? anchorWithdrawalMinMoney;
  final String? anchorWithdrawalCommission;

  AppConfigModel({
    this.baseSpringLiveUrl,
    this.defUrlUserAgreement,
    this.defAgoraAppId,
    this.defUrlEula,
    this.defTencentChatPushId,
    this.defOperationalStatus,
    this.defUrlPrivacyAgreement,
    this.defAppCustomerEmail,
    this.defTencentChatAppId,
    this.defTencentRtcAppId,
    this.anchorWithdrawalMinMoney,
    this.anchorWithdrawalCommission,
  });

  factory AppConfigModel.fromJson(Map<String, dynamic> json) {
    return AppConfigModel(
      baseSpringLiveUrl: json['BASE_SPRING_LIVE_URL'] as String?,
      defUrlUserAgreement: json['DEF_URL_USER_AGREEMENT'] as String?,
      defAgoraAppId: json['DEF_AGORA_APP_ID'] as String?,
      defUrlEula: json['DEF_URL_EULA'] as String?,
      defTencentChatPushId: json['DEF_TENCENT_CHAT_PUSH_ID'] as String?,
      defOperationalStatus: json['DEF_OPERATIONAL_STATUS'] as String?,
      defUrlPrivacyAgreement: json['DEF_URL_PRIVACY_AGREEMENT'] as String?,
      defAppCustomerEmail: json['DEF_APP_CUSTOMER_EMAIL'] as String?,
      defTencentChatAppId: json['DEF_TENCENT_CHAT_APP_ID'] as int?,
      defTencentRtcAppId: json['DEF_TENCENT_RTC_APP_ID'] as int?,
      anchorWithdrawalMinMoney: _configString(json['ANCHOR_WITHDRAWAL_MIN_MONEY']),
      anchorWithdrawalCommission: _configString(json['ANCHOR_WITHDRAWAL_COMMISSION']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'BASE_SPRING_LIVE_URL': baseSpringLiveUrl,
      'DEF_URL_USER_AGREEMENT': defUrlUserAgreement,
      'DEF_AGORA_APP_ID': defAgoraAppId,
      'DEF_URL_EULA': defUrlEula,
      'DEF_TENCENT_CHAT_PUSH_ID': defTencentChatPushId,
      'DEF_OPERATIONAL_STATUS': defOperationalStatus,
      'DEF_URL_PRIVACY_AGREEMENT': defUrlPrivacyAgreement,
      'DEF_APP_CUSTOMER_EMAIL': defAppCustomerEmail,
      'DEF_TENCENT_CHAT_APP_ID': defTencentChatAppId,
      'DEF_TENCENT_RTC_APP_ID': defTencentRtcAppId,
      'ANCHOR_WITHDRAWAL_MIN_MONEY': anchorWithdrawalMinMoney,
      'ANCHOR_WITHDRAWAL_COMMISSION': anchorWithdrawalCommission,
    };
  }

  // ========== 便捷属性 ==========

  /// 声网 AppId
  String get agoraAppId => defAgoraAppId ?? '';

  /// 腾讯云 IM AppId
  int get tencentChatAppId => defTencentChatAppId ?? 0;

  /// 腾讯云 RTC AppId
  int get tencentRtcAppId => defTencentRtcAppId ?? 0;

  /// 腾讯云推送 ID
  String get tencentChatPushId => defTencentChatPushId ?? '';

  /// 用户协议 URL
  String get userAgreementUrl => defUrlUserAgreement ?? '';

  /// 隐私协议 URL
  String get privacyAgreementUrl => defUrlPrivacyAgreement ?? '';

  /// EULA URL
  String get eulaUrl => defUrlEula ?? '';

  /// H5 基础地址
  String get springLiveUrl => baseSpringLiveUrl ?? '';

  /// 客服邮箱
  String? get customerEmail => defAppCustomerEmail;

  /// 是否正常运营
  bool get isOperational => defOperationalStatus == '1';

  /// 复制并更新
  AppConfigModel copyWith({
    String? baseSpringLiveUrl,
    String? defUrlUserAgreement,
    String? defAgoraAppId,
    String? defUrlEula,
    String? defTencentChatPushId,
    String? defOperationalStatus,
    String? defUrlPrivacyAgreement,
    String? defAppCustomerEmail,
    int? defTencentChatAppId,
    int? defTencentRtcAppId,
  }) {
    return AppConfigModel(
      baseSpringLiveUrl: baseSpringLiveUrl ?? this.baseSpringLiveUrl,
      defUrlUserAgreement: defUrlUserAgreement ?? this.defUrlUserAgreement,
      defAgoraAppId: defAgoraAppId ?? this.defAgoraAppId,
      defUrlEula: defUrlEula ?? this.defUrlEula,
      defTencentChatPushId: defTencentChatPushId ?? this.defTencentChatPushId,
      defOperationalStatus: defOperationalStatus ?? this.defOperationalStatus,
      defUrlPrivacyAgreement: defUrlPrivacyAgreement ?? this.defUrlPrivacyAgreement,
      defAppCustomerEmail: defAppCustomerEmail ?? this.defAppCustomerEmail,
      defTencentChatAppId: defTencentChatAppId ?? this.defTencentChatAppId,
      defTencentRtcAppId: defTencentRtcAppId ?? this.defTencentRtcAppId,
    );
  }

  @override
  String toString() {
    return 'AppConfigModel(agoraAppId: $agoraAppId, tencentChatAppId: $tencentChatAppId, isOperational: $isOperational)';
  }
}
