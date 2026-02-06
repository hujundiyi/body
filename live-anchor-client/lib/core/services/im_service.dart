import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:tencent_cloud_chat_sdk/enum/V2TimAdvancedMsgListener.dart';
import 'package:tencent_cloud_chat_sdk/enum/V2TimConversationListener.dart';
import 'package:tencent_cloud_chat_sdk/enum/V2TimFriendshipListener.dart';
import 'package:tencent_cloud_chat_sdk/enum/V2TimGroupListener.dart';
import 'package:tencent_cloud_chat_sdk/enum/V2TimSDKListener.dart';
import 'package:tencent_cloud_chat_sdk/enum/friend_type_enum.dart';
import 'package:tencent_cloud_chat_sdk/enum/history_msg_get_type_enum.dart';
import 'package:tencent_cloud_chat_sdk/enum/log_level_enum.dart';
import 'package:tencent_cloud_chat_sdk/enum/message_elem_type.dart';
import 'package:tencent_cloud_chat_sdk/enum/message_priority_enum.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_callback.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_conversation.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_conversation_result.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_message.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_msg_create_info_result.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_user_full_info.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_user_status.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_value_callback.dart';
import 'package:tencent_cloud_chat_sdk/tencent_im_sdk_plugin.dart';
import '../network/api_services.dart';
import '../network/api_exception.dart';
import '../constants/call_constants.dart';
import '../constants/app_constants.dart';
import 'app_config_service.dart';
import 'auth_service.dart';
import 'call_service.dart';
import 'storage_service.dart';
import '../utils/toast_utils.dart';
import 'blocked_user_service.dart';
import '../../routes/app_routes.dart';
import '../../data/models/call_data_model.dart';
import '../../data/models/user_model_entity.dart';

/// 腾讯云 IM 服务
class IMService extends GetxService {
  static const MethodChannel _pushTokenChannel = MethodChannel('im_push_token');

  // ============ 配置 ============
  /// 从 AppConfigService 获取 SDKAppID
  int get sdkAppID => AppConfigService.shared.tencentChatAppId;

  /// 从 AppConfigService 获取推送 ID
  String get pushId => AppConfigService.shared.tencentChatPushId;

  // ============ 状态 ============
  /// SDK 是否已初始化
  final RxBool _isInitialized = false.obs;
  bool get isInitialized => _isInitialized.value;

  /// 是否已登录
  final RxBool _isLoggedIn = false.obs;
  bool get isLoggedIn => _isLoggedIn.value;

  /// 用于监听登录状态（如进入首页后等 IM 登录成功再注册离线推送）
  RxBool get isLoggedInRx => _isLoggedIn;

  /// 连接状态
  final Rx<IMConnectionStatus> _connectionStatus = IMConnectionStatus.disconnected.obs;
  IMConnectionStatus get connectionStatus => _connectionStatus.value;

  /// 当前登录用户ID
  String? _currentUserID;
  String? get currentUserID => _currentUserID;

  /// 当前用户信息
  final Rx<V2TimUserFullInfo?> _currentUserInfo = Rx<V2TimUserFullInfo?>(null);
  V2TimUserFullInfo? get currentUserInfo => _currentUserInfo.value;

  /// App 是否在前台
  final RxBool _isAppInForeground = true.obs;
  bool get isAppInForeground => _isAppInForeground.value;

  /// 当前活跃会话（用于前台消息免打扰）
  String? _activeChatUserID;
  String? _activeChatGroupID;

  /// 最近一次注册的推送 Token
  String? _lastPushToken;
  String? _pendingPushToken;

  /// 用户信息缓存（用于前台弹窗）
  final Map<String, UserModelEntity> _userInfoCache = {};

  /// 会话列表
  final RxList<V2TimConversation> _conversationList = <V2TimConversation>[].obs;
  List<V2TimConversation> get conversationList => _conversationList;

  /// IM 黑名单用户 ID 列表
  final RxList<String> _blackListUserIDs = <String>[].obs;
  List<String> get blackListUserIDs => _blackListUserIDs;
  RxList<String> get blackListUserIDsRx => _blackListUserIDs;

  /// 未读消息总数
  final RxInt _totalUnreadCount = 0.obs;
  int get totalUnreadCount => _totalUnreadCount.value;
  RxInt get totalUnreadCountRx => _totalUnreadCount;

  final StorageService _storage = Get.find<StorageService>();

  // ============ 响应式消息流 ============
  /// 最新收到的消息（使用 ever 监听）
  final RxList<V2TimMessage> newMessages = <V2TimMessage>[].obs;

  /// 被服务端修改的消息（如翻译完成后后端修改 IM 消息），使用 ever 监听后更新本地 messageList
  final RxList<V2TimMessage> modifiedMessages = <V2TimMessage>[].obs;

  /// 消息已读回执
  final RxList<V2TimMessageReceipt> messageReadReceipts = <V2TimMessageReceipt>[].obs;

  // ============ 回调函数 ============
  /// 会话变更回调
  Function(List<V2TimConversation>)? onConversationChanged;

  /// 被踢下线回调
  Function()? onKickedOffline;

  /// UserSig 过期回调
  Function()? onUserSigExpired;

  /// 工作状态被设为离线时回调（仅 APP 重启/重新登录时触发），供 Work 页同步 UI
  Function()? onWorkStatusSetToOffByApp;

  /// 应用从后台回到前台时回调，供 Work 页等拉取远程在线/离线状态
  Function()? onAppResumedToForeground;

  /// 用户状态变更回调（需先 subscribeUserStatus 才会收到），供 Work 页等同步在线/离线/自定义状态
  Function(List<V2TimUserStatus>)? onUserStatusChanged;

  /// 切换到 Work Tab 时回调，供 Work 页拉取用户信息并同步腾讯在线状态
  Function()? onWorkTabSelected;

  // ============ 生命周期 ============

  @override
  void onInit() {
    super.onInit();
    _pushTokenChannel.setMethodCallHandler(_handlePushTokenCall);
  }

