/// 应用常量
class AppConstants {
  // 应用信息
  static const String appName = 'Weeder';
  static const String appVersion = '1.0.1';
  static const String packageName = 'com.weeder.app'; // TODO: 替换为实际包名

  // API相关
  static const String baseUrl = 'https://api.example.com'; // TODO: 替换为实际API地址
  static const int connectTimeout = 30000; // 30秒
  static const int receiveTimeout = 30000; // 30秒

  // 存储键名
  static const String keyToken = 'auth_token';
  static const String keyUserInfo = 'user_info';
  static const String keyThemeMode = 'theme_mode';
  static const String keyLanguage = 'language';
  static const String keyPendingUploads = 'pending_uploads';
  static const String keyWorkStatus = 'work_status_is_working';

  /// 远程通知（离线推送）开关，默认 true
  static const String keyRemoteNotificationEnabled = 'remote_notification_enabled';

  /// 应用内通知（前台消息横幅）开关，默认 true
  static const String keyInAppNotificationEnabled = 'in_app_notification_enabled';

  /// 来消息/来电铃声开关，默认 true
  static const String keySoundingEnabled = 'sounding_enabled';

  /// 应用更新：未完成/已完成未安装时持久化，用于杀进程后恢复
  static const String keyPendingUpdateJson = 'pending_update_json';
  static const String keyPendingUpdateCompleted = 'pending_update_completed';
  static const String keyPendingUpdateInstallStarted = 'pending_update_install_started';

  /// 下载进度 0.0~1.0，杀进程后恢复时用于界面从上次进度显示
  static const String keyPendingUpdateProgress = 'pending_update_progress';

  /// 美颜设置持久化
  static const String keyBeautyEnabled = 'beauty_enabled';
  static const String keyBeautyLevel = 'beauty_level';
  static const String keyWhitenessLevel = 'beauty_whiteness_level';
  static const String keyRuddinessLevel = 'beauty_ruddiness_level';

  // 分页
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // 图片相关
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png', 'gif'];

  // 网络状态
  static const String networkError = 'Network error. Please check your connection.';
  static const String serverError = 'Server error. Please try again later.';
  static const String unknownError = 'Unknown error';

  // 验证规则（密码 6-18 位）
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 18;
  static const int minUsernameLength = 3;
  static const int maxUsernameLength = 20;

  // 正则表达式
  static const String emailRegex = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
  static const String phoneRegex = r'^1[3-9]\d{9}$';

  // 动画时长
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
}

/// 环境配置
enum AppEnvironment { development, staging, production }

/// 环境配置管理
class EnvironmentConfig {
  static AppEnvironment _currentEnvironment = AppEnvironment.development;

  static AppEnvironment get current => _currentEnvironment;

  static void setEnvironment(AppEnvironment env) {
    _currentEnvironment = env;
  }

  static String get baseURL {
    switch (_currentEnvironment) {
      case AppEnvironment.development:
        return 'http://8.137.21.100:8080/'; // TODO: 替换为实际开发环境API地址
      // return 'http://192.168.110.193:8080/'; // TODO: 替换为实际开发环境API地址
      case AppEnvironment.staging:
        return 'http://8.137.21.100:8080/'; // TODO: 替换为实际测试环境API地址
      case AppEnvironment.production:
        return 'https://baseapi.live9527.com/'; // TODO: 替换为实际生产环境API地址
    }
  }

  static String get packageName {
    switch (_currentEnvironment) {
      case AppEnvironment.development:
        return 'LiveTalent';
      case AppEnvironment.staging:
        return 'LiveTalent';
      case AppEnvironment.production:
        return 'LiveTalent';
    }
  }
}

/// API 请求头定义
/// 对应 Swift 版本的 BHIAPIDefine
class APIHeaderKeys {
  static const String signature = 'X-Signature';
  static const String requestId = 'X-Request-ID';
  static const String requestTimestamp = 'X-Request-Timestamp';
  static const String appInfo = 'X-App-Info';
  static const String language = 'X-Language';
  static const String region = 'X-Region';
  static const String deviceId = 'X-Device-ID';
  static const String appChannel = 'X-App-Channel';
  static const String contentType = 'Content-Type';
  static const String authorization = 'Authorization';
}