  @override
  void onClose() {
    unInitSDK();
    super.onClose();
  }

  Future<void> _handlePushTokenCall(MethodCall call) async {
    if (call.method != 'onPushToken') return;
    String token = '';
    final args = call.arguments;
    if (args is String) {
      token = args;
    } else if (args is Map && args['token'] is String) {
      token = args['token'] as String;
    }

    if (token.isEmpty) {
      debugPrint('[IMService] 收到空推送 Token，忽略');
      return;
    }
    await registerOfflinePushToken(token);
  }

  // ============ SDK 初始化 ============

  /// 初始化 SDK 并自动登录（如果已有用户信息）
  Future<bool> initAndAutoLogin({String? userID, String? userSig}) async {
    // 先初始化 SDK
    final initSuccess = await initSDK();
    if (!initSuccess) return false;

    // 如果提供了用户信息，自动登录
    if (userID != null && userSig != null && userID.isNotEmpty && userSig.isNotEmpty) {
      return await login(userID: userID, userSig: userSig);
    }

    return true;
  }

  /// 初始化 SDK
  Future<bool> initSDK({int? appID}) async {
    if (_isInitialized.value) {
      debugPrint('IM SDK 已初始化');
      return true;
    }

    final int targetAppID = appID ?? sdkAppID;
    if (targetAppID == 0) {
      debugPrint('错误: SDKAppID 未配置，当前值: $sdkAppID');
      debugPrint('请确保 AppConfigService 已加载配置');
      return false;
    }

    debugPrint('IM SDK 初始化中... AppID: $targetAppID, PushID: $pushId');

    // SDK 监听器
    V2TimSDKListener sdkListener = V2TimSDKListener(
      onConnectFailed: (int code, String error) {
        debugPrint('IM 连接失败: code=$code, error=$error');
        _connectionStatus.value = IMConnectionStatus.connectFailed;
      },
      onConnectSuccess: () {
        debugPrint('IM 连接成功');
        _connectionStatus.value = IMConnectionStatus.connected;
      },
      onConnecting: () {
        debugPrint('IM 正在连接...');
        _connectionStatus.value = IMConnectionStatus.connecting;
      },
      onKickedOffline: () {
        debugPrint('用户被踢下线');
        _isLoggedIn.value = false;
        _currentUserID = null;
        onKickedOffline?.call();
      },
      onSelfInfoUpdated: (V2TimUserFullInfo info) {
        debugPrint('用户信息更新: ${info.toJson()}');
        _currentUserInfo.value = info;
      },
      onUserSigExpired: () {
        debugPrint('UserSig 已过期');
        _isLoggedIn.value = false;
        onUserSigExpired?.call();
      },
      onUserStatusChanged: (List<V2TimUserStatus> userStatusList) {
        debugPrint('用户状态变更: ${userStatusList.length}个用户');
        onUserStatusChanged?.call(userStatusList);
      },
    );

    // 初始化 SDK
    V2TimValueCallback<bool> initResult = await TencentImSDKPlugin.v2TIMManager.initSDK(
      sdkAppID: targetAppID,
      loglevel: kDebugMode ? LogLevelEnum.V2TIM_LOG_ALL : LogLevelEnum.V2TIM_LOG_WARN,
      listener: sdkListener,
    );

    if (initResult.code == 0) {
      _isInitialized.value = true;
      debugPrint('IM SDK 初始化成功');

      // 根据当前前后台状态调整推送行为
      await _updateOfflinePushMode();
      if (_pendingPushToken != null) {
        final token = _pendingPushToken!;
        _pendingPushToken = null;
        await registerOfflinePushToken(token);
      }

      // 添加消息监听
      _addMessageListener();
      // 添加会话监听
      _addConversationListener();
      // 添加群组监听
      _addGroupListener();
      // 添加好友监听
      _addFriendshipListener();

      return true;
    } else {
      debugPrint('IM SDK 初始化失败: code=${initResult.code}, desc=${initResult.desc}');
      return false;
    }
  }

  /// 反初始化 SDK
  Future<void> unInitSDK() async {
    if (!_isInitialized.value) return;

    await TencentImSDKPlugin.v2TIMManager.unInitSDK();
    _isInitialized.value = false;
    _isLoggedIn.value = false;
    _currentUserID = null;
    _connectionStatus.value = IMConnectionStatus.disconnected;
    debugPrint('IM SDK 已反初始化');
  }

  // ============ 登录/登出 ============

  /// 登录
  Future<bool> login({required String userID, required String userSig}) async {
    if (!_isInitialized.value) {
      // SDK 未初始化，先初始化
      debugPrint('SDK 未初始化，正在初始化...');
      final initSuccess = await initSDK();
      if (!initSuccess) {
        debugPrint('错误: SDK 初始化失败');
        return false;
      }
    }

    debugPrint('IM 登录中... userID=$userID');

    V2TimCallback result = await TencentImSDKPlugin.v2TIMManager.login(userID: userID, userSig: userSig);
    if (result.code == 0) {
      _isLoggedIn.value = true;
      _currentUserID = userID;
      debugPrint('IM 登录成功: userID=$userID');

      // 获取会话列表
      await getConversationList();
      await loadBlackList();
      await _updateOfflinePushMode();
      // APP 重启或重新登录时设为不工作状态，并提示主播
      await _setSelfStatusOffWork(showOfflineToast: true);

      return true;
    } else {
      Future.delayed(Duration(seconds: 2), () {
        login(userID: userID, userSig: userSig);
      });
      debugPrint('IM 登录失败: code=${result.code}, desc=${result.desc}');
      return false;
    }
  }

  /// 登出
  Future<bool> logout() async {
    if (!_isLoggedIn.value) return true;

    await _setSelfStatusOffWork();
    V2TimCallback result = await TencentImSDKPlugin.v2TIMManager.logout();

    if (result.code == 0) {
      _isLoggedIn.value = false;
      _currentUserID = null;
      _conversationList.clear();
      _blackListUserIDs.clear();
      _totalUnreadCount.value = 0;
      if (kDebugMode) {
        print('IM 登出成功');
      }
      return true;
    } else {
      print('IM 登出失败: code=${result.code}, desc=${result.desc}');
      return false;
    }
  }

  /// [showOfflineToast] 为 true 时（APP 重启/重新登录）提示主播已下线，并通知 Work 页同步 UI
  Future<void> _setSelfStatusOffWork({bool showOfflineToast = false}) async {
    final authService = Get.find<AuthService>();
    if (!authService.isAuthenticated) {
      return;
    }
    try {
      await TencentImSDKPlugin.v2TIMManager.setSelfStatus(status: 'OffWork');
      if (showOfflineToast) {
        ToastUtils.showInfo('You are offline', title: 'Work Status');
        onWorkStatusSetToOffByApp?.call();
      }
    } catch (_) {
      // 忽略异常，登出后状态会刷新
    }
  }

  /// 当前主播是否已上线（工作状态为 OnWork），用于拨打前校验
  Future<bool> isCurrentUserOnWork() async {
    final userID = currentUserID;
    if (userID == null || userID.isEmpty) return false;
    try {
      final result = await TencentImSDKPlugin.v2TIMManager.getUserStatus(userIDList: [userID]);
      if (result.code == 0 && result.data != null && result.data!.isNotEmpty) {
        final customStatus = result.data!.first.customStatus ?? '';
        return customStatus == 'OnWork';
      }
    } catch (_) {}
    return false;
  }

  /// 设置当前主播为上线（OnWork），用于弹窗内确认上线后继续拨打
  Future<void> setCurrentUserOnWork() async {
    try {
      await TencentImSDKPlugin.v2TIMManager.setSelfStatus(status: 'OnWork');
    } catch (_) {}
  }

  // ============ 消息相关 ============

  /// 添加消息监听器
  void _addMessageListener() {
    TencentImSDKPlugin.v2TIMManager.getMessageManager().addAdvancedMsgListener(
      listener: V2TimAdvancedMsgListener(
        onRecvNewMessage: (V2TimMessage message) {
          debugPrint('[IMService] 收到新消息: ${message.msgID}');

          // 更新响应式变量，触发所有监听者
          newMessages.assignAll([message]);

          // 前台通知（顶部弹出）
          _maybeShowInAppBanner(message);
        },
        // onRecvMessageReadReceipts: (List<V2TimMessageReceipt> receiptList) {
        //   // print('消息已读回执: ${receiptList.length}条');
        //   // onRecvMessageReadReceipts?.call(receiptList);
        // },
        onRecvMessageRevoked: (String msgID) {
          debugPrint('[IMService] 消息被撤回: $msgID');
        },
        onRecvMessageModified: (V2TimMessage message) {
          debugPrint('[IMService] 消息被修改: ${message.msgID}');
          modifiedMessages.assignAll([message]);
        },
      ),
    );
  }

  /// 远程通知（离线推送）是否开启，默认 true
  bool get isRemoteNotificationEnabled => _storage.getBool(AppConstants.keyRemoteNotificationEnabled) ?? true;

  /// 设置远程通知开关并同步到 IM（保存到本地；开启时重新注册 Token）
  Future<void> updateRemoteNotificationEnabled(bool enabled) async {
    await _storage.setBool(AppConstants.keyRemoteNotificationEnabled, enabled);
    if (enabled && _lastPushToken != null && _isInitialized.value && _isLoggedIn.value) {
      await registerOfflinePushToken(_lastPushToken!, forceRegister: true);
    }
    await _updateOfflinePushMode();
  }

  /// 注册离线推送 Token（Android/iOS）
  /// 若用户关闭了远程通知开关，仅缓存 Token 不提交给 IM
  /// [forceRegister] 为 true 时忽略“已注册同一 Token”的跳过逻辑，用于用户重新开启远程通知时强制注册
  Future<void> registerOfflinePushToken(
    String token, {
    bool isTPNSToken = false,
    bool isVoip = false,
    bool forceRegister = false,
  }) async {
    if (token.isEmpty) return;
    if (!_isInitialized.value) {
      _pendingPushToken = token;
      return;
    }
    if (!isRemoteNotificationEnabled) {
      _lastPushToken = token;
      debugPrint('[IMService] 远程通知已关闭，仅缓存 Token');
      return;
    }
    if (!forceRegister && token == _lastPushToken) return;

    final int? businessId = int.tryParse(pushId);
    if (businessId == null || businessId <= 0) {
      debugPrint('[IMService] PushID 未配置或非法: $pushId');
      return;
    }

    final result = await TencentImSDKPlugin.v2TIMManager.getOfflinePushManager().setOfflinePushConfig(
      businessID: businessId.toDouble(),
      token: token,
      isTPNSToken: isTPNSToken,
      isVoip: isVoip,
    );

    if (result.code == 0) {
      _lastPushToken = token;
      debugPrint('[IMService] 推送 Token 注册成功');
    } else {
      debugPrint('[IMService] 推送 Token 注册失败: code=${result.code}, desc=${result.desc}');
    }
  }

  /// 设置当前活跃会话（用于前台消息免打扰）
  void setActiveConversation({String? userID, String? groupID}) {
    _activeChatUserID = userID;
    _activeChatGroupID = groupID;
  }

  /// 清除当前活跃会话
  void clearActiveConversation() {
    _activeChatUserID = null;
    _activeChatGroupID = null;
  }