/// API 路径定义
/// 基于 Swagger 文档 LiveChat-API
class APIPaths {
  // ==================== 登录、注册 ====================
  static const String anchorLogin = 'authorize/anchorLogin';
  static const String userLogin = 'authorize/login';
  static const String getAnchorInfo = 'authorize/getAnchorInfo';
  static const String getUserInfo = 'authorize/getUserInfo';
  static const String changePassword = 'authorize/changePassword';
  static const String loginOut = 'authorize/loginOut';
  static const String toHome = 'authorize/toHome';

  // ==================== 主播相关 ====================
  static const String anchorSetInfo = 'anchor/setInfo';
  static const String anchorGetInfo = 'anchor/getInfo';
  static const String anchorGetList = 'anchor/getList';
  static const String anchorGetDetailList = 'anchor/getDetailList';
  static const String anchorRankingList = 'anchor/rankingList';
  static const String anchorRecommend = 'anchor/recommendAnchor';
  static const String anchorMatcher = 'anchor/matcherAnchor';

  // ==================== 主播工作台 ====================
  static const String getWorkReport = 'anchorWork/getWorkReport';
  static const String getCommissionList = 'anchorWork/getCommissionList';
  static const String getMonthCommissionList = 'anchorWork/getMonthCommissionList';
  static const String withdrawal = 'anchorWork/withdrawal';
  static const String getActualAmountReceived = 'anchorWork/getActualAmountReceived';
  static const String setShowMeVideo = 'anchorWork/setShowMeVideo';
  static const String getShowMeVideo = 'anchorWork/getShowMeVideo';
  static const String addSayHiMessage = 'anchorWork/addSayHiMessage';
  static const String getSayHiMessage = 'anchorWork/getSayHiMessage';
  static const String delSayHiMessage = 'anchorWork/delSayHiMessage';
  static const String setSayHiMessageDefault = 'anchorWork/setSayHiMessageDefault';

  // ==================== 主播任务 ====================
  static const String anchorTaskH5Url = 'anchor/task/getH5Url';

  // ==================== 用户相关 ====================
  static const String userSetInfo = 'user/setInfo';
  static const String userGetInfo = 'user/getInfo';
  static const String userGetList = 'user/getList';
  static const String userRankingList = 'user/rankingList';
  static const String userReport = 'user/reportUser';
  static const String userFeedback = 'user/feedback';
  static const String userDelete = 'user/delUser';
  static const String rtmToken = 'user/rtmToken';
  static const String rtcToken = 'user/rtcToken';

  // ==================== 用户状态 ====================
  static const String getFollowList = 'userStatus/getFollowList';
  static const String getBlackList = 'userStatus/getBlackList';
  static const String getBatchList = 'userStatus/getBatchList';
  static const String followStatus = 'userStatus/followStatus';
  static const String blackStatus = 'userStatus/blackStatus';

  // ==================== 通话相关 ====================
  static const String callCreate = 'call/callCreate';
  static const String callStart = 'call/callStart';
  static const String callEnd = 'call/callEnd';
  static const String getCallHistory = 'call/getCallHistory';
  static const String callComment = 'call/callComment';
  static const String postScreenshot = 'call/postScreenshot';

  // ==================== 消息发送 ====================
  static const String messageSend = 'message/send';
  static const String messageSendText = 'message/sendText';
  static const String messageSendImg = 'message/sendImg';
  static const String messageSendSound = 'message/sendSound';
  static const String messageSendVideo = 'message/sendVideo';
  static const String messageSendGift = 'message/sendGift';
  static const String messageTranslation = 'message/translationMsg';

  // ==================== 视频相关 ====================
  static const String videoPublish = 'video/publish';
  static const String videoRemove = 'video/remove';
  static const String videoMyVideos = 'video/myVideos';
  static const String videoGetList = 'video/getVideoList';
  static const String videoGetById = 'video/getVideoById';
  static const String videoLike = 'video/likeVideo';
  static const String videoPurchase = 'video/purchase';