  /// 更新 App 前后台状态（用于离线推送前后台切换）
  /// 不本地维护在线/离线：仅 APP 重启或重新登录时设为不工作；回到前台时通过 [onAppResumedToForeground] 由业务方拉取远程状态。
  /// 回到前台时会调用 [doForeground] 并检查 IM 登录状态，若已掉线则自动重登，避免收不到消息。
  Future<void> updateAppLifecycle(AppLifecycleState state) async {
    final bool isForeground = state == AppLifecycleState.resumed;
    final bool wasInForeground = _isAppInForeground.value;
    if (_isAppInForeground.value != isForeground) {
      _isAppInForeground.value = isForeground;
    }
    if (isForeground && !wasInForeground) {
      onAppResumedToForeground?.call();
    }
    await _updateOfflinePushMode();
    // 退后台后 TCP 长连接可能断开，回前台时检查登录状态，若 SDK 已未登录则重登以恢复收消息
    if (isForeground && !wasInForeground) {
      _tryReconnectOnResume();
    }
  }

  /// 回到前台时检查 IM 登录状态，若 SDK 返回未登录但本地认为已登录则重新登录（避免退后台后收不到消息）
  Future<void> _tryReconnectOnResume() async {
    if (!_isInitialized.value || !_isLoggedIn.value) return;
    try {
      final res = await TencentImSDKPlugin.v2TIMManager.getLoginStatus();
      if (res.code != 0 || res.data == null) return;
      // 1=已登录 2=登录中 3=未登录
      if (res.data == 3) {
        if (!Get.isRegistered<AuthService>()) return;
        final auth = Get.find<AuthService>();
        if (!auth.isAuthenticated || auth.tencentUserSig == null || auth.tencentUserSig!.isEmpty) return;
        final userId = auth.userId.toString();
        if (userId.isEmpty) return;
        debugPrint('[IMService] 回到前台检测到 IM 未登录，正在重新登录: userId=$userId');
        final ok = await login(userID: userId, userSig: auth.tencentUserSig!);
        if (ok) {
          debugPrint('[IMService] 回到前台重登成功');
        } else {
          debugPrint('[IMService] 回到前台重登失败');
        }
      }
    } catch (e) {
      debugPrint('[IMService] 回到前台检查登录状态异常: $e');
    }
  }

  Future<void> _updateOfflinePushMode() async {
    if (!_isInitialized.value || !_isLoggedIn.value) return;
    final manager = TencentImSDKPlugin.v2TIMManager.getOfflinePushManager();
    if (_isAppInForeground.value) {
      await manager.doForeground();
    } else {
      await manager.doBackground(unreadCount: _totalUnreadCount.value);
    }
  }

  /// 应用内通知（前台消息横幅）是否开启，默认 true
  bool get isInAppNotificationEnabled => _storage.getBool(AppConstants.keyInAppNotificationEnabled) ?? true;

  /// 来消息/来电铃声是否开启，默认 true
  bool get isSoundingEnabled => _storage.getBool(AppConstants.keySoundingEnabled) ?? true;

  /// 播放来消息提示音（仅在 isSoundingEnabled 时）
  void _playIncomingMessageSound() {
    if (!isSoundingEnabled) return;
    try {
      SystemSound.play(SystemSoundType.alert);
    } catch (e) {
      print(e);
    }
  }

  void _maybeShowInAppBanner(V2TimMessage message) {
    if (message.isSelf == true) return;
    if (!isInAppNotificationEnabled) return;
    if (_isBlockedSender(message)) return;
    if (!_isAppInForeground.value) return;
    if (_isInCall()) return;
    if (_isMessageInActiveConversation(message)) return;

    _playIncomingMessageSound();
    _showInAppBannerWithProfile(message);
  }

  Future<void> _showInAppBannerWithProfile(V2TimMessage message) async {
    final String? targetUserId = _extractMessageUserId(message);
    if (targetUserId == null || targetUserId.isEmpty) return;

    final UserModelEntity? userInfo = await _fetchUserInfo(targetUserId);
    final String nickname = userInfo?.nickname ?? '';
    if (nickname.isEmpty) return;

    if (!_isAppInForeground.value) return;
    if (_isInCall()) return;
    if (_isMessageInActiveConversation(message)) return;

    final preview = _buildMessagePreview(message);
    if (preview.isEmpty) return;

    ToastUtils.showInAppMessage(
      title: nickname,
      message: preview,
      avatarUrl: userInfo?.avatar,
      onTap: () {
        Get.toNamed(
          AppRoutes.messageChat,
          // arguments: {'conversationID': 'c2c_$targetUserId'},
          arguments: {
            'conversationID': 'c2c_$targetUserId',
            'userID': targetUserId,
            'groupID': null,
            'name': nickname,
            'avatar': userInfo?.avatar ?? '',
          },
        );
      },
    );
  }

  String? _extractMessageUserId(V2TimMessage message) {
    final String? userId = (message.userID?.isNotEmpty ?? false) ? message.userID : message.sender;
    return userId;
  }

  /// 是否拉黑用户（App 拉黑 + IM 黑名单）
  bool _isBlockedSender(V2TimMessage message) {
    final userId = _extractMessageUserId(message);
    if (userId == null || userId.isEmpty) return false;
    final idNum = int.tryParse(userId) ?? 0;
    if (idNum > 0 &&
        Get.isRegistered<BlockedUserService>() &&
        Get.find<BlockedUserService>().blockedUserIds.contains(idNum)) {
      return true;
    }
    return _blackListUserIDs.contains(userId);
  }

  Future<UserModelEntity?> _fetchUserInfo(String userId) async {
    if (_userInfoCache.containsKey(userId)) {
      return _userInfoCache[userId];
    }

    final int? targetUserId = int.tryParse(userId);
    if (targetUserId == null || targetUserId <= 0) return null;

    try {
      final info = await UserAPIService.shared.getUserDetail(targetUserId);
      _userInfoCache[userId] = info;
      return info;
    } catch (e) {
      debugPrint('[IMService] 获取用户详情失败: $e');
      return null;
    }
  }

  bool _isInCall() {
    if (!Get.isRegistered<CallService>()) return false;
    final callService = Get.find<CallService>();
    return callService.localCallStatus != LocalCallStatus.none;
  }

  bool _isMessageInActiveConversation(V2TimMessage message) {
    final String? senderId = (message.userID?.isNotEmpty ?? false) ? message.userID : message.sender;

    if (_activeChatUserID != null && _activeChatUserID!.isNotEmpty) {
      return senderId == _activeChatUserID;
    }
    if (_activeChatGroupID != null && _activeChatGroupID!.isNotEmpty) {
      return message.groupID == _activeChatGroupID;
    }
    return false;
  }

  String _buildMessagePreview(V2TimMessage message) {
    final int elemType = message.elemType ?? MessageElemType.V2TIM_ELEM_TYPE_NONE;
    switch (elemType) {
      case MessageElemType.V2TIM_ELEM_TYPE_TEXT:
        return message.textElem?.text ?? '';
      case MessageElemType.V2TIM_ELEM_TYPE_IMAGE:
        return '[Image]';
      case MessageElemType.V2TIM_ELEM_TYPE_SOUND:
        return '[Voice]';
      case MessageElemType.V2TIM_ELEM_TYPE_VIDEO:
        return '[Video]';
      case MessageElemType.V2TIM_ELEM_TYPE_FILE:
        return '[File]';
      case MessageElemType.V2TIM_ELEM_TYPE_CUSTOM:
        return _parseCustomMessage(message);
      case MessageElemType.V2TIM_ELEM_TYPE_FACE:
        return '[Sticker]';
      case MessageElemType.V2TIM_ELEM_TYPE_LOCATION:
        return '[Location]';
      case MessageElemType.V2TIM_ELEM_TYPE_MERGER:
        return '[Chat History]';
      default:
        return '[Message]';
    }
  }

  String _parseCustomMessage(V2TimMessage message) {
    final customElem = message.customElem;
    if (customElem == null) return '[Custom Message]';

    final data = customElem.data;
    if (data != null && data.contains('video_call')) {
      return '[Video Call]';
    }

    return '[Custom Message]';
  }