  // ==================== 音频相关 ====================
  static const String audioPublish = 'audio/publish';
  static const String audioRemove = 'audio/remove';
  static const String audioGetList = 'audio/getAudioList';
  static const String audioGetMyList = 'audio/getMyAudioList';
  static const String audioGetById = 'audio/getAudioById';
  static const String audioLike = 'audio/likeAudio';
  static const String audioPurchase = 'audio/purchase';
  static const String audioComment = 'audio/comment';
  static const String audioGetCommentList = 'audio/getCommentList';
  static const String audioGetCategoryList = 'audio/getAudioCategoryList';
  static const String audioGetByUserId = 'audio/getAudioListByUserId';

  // ==================== 图集相关 ====================
  static const String pictureGetList = 'picture/getList';
  static const String pictureBatchAddUpdate = 'picture/batchAddUpdate';
  static const String pictureRemove = 'picture/remove';

  // ==================== 充值、消耗 ====================
  static const String getRechargeList = 'rechargeConsume/getRechargeList';
  static const String getGiftList = 'rechargeConsume/getGiftList';
  static const String getCoinConsumeList = 'rechargeConsume/getCoinConsumeList';
  static const String purchasePicture = 'rechargeConsume/purchasePicture';
  static const String iosSuccess = 'rechargeConsume/iosSuccess';
  static const String googleSuccess = 'rechargeConsume/googleSuccess';

  // ==================== 系统相关 ====================
  static const String getPutFileUrl = 'system/getPutFileUrl';
  static const String getPutFileUrls = 'system/getPutFileUrls';
  static const String getBanner = 'system/getBanner';

  // ==================== 初始化配置 ====================
  static const String getConfig = 'init/getConfig';
  static const String getDict = 'init/getDict';
  static const String getIpCountry = 'init/getIpCountry';
  static const String getAppUpdate = 'init/getAppUpdate';

  // ==================== 第三方支付 ====================
  static const String payWithCashier = 'payIn/payWithCashier';

  // ==================== 旧版兼容（加密路径） ====================
  // static const String login = 'authorize/anchorLogin';
  static const String deleteAccount = 'E881E77BD0CA31BD7131BEED673A75B1.do';
  static const String editInfo = 'FDC8503A89C90D01AB5404A8B8ED46D8.do';
  static const String updateInfo = 'dbbfb9cf.do';
  static const String getUserInfoOld = '053D133C76056A57513140EA4878C178.do';
  static const String getUserInfoByIds = 'fa97fd74.do';
  static const String premiumInfo = 'dd969b34.do';
  static const String getUserList = 'user/getList';
  static const String getHomeList = 'E54205C5EE38A3C104450076BD76E036.do';
  static const String product = 'c5f1613d.do';
  static const String recharge = '32E28BDF334ECDEE2336F1B83ECAFC01.do';
  static const String verifyOrder = 'C2A0C59E560503F69A0CAFAB8D57B9B0.do';
  static const String walletBalance = 'f57d1444.do';
  static const String deduction = '4a438a17.do';
  static const String configuration = 'D1FF55A73154F6191C6AB69E8CA265CB.do';
  static const String getUploadUrl = 'e5f2f722.do';
}

/// 审核状态枚举
class AuditStatus {
  static const int pending = 0; // 待审核
  static const int approved = 1; // 审核通过
  static const int rejected = 2; // 审核拒绝
}

/// 在线状态枚举
class OnlineStatus {
  static const int offline = 0; // 离线
  static const int online = 1; // 在线
  static const int busy = 2; // 忙碌/通话中
}

/// 性别枚举
class Gender {
  static const int male = 0; // 男
  static const int female = 1; // 女
  static const int unknown = 2; // 未知
}

/// 联系方式类型
class LinkType {
  static const int whatsApp = 1;
  static const int telegram = 2;
  static const int line = 3;
}

/// 排行榜时间类型
class RankingTimeType {
  static const String all = 'ALL';
  static const String day = 'DAY';
  static const String week = 'WEEK';
  static const String month = 'MONTH';
}