  /// 发送文本消息（通过服务端接口）
  Future<V2TimMessage?> sendTextMessage({required String text, required String receiver, bool isGroup = false}) async {
    try {
      // 生成 clientLocalId
      final clientLocalId = const Uuid().v4().substring(0, 8);

      // 构建请求参数，参照 JS 版本的 m_sendMessage 方法
      final Map<String, dynamic> params = {
        'msgType': 'TIMTextElem',
        'data': {
          'toUserId': receiver,
          'text': text,
          'clientLocalId': clientLocalId,
          'cloudCustomData': {'clientLocalId': clientLocalId},
        },
      };

      debugPrint('发送文本消息参数: $params');

      // 调用服务端发送消息接口
      final response = await MessageAPIService.shared.sendMessage(params);
      debugPrint('发送文本消息响应: $response');

      // 创建本地消息对象用于 UI 显示
      // 服务端发送成功后，腾讯IM会通过监听器推送消息，这里先创建一个本地消息用于即时显示
      // V2TimValueCallback<V2TimMsgCreateInfoResult> createResult = await TencentImSDKPlugin.v2TIMManager
      //     .getMessageManager()
      //     .createTextMessage(text: text);
      //
      // if (createResult.code == 0 && createResult.data?.messageInfo != null) {
      //   final message = createResult.data!.messageInfo!;
      //   // 标记消息为已发送状态
      //   return message;
      // }

      // 如果无法创建本地消息，返回 null 但发送已成功
      debugPrint('发送文本消息成功（通过服务端）');
      return null;
    } on APIException catch (e) {
      debugPrint('发送文本消息失败: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('发送文本消息失败: $e');
      return null;
    }
  }

  /// 发送图片消息
  Future<V2TimMessage?> sendImageMessage({
    required String imagePath,
    required String receiver,
    bool isGroup = false,
  }) async {
    // 创建图片消息
    V2TimValueCallback<V2TimMsgCreateInfoResult> createResult = await TencentImSDKPlugin.v2TIMManager
        .getMessageManager()
        .createImageMessage(imagePath: imagePath);

    if (createResult.code != 0 || createResult.data?.id == null) {
      print('创建图片消息失败: ${createResult.desc}');
      return null;
    }

    // 发送消息
    V2TimValueCallback<V2TimMessage> sendResult = await TencentImSDKPlugin.v2TIMManager.getMessageManager().sendMessage(
      id: createResult.data!.id!,
      receiver: isGroup ? '' : receiver,
      groupID: isGroup ? receiver : '',
      priority: MessagePriorityEnum.V2TIM_PRIORITY_NORMAL,
    );

    if (sendResult.code == 0) {
      print('发送图片消息成功');
      return sendResult.data;
    } else {
      print('发送图片消息失败: ${sendResult.desc}');
      return null;
    }
  }

  /// 发送语音消息
  Future<V2TimMessage?> sendSoundMessage({
    required String soundPath,
    required int duration,
    required String receiver,
    bool isGroup = false,
  }) async {
    // 创建语音消息
    V2TimValueCallback<V2TimMsgCreateInfoResult> createResult = await TencentImSDKPlugin.v2TIMManager
        .getMessageManager()
        .createSoundMessage(soundPath: soundPath, duration: duration);

    if (createResult.code != 0 || createResult.data?.id == null) {
      print('创建语音消息失败: ${createResult.desc}');
      return null;
    }

    // 发送消息
    V2TimValueCallback<V2TimMessage> sendResult = await TencentImSDKPlugin.v2TIMManager.getMessageManager().sendMessage(
      id: createResult.data!.id!,
      receiver: isGroup ? '' : receiver,
      groupID: isGroup ? receiver : '',
      priority: MessagePriorityEnum.V2TIM_PRIORITY_NORMAL,
    );

    if (sendResult.code == 0) {
      print('发送语音消息成功');
      return sendResult.data;
    } else {
      print('发送语音消息失败: ${sendResult.desc}');
      return null;
    }
  }

  /// 发送视频消息
  Future<V2TimMessage?> sendVideoMessage({
    required String videoPath,
    required String snapshotPath,
    required int duration,
    required String receiver,
    bool isGroup = false,
  }) async {
    // 创建视频消息
    V2TimValueCallback<V2TimMsgCreateInfoResult> createResult = await TencentImSDKPlugin.v2TIMManager
        .getMessageManager()
        .createVideoMessage(videoFilePath: videoPath, snapshotPath: snapshotPath, duration: duration, type: 'mp4');

    if (createResult.code != 0 || createResult.data?.id == null) {
      print('创建视频消息失败: ${createResult.desc}');
      return null;
    }

    // 发送消息
    V2TimValueCallback<V2TimMessage> sendResult = await TencentImSDKPlugin.v2TIMManager.getMessageManager().sendMessage(
      id: createResult.data!.id!,
      receiver: isGroup ? '' : receiver,
      groupID: isGroup ? receiver : '',
      priority: MessagePriorityEnum.V2TIM_PRIORITY_NORMAL,
    );

    if (sendResult.code == 0) {
      print('发送视频消息成功');
      return sendResult.data;
    } else {
      print('发送视频消息失败: ${sendResult.desc}');
      return null;
    }
  }

  /// 发送文件消息
  Future<V2TimMessage?> sendFileMessage({
    required String filePath,
    required String fileName,
    required String receiver,
    bool isGroup = false,
  }) async {
    // 创建文件消息
    V2TimValueCallback<V2TimMsgCreateInfoResult> createResult = await TencentImSDKPlugin.v2TIMManager
        .getMessageManager()
        .createFileMessage(filePath: filePath, fileName: fileName);

    if (createResult.code != 0 || createResult.data?.id == null) {
      print('创建文件消息失败: ${createResult.desc}');
      return null;
    }

    // 发送消息
    V2TimValueCallback<V2TimMessage> sendResult = await TencentImSDKPlugin.v2TIMManager.getMessageManager().sendMessage(
      id: createResult.data!.id!,
      receiver: isGroup ? '' : receiver,
      groupID: isGroup ? receiver : '',
      priority: MessagePriorityEnum.V2TIM_PRIORITY_NORMAL,
    );

    if (sendResult.code == 0) {
      print('发送文件消息成功');
      return sendResult.data;
    } else {
      print('发送文件消息失败: ${sendResult.desc}');
      return null;
    }
  }

  /// 发送自定义消息
  Future<V2TimMessage?> sendCustomMessage({
    required String data,
    String? description,
    String? extension,
    required String receiver,
    bool isGroup = false,
  }) async {
    // 创建自定义消息
    V2TimValueCallback<V2TimMsgCreateInfoResult> createResult = await TencentImSDKPlugin.v2TIMManager
        .getMessageManager()
        .createCustomMessage(data: data, desc: description ?? '', extension: extension ?? '');

    if (createResult.code != 0 || createResult.data?.id == null) {
      print('创建自定义消息失败: ${createResult.desc}');
      return null;
    }

    // 发送消息
    V2TimValueCallback<V2TimMessage> sendResult = await TencentImSDKPlugin.v2TIMManager.getMessageManager().sendMessage(
      id: createResult.data!.id!,
      receiver: isGroup ? '' : receiver,
      groupID: isGroup ? receiver : '',
      priority: MessagePriorityEnum.V2TIM_PRIORITY_NORMAL,
    );

    if (sendResult.code == 0) {
      print('发送自定义消息成功');
      return sendResult.data;
    } else {
      print('发送自定义消息失败: ${sendResult.desc}');
      return null;
    }
  }

  /// 获取历史消息
  Future<List<V2TimMessage>> getHistoryMessageList({
    required String userID,
    bool isGroup = false,
    int count = 20,
    V2TimMessage? lastMsg,
  }) async {
    V2TimValueCallback<List<V2TimMessage>> result = await TencentImSDKPlugin.v2TIMManager
        .getMessageManager()
        .getHistoryMessageList(
          count: count,
          getType: HistoryMsgGetTypeEnum.V2TIM_GET_LOCAL_OLDER_MSG, // 1: C2C, 3: Group
          userID: isGroup ? null : userID,
          groupID: isGroup ? userID : null,
          lastMsgID: lastMsg?.msgID,
        );

    if (result.code == 0) {
      return result.data ?? [];
    } else {
      print('获取历史消息失败: ${result.desc}');
      return [];
    }
  }

  /// 撤回消息
  Future<bool> revokeMessage(V2TimMessage message) async {
    if (message.msgID == null) return false;

    V2TimCallback result = await TencentImSDKPlugin.v2TIMManager.getMessageManager().revokeMessage(
      msgID: message.msgID!,
    );

    if (result.code == 0) {
      print('撤回消息成功');
      return true;
    } else {
      print('撤回消息失败: ${result.desc}');
      return false;
    }
  }

  /// 删除消息
  Future<bool> deleteMessages(List<V2TimMessage> messages) async {
    List<String> msgIDs = messages.where((msg) => msg.msgID != null).map((msg) => msg.msgID!).toList();

    if (msgIDs.isEmpty) return false;

    V2TimCallback result = await TencentImSDKPlugin.v2TIMManager.getMessageManager().deleteMessages(msgIDs: msgIDs);

    if (result.code == 0) {
      print('删除消息成功');
      return true;
    } else {
      print('删除消息失败: ${result.desc}');
      return false;
    }
  }

  /// 标记消息已读 - C2C
  Future<bool> markC2CMessageAsRead(String userID) async {
    V2TimCallback result = await TencentImSDKPlugin.v2TIMManager.getMessageManager().markC2CMessageAsRead(
      userID: userID,
    );

    if (result.code == 0) {
      print('标记C2C消息已读成功');
      return true;
    } else {
      print('标记C2C消息已读失败: ${result.desc}');
      return false;
    }
  }

  /// 标记消息已读 - 群组
  Future<bool> markGroupMessageAsRead(String groupID) async {
    V2TimCallback result = await TencentImSDKPlugin.v2TIMManager.getMessageManager().markGroupMessageAsRead(
      groupID: groupID,
    );

    if (result.code == 0) {
      print('标记群消息已读成功');
      return true;
    } else {
      print('标记群消息已读失败: ${result.desc}');
      return false;
    }
  }

  // ============ 会话相关 ============

  /// 添加会话监听器
  void _addConversationListener() {
    TencentImSDKPlugin.v2TIMManager.getConversationManager().addConversationListener(
      listener: V2TimConversationListener(
        onConversationChanged: (List<V2TimConversation> conversationList) {
          print('会话变更: ${conversationList.length}个');
          _updateConversationList(conversationList);
          // 已过滤列表在 _updateConversationList 内通过 onConversationChanged 回调
        },
        onNewConversation: (List<V2TimConversation> conversationList) {
          print('新会话: ${conversationList.length}个');
          _updateConversationList(conversationList);
        },
        onTotalUnreadMessageCountChanged: (int totalUnreadCount) {
          print('未读消息总数变更: $totalUnreadCount');
          _totalUnreadCount.value = totalUnreadCount;
        },
      ),
    );
  }

  /// 过滤掉黑名单用户的会话
  List<V2TimConversation> _filterBlockedConversations(List<V2TimConversation> list) {
    final blocked = Get.isRegistered<BlockedUserService>() ? Get.find<BlockedUserService>().blockedUserIds : <int>[];
    return list.where((c) {
      final userId = c.userID;
      if (userId == null || userId.isEmpty) return true;
      final idNum = int.tryParse(userId) ?? 0;
      if (idNum > 0 && blocked.contains(idNum)) return false;
      if (_blackListUserIDs.contains(userId)) return false;
      return true;
    }).toList();
  }

  /// 更新会话列表
  void _updateConversationList(List<V2TimConversation> updatedList) {
    for (var conv in updatedList) {
      int index = _conversationList.indexWhere((c) => c.conversationID == conv.conversationID);
      if (index >= 0) {
        _conversationList[index] = conv;
      } else {
        _conversationList.add(conv);
      }
    }
    // 过滤黑名单用户
    _conversationList.assignAll(_filterBlockedConversations(_conversationList));
    var unreadCount = 0;
    for (final con in _conversationList) {
      unreadCount += (con.unreadCount ?? 0);
    }
    _totalUnreadCount.value = unreadCount;
    debugPrint("read:$unreadCount");
    // 按最后消息时间排序
    _conversationList.sort((a, b) {
      int timeA = a.lastMessage?.timestamp ?? 0;
      int timeB = b.lastMessage?.timestamp ?? 0;
      return timeB.compareTo(timeA);
    });
    // 回调时传递已过滤的列表
    onConversationChanged?.call(List.from(_conversationList));
  }

  /// 获取会话列表
  Future<List<V2TimConversation>> getConversationList({int count = 100, String nextSeq = '0'}) async {
    V2TimValueCallback<V2TimConversationResult> result = await TencentImSDKPlugin.v2TIMManager
        .getConversationManager()
        .getConversationList(count: count, nextSeq: nextSeq);

    if (result.code == 0 && result.data != null) {
      _conversationList.value = result.data?.conversationList ?? [];
      _conversationList.assignAll(_filterBlockedConversations(_conversationList));
      return _conversationList;
    } else {
      print('获取会话列表失败: ${result.desc}');
      return [];
    }
  }

  /// 删除会话
  Future<bool> deleteConversation(String conversationID) async {
    V2TimCallback result = await TencentImSDKPlugin.v2TIMManager.getConversationManager().deleteConversation(
      conversationID: conversationID,
    );

    if (result.code == 0) {
      _conversationList.removeWhere((c) => c.conversationID == conversationID);
      print('删除会话成功');
      return true;
    } else {
      print('删除会话失败: ${result.desc}');
      return false;
    }
  }

  /// 置顶会话
  Future<bool> pinConversation({required String conversationID, required bool isPinned}) async {
    V2TimCallback result = await TencentImSDKPlugin.v2TIMManager.getConversationManager().pinConversation(
      conversationID: conversationID,
      isPinned: isPinned,
    );

    if (result.code == 0) {
      print('${isPinned ? "置顶" : "取消置顶"}会话成功');
      return true;
    } else {
      print('${isPinned ? "置顶" : "取消置顶"}会话失败: ${result.desc}');
      return false;
    }
  }

  // ============ 群组相关 ============

  /// 添加群组监听器
  void _addGroupListener() {
    TencentImSDKPlugin.v2TIMManager.setGroupListener(
      listener: V2TimGroupListener(
        onMemberEnter: (String groupID, List<dynamic> memberList) {
          print('群成员加入: groupID=$groupID');
        },
        onMemberLeave: (String groupID, dynamic member) {
          print('群成员离开: groupID=$groupID');
        },
        onMemberKicked: (String groupID, dynamic opUser, List<dynamic> memberList) {
          print('群成员被踢: groupID=$groupID');
        },
        onGroupDismissed: (String groupID, dynamic opUser) {
          print('群组解散: groupID=$groupID');
        },
        onGroupRecycled: (String groupID, dynamic opUser) {
          print('群组被回收: groupID=$groupID');
        },
        onGroupInfoChanged: (String groupID, List<dynamic> changeInfos) {
          print('群信息变更: groupID=$groupID');
        },
        onReceiveJoinApplication: (String groupID, dynamic member, String opReason) {
          print('收到入群申请: groupID=$groupID');
        },
      ),
    );
  }

  /// 加入群组
  Future<bool> joinGroup({required String groupID, String? message}) async {
    V2TimCallback result = await TencentImSDKPlugin.v2TIMManager.joinGroup(groupID: groupID, message: message ?? '');

    if (result.code == 0) {
      print('加入群组成功');
      return true;
    } else {
      print('加入群组失败: ${result.desc}');
      return false;
    }
  }

  /// 退出群组
  Future<bool> quitGroup(String groupID) async {
    V2TimCallback result = await TencentImSDKPlugin.v2TIMManager.quitGroup(groupID: groupID);

    if (result.code == 0) {
      print('退出群组成功');
      return true;
    } else {
      print('退出群组失败: ${result.desc}');
      return false;
    }
  }

  /// 解散群组
  Future<bool> dismissGroup(String groupID) async {
    V2TimCallback result = await TencentImSDKPlugin.v2TIMManager.dismissGroup(groupID: groupID);

    if (result.code == 0) {
      print('解散群组成功');
      return true;
    } else {
      print('解散群组失败: ${result.desc}');
      return false;
    }
  }

  // ============ 好友相关 ============

  /// 添加好友监听器
  void _addFriendshipListener() {
    TencentImSDKPlugin.v2TIMManager.getFriendshipManager().addFriendListener(
      listener: V2TimFriendshipListener(
        onFriendApplicationListAdded: (List<dynamic> applicationList) {
          print('收到好友申请: ${applicationList.length}个');
        },
        onFriendListAdded: (List<dynamic> users) {
          print('好友列表新增: ${users.length}个');
        },
        onFriendListDeleted: (List<String> userIDList) {
          print('好友列表删除: ${userIDList.length}个');
        },
        onBlackListAdd: (List<dynamic> infoList) {
          for (final info in infoList) {
            final userId = _extractBlackListUserId(info);
            if (userId != null && userId.isNotEmpty && !_blackListUserIDs.contains(userId)) {
              _blackListUserIDs.add(userId);
            }
          }
          print('黑名单新增');
        },
        onBlackListDeleted: (List<String> userIDList) {
          for (final userId in userIDList) {
            _blackListUserIDs.remove(userId);
          }
          print('黑名单删除');
        },
        onFriendInfoChanged: (List<dynamic> infoList) {
          print('好友信息变更');
        },
      ),
    );
  }

  /// 获取黑名单列表
  Future<void> loadBlackList() async {
    try {
      V2TimValueCallback<List<dynamic>> result = await TencentImSDKPlugin.v2TIMManager
          .getFriendshipManager()
          .getBlackList();
      if (result.code == 0) {
        final ids = <String>[];
        for (final info in result.data ?? []) {
          final userId = _extractBlackListUserId(info);
          if (userId != null && userId.isNotEmpty) ids.add(userId);
        }
        _blackListUserIDs.assignAll(ids);
      } else {
        _blackListUserIDs.clear();
      }
    } catch (_) {
      _blackListUserIDs.clear();
    }
  }

  String? _extractBlackListUserId(dynamic info) {
    if (info == null) return null;
    if (info is String) return info;
    if (info is Map) {
      final v = info['userID'] ?? info['userId'] ?? info['id'];
      return v?.toString();
    }
    final dynamic data = info;
    final dynamic v = data.userID ?? data.userId;
    if (v == null) return null;
    return v.toString();
  }

  /// 获取好友列表
  Future<List<dynamic>> getFriendList() async {
    V2TimValueCallback<List<dynamic>> result = await TencentImSDKPlugin.v2TIMManager
        .getFriendshipManager()
        .getFriendList();

    if (result.code == 0) {
      return result.data ?? [];
    } else {
      print('获取好友列表失败: ${result.desc}');
      return [];
    }
  }

  /// 添加好友
  Future<bool> addFriend({required String userID, String? remark, String? addWording}) async {
    V2TimValueCallback<dynamic> result = await TencentImSDKPlugin.v2TIMManager.getFriendshipManager().addFriend(
      userID: userID,
      addType: FriendTypeEnum.V2TIM_FRIEND_TYPE_SINGLE, // 1: 单向加好友
      remark: remark,
      addWording: addWording,
    );

    if (result.code == 0) {
      print('添加好友成功');
      return true;
    } else {
      print('添加好友失败: ${result.desc}');
      return false;
    }
  }

  /// 删除好友
  Future<bool> deleteFriend(String userID) async {
    V2TimValueCallback<List<dynamic>> result = await TencentImSDKPlugin.v2TIMManager
        .getFriendshipManager()
        .deleteFromFriendList(
          userIDList: [userID],
          deleteType: FriendTypeEnum.V2TIM_FRIEND_TYPE_BOTH, // 2: 双向删除
        );

    if (result.code == 0) {
      print('删除好友成功');
      return true;
    } else {
      print('删除好友失败: ${result.desc}');
      return false;
    }
  }

  // ============ 用户资料相关 ============

  /// 获取用户资料
  Future<List<V2TimUserFullInfo>> getUsersInfo(List<String> userIDList) async {
    V2TimValueCallback<List<V2TimUserFullInfo>> result = await TencentImSDKPlugin.v2TIMManager.getUsersInfo(
      userIDList: userIDList,
    );

    if (result.code == 0) {
      return result.data ?? [];
    } else {
      print('获取用户资料失败: ${result.desc}');
      return [];
    }
  }

  /// 设置自己的资料
  Future<bool> setSelfInfo({String? nickName, String? faceUrl, int? gender, String? selfSignature}) async {
    V2TimCallback result = await TencentImSDKPlugin.v2TIMManager.setSelfInfo(
      userFullInfo: V2TimUserFullInfo(
        nickName: nickName,
        faceUrl: faceUrl,
        gender: gender,
        selfSignature: selfSignature,
      ),
    );

    if (result.code == 0) {
      print('设置资料成功');
      return true;
    } else {
      print('设置资料失败: ${result.desc}');
      return false;
    }
  }
}

/// IM 连接状态
enum IMConnectionStatus {
  /// 已断开连接
  disconnected,

  /// 正在连接
  connecting,

  /// 已连接
  connected,

  /// 连接失败
  connectFailed,
}

/// 消息已读回执 (简化模型)
class V2TimMessageReceipt {
  final String? msgID;
  final String? userID;
  final int? timestamp;

  V2TimMessageReceipt({this.msgID, this.userID, this.timestamp});
}
