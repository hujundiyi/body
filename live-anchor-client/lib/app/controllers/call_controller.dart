import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_message.dart';
import 'package:tencent_rtc_sdk/trtc_cloud_def.dart';
import 'package:weeder/core/constants/call_constants.dart';
import 'package:weeder/core/network/anchor_api_service.dart';
import 'package:weeder/core/network/api_services.dart';
import 'package:weeder/core/services/auth_service.dart';
import 'package:weeder/core/services/call_service.dart';
import 'package:weeder/core/services/im_service.dart';
import 'package:weeder/core/services/translation_service.dart';
import 'package:weeder/core/services/trtc_service.dart';
import 'package:weeder/core/utils/toast_utils.dart';
import 'package:weeder/data/models/call_data_model.dart';
import 'package:weeder/data/models/user_model_entity.dart';

/// 通话页面控制器
/// 管理通话页面的状态和交互
class CallController extends GetxController {
  // ============ 服务引用 ============
  CallService get _callService => Get.find<CallService>();
  AuthService get _authService => Get.find<AuthService>();
  TRTCService get _trtcService => Get.find<TRTCService>();
  IMService get _imService => Get.find<IMService>();
  TranslationService get _translationService => Get.find<TranslationService>();

  // ============ 聊天相关 ============
  /// 消息列表
  final RxList<V2TimMessage> messageList = <V2TimMessage>[].obs;

  /// 输入框控制器
  final TextEditingController textController = TextEditingController();

  /// 滚动控制器
  final ScrollController chatScrollController = ScrollController();

  /// 是否正在发送消息
  final RxBool isSendingMessage = false.obs;

  /// 是否显示聊天面板
  final RxBool showChatPanel = true.obs;

  // ============ 页面状态 ============
  /// 本地视频 viewId
  final RxnInt localViewId = RxnInt(null);
  
  /// 远端视频 viewId
  final RxnInt remoteViewId = RxnInt(null);

  /// 全屏区域 viewId（固定，用于切换时重新绑定）
  final RxnInt fullScreenViewId = RxnInt(null);

  /// 小窗区域 viewId（固定，用于切换时重新绑定）
  final RxnInt smallViewId = RxnInt(null);

  /// 远端视频是否就绪
  final RxBool isRemoteVideoReady = false.obs;

  /// 是否交换本地和远端视频位置
  final RxBool isVideoSwapped = false.obs;

  /// 挂断按钮是否禁用（进入页面5秒内禁用）
  final RxBool isHangupDisabled = true.obs;

  /// 是否显示设置面板
  final RxBool showSettings = false.obs;

  /// 是否显示充值提醒
  final RxBool showRechargeReminder = false.obs;

  /// 充值提醒是否展开
  final RxBool rechargeReminderExpanded = true.obs;

  /// 充值倒计时（秒）
  final RxInt rechargeCountdown = 60.obs;

  /// 是否初始化完成
  final RxBool isInitialized = false.obs;

  // ============ 计时器与监听 ============
  Timer? _hangupDisableTimer;
  Timer? _rechargeTimer;
  Timer? _rechargeCollapseTimer;
  Worker? _messageWorker;
  Worker? _modifiedMessageWorker;

  // ============ 便捷访问器 ============
  CallData? get callData => _callService.callData;
  UserModelEntity? get remoteUserInfo => _callService.remoteUserInfo;
  CallStatusChangeMessage? get endCallData => _callService.endCallData;
  Rx<LocalCallStatus> get localCallStatusRx => _callService.localCallStatusRx;
  LocalCallStatus get localCallStatus => _callService.localCallStatus;
  bool get isCameraEnabled => _callService.isCameraEnabled;
  bool get isMicrophoneEnabled => _callService.isMicrophoneEnabled;
  bool get isFrontCamera => _callService.isFrontCamera;
  String get formattedCallDuration => _callService.formattedCallDuration;
  int get callStartTime => _callService.callStartTime;
  bool get isRemoteVideoAvailable => _trtcService.isRemoteVideoReady;

  /// 远端用户ID列表
  List<String> get remoteUsers => _trtcService.remoteUsers;

  /// 当前远端用户ID
  String? get remoteUserId => remoteUsers.isNotEmpty ? remoteUsers.first : null;

  @override
  void onInit() {
    super.onInit();
    debugPrint('[CallController] onInit');
    _setupCallServiceCallbacks();
    _setupTRTCCallbacks();
    _setupIMListener();
  }

  @override
  void onReady() {
    super.onReady();
    debugPrint('[CallController] onReady');
    _initializeCall();
    _fetchRemoteUserDetail();
  }

  /// 进入页面后拉取一次用户详情（含 follow 状态），覆盖通话中仅含基础信息的远端用户数据
  void _fetchRemoteUserDetail() {
    final userId = remoteUserInfo?.userId;
    if (userId == null || userId == 0) return;
    UserAPIService.shared.getUserDetail(userId).then((detail) {
      _callService.setRemoteUserInfo(detail);
      debugPrint('[CallController] 已刷新远端用户详情（含 follow 状态）');
    }).catchError((e) {
      debugPrint('[CallController] 获取远端用户详情失败: $e');
    });
  }

  /// 设置 CallService 回调
  void _setupCallServiceCallbacks() {
    _callService.onCallEnded = (endData) {
      debugPrint('[CallController] 通话结束');
      // 通话结束，页面会通过状态变化自动更新
    };

    _callService.onRemoteVideoReady = () {
      debugPrint('[CallController] 远端视频就绪');
      isRemoteVideoReady.value = true;
    };

    _callService.onBalanceWarning = (remainingSeconds) {
      debugPrint('[CallController] 余额不足提醒: ${remainingSeconds}秒');
      _showRechargeReminder(remainingSeconds);
    };
  }

  /// 设置 TRTC 回调
  void _setupTRTCCallbacks() {
    _trtcService.onUserVideoAvailable = (userId, streamType) {
      debugPrint('[CallController] 远端用户视频可用: userId=$userId');
      // 自动开始渲染远端视频
      if (remoteViewId.value != null) {
        startRemoteView(userId, remoteViewId.value!);
      }
    };

    _trtcService.onRemoteUserLeaveRoom = (userId, reason) {
      debugPrint('[CallController] 远端用户离开: userId=$userId');
      isRemoteVideoReady.value = false;
    };

    _trtcService.onFirstVideoFrame = (userId, streamType, width, height) {
      if (userId.isNotEmpty && userId != _trtcService.currentUserId) {
        debugPrint('[CallController] 收到远端首帧: userId=$userId');
        isRemoteVideoReady.value = true;
      }
    };
  }

  /// 设置 IM 消息监听
  void _setupIMListener() {
    debugPrint('[CallController] 设置 IM 消息监听');

    _messageWorker = ever(_imService.newMessages, (messages) {
      for (final message in messages) {
        // 只接收来自当前通话对方的消息
        final remoteId = remoteUserInfo?.userId.toString();
        if (remoteId != null && (message.userID == remoteId || message.sender == remoteId)) {
          messageList.add(message);
          _scrollChatToBottom();
        }
      }
    });

    // 后端修改消息（如翻译完成写入 IM）时，更新通话页 messageList 中对应消息
    _modifiedMessageWorker = ever(_imService.modifiedMessages, (messages) {
      final remoteId = remoteUserInfo?.userId.toString();
      if (remoteId == null) return;
      for (final message in messages) {
        if (message.userID != remoteId && message.sender != remoteId) continue;
        final msgID = message.msgID;
        if (msgID == null || msgID.isEmpty) continue;
        final index = messageList.indexWhere((m) => m.msgID == msgID);
        if (index >= 0) {
          messageList[index] = message;
        }
      }
    });
  }

  /// 移除 IM 消息监听
  void _removeIMListener() {
    debugPrint('[CallController] 移除 IM 消息监听');
    _modifiedMessageWorker?.dispose();
    _modifiedMessageWorker = null;
    _messageWorker?.dispose();
    _messageWorker = null;
  }

  // ============ 聊天操作 ============

  /// 发送文本消息
  Future<void> sendTextMessage() async {
    final text = textController.text.trim();
    if (text.isEmpty || isSendingMessage.value) return;

    final targetUserId = remoteUserInfo?.userId.toString();
    if (targetUserId == null) {
      ToastUtils.showError('Unable to send message');
      return;
    }

    isSendingMessage.value = true;
    textController.clear();

    try {
      final message = await _imService.sendTextMessage(
        text: text,
        receiver: targetUserId,
        isGroup: false,
      );

      if (message != null) {
        messageList.add(message);
        _scrollChatToBottom();
      }
    } catch (e) {
      debugPrint('[CallController] 发送消息失败: $e');
      ToastUtils.showError('Failed to send message');
    } finally {
      isSendingMessage.value = false;
    }
  }

  /// 滚动聊天到底部
  void _scrollChatToBottom() {
    if (chatScrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        chatScrollController.animateTo(
          chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      });
    }
  }

  /// 切换聊天面板显示
  void toggleChatPanel() {
    showChatPanel.value = !showChatPanel.value;
  }

  // ============ 翻译相关（使用 TranslationService）============

  /// 翻译消息
  Future<void> translateMessage(V2TimMessage message) async {
    final toUserId = remoteUserInfo?.userId?.toString();
    await _translationService.translateMessage(message, toUserId: toUserId);
  }

  /// 检查消息是否正在翻译
  bool isTranslating(String msgId) => _translationService.isTranslating(msgId);


  /// 是否已关注（userStatus/followStatus 返回 2 或 3 表示已关注）
  bool get isFollowing =>
      remoteUserInfo?.following == 2 || remoteUserInfo?.following == 3;

  /// 关注/取消关注：调用 userStatus/followStatus，成功后更新远端用户状态
  Future<void> toggleFollow() async {
    final info = remoteUserInfo;
    if (info == null || info.userId == 0) return;
    final follow = !isFollowing;
    try {
      final newState = await AnchorAPIService.shared.followStatus(
        followUserId: info.userId,
        follow: follow,
      );
      if (info.userId != null && remoteUserInfo?.userId == info.userId) {
        _callService.setRemoteUserInfo(
          info.copyWith(following: newState ?? (follow ? 2 : 0)),
        );
      }
      ToastUtils.showSuccess(follow ? 'Following' : 'Unfollowed');
    } catch (e) {
      ToastUtils.showError('Operation failed');
    }
  }

  /// 初始化通话
  Future<void> _initializeCall() async {
    debugPrint('[CallController] 初始化通话');

    // 检查通话状态
    if (_callService.localCallStatus != LocalCallStatus.calling) {
      debugPrint('[CallController] 通话状态异常，返回上一页');
      Get.back();
      return;
    }

    // 5秒后启用挂断按钮
    _hangupDisableTimer = Timer(
      const Duration(milliseconds: CallConfig.hangupDisableTime),
      () {
        isHangupDisabled.value = false;
      },
    );

    // 进入通话房间
    final success = await _callService.enterCallRoom();
    if (success) {
      isInitialized.value = true;
      debugPrint('[CallController] 通话初始化成功');
    } else {
      debugPrint('[CallController] 通话初始化失败');
      ToastUtils.showError('Failed to initialize video call');
      Get.back();
    }
  }

  // ============ 视频操作 ============

  /// 设置本地视频 viewId 并开始预览
  Future<void> setLocalViewId(int viewId) async {
    debugPrint('[CallController] 设置本地视频 viewId: $viewId');
    localViewId.value = viewId;
    await _callService.startLocalPreview(viewId);
  }

  /// 设置远端视频 viewId
  void setRemoteViewId(int viewId) {
    debugPrint('[CallController] 设置远端视频 viewId: $viewId');
    remoteViewId.value = viewId;
    
    // 如果已有远端用户，立即开始渲染
    if (remoteUserId != null) {
      startRemoteView(remoteUserId!, viewId);
    }
  }

  /// 设置全屏区域 viewId（固定视图，切换时通过 update 重绑定）
  Future<void> setFullScreenViewId(int viewId) async {
    debugPrint('[CallController] 设置全屏区域 viewId: $viewId');
    fullScreenViewId.value = viewId;
    await _applyVideoBindings();
  }

  /// 设置小窗区域 viewId（固定视图，切换时通过 update 重绑定）
  Future<void> setSmallViewId(int viewId) async {
    debugPrint('[CallController] 设置小窗区域 viewId: $viewId');
    smallViewId.value = viewId;
    await _applyVideoBindings();
  }

  /// 根据 isVideoSwapped 状态应用视频绑定
  Future<void> _applyVideoBindings() async {
    final fullId = fullScreenViewId.value;
    final smallId = smallViewId.value;
    if (fullId == null || smallId == null) return;

    final userId = remoteUserId;

    if (isVideoSwapped.value) {
      // 全屏显示本地，小窗显示远端
      localViewId.value = fullId;
      remoteViewId.value = smallId;
      await _callService.startLocalPreview(fullId);
      if (userId != null) {
        _callService.startRemoteView(userId, smallId);
      }
    } else {
      // 全屏显示远端，小窗显示本地
      localViewId.value = smallId;
      remoteViewId.value = fullId;
      await _callService.startLocalPreview(smallId);
      if (userId != null) {
        _callService.startRemoteView(userId, fullId);
      }
    }
    debugPrint('[CallController] 应用视频绑定: swapped=${isVideoSwapped.value}');
  }

  /// 开始渲染远端视频
  Future<void> startRemoteView(String userId, int viewId) async {
    debugPrint('[CallController] 开始渲染远端视频: userId=$userId, viewId=$viewId');
    await _callService.startRemoteView(userId, viewId);
  }

  // ============ 控制操作 ============

  /// 切换摄像头开关
  Future<void> toggleCamera() async {
    await _callService.setCameraEnabled(!isCameraEnabled);
  }

  /// 切换麦克风开关
  Future<void> toggleMicrophone() async {
    await _callService.setMicrophoneEnabled(!isMicrophoneEnabled);
  }

  /// 切换前后摄像头
  Future<void> switchCamera() async {
    await _callService.switchCamera();
  }

  /// 点击挂断按钮
  void onHangupClick() {
    if (isHangupDisabled.value) return;

    Get.defaultDialog(
      title: 'End Video Chat',
      middleText: 'Are you sure you want to end this video chat?',
      textConfirm: 'End Video Chat',
      textCancel: 'Cancel',
      confirmTextColor: Get.theme.colorScheme.onPrimary,
      onConfirm: () {
        Get.back(); // 关闭对话框
        endCall();
      },
    );
  }

  /// 结束通话
  Future<void> endCall() async {
    debugPrint('[CallController] 结束通话');
    await _callService.endCall(status: CallStatus.callDone);
  }

  /// 切换设置面板
  void toggleSettings() {
    showSettings.value = !showSettings.value;
  }

  /// 关闭设置面板
  void closeSettings() {
    showSettings.value = false;
  }

  /// 切换本地和远端视频位置
  Future<void> toggleVideoSwap() async {
    final fullId = fullScreenViewId.value;
    final smallId = smallViewId.value;
    final userId = remoteUserId;

    if (fullId == null || smallId == null || userId == null) {
      // 视图未就绪时仅切换状态，等待 _applyVideoBindings
      isVideoSwapped.value = !isVideoSwapped.value;
      if (fullId != null && smallId != null) {
        await _applyVideoBindings();
      }
      debugPrint('[CallController] 视频窗口切换: isSwapped=${isVideoSwapped.value}');
      return;
    }

    isVideoSwapped.value = !isVideoSwapped.value;

    // 使用 update 方法重新绑定，无需重建视图
    if (isVideoSwapped.value) {
      _callService.updateLocalView(fullId);
      _callService.updateRemoteView(userId, smallId);
    } else {
      _callService.updateLocalView(smallId);
      _callService.updateRemoteView(userId, fullId);
    }

    localViewId.value = isVideoSwapped.value ? fullId : smallId;
    remoteViewId.value = isVideoSwapped.value ? smallId : fullId;
    debugPrint('[CallController] 视频窗口切换: isSwapped=${isVideoSwapped.value}');
  }

  // ============ 充值提醒 ============

  /// 显示充值提醒
  void _showRechargeReminder(int seconds) {
    // 清除之前的计时器
    _clearRechargeTimers();

    rechargeCountdown.value = seconds;
    showRechargeReminder.value = true;
    rechargeReminderExpanded.value = true;

    // 开始倒计时
    _rechargeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (rechargeCountdown.value > 0) {
        rechargeCountdown.value--;
      } else {
        _clearRechargeTimers();
      }
    });

    // 3秒后自动收起
    _rechargeCollapseTimer = Timer(
      const Duration(milliseconds: CallConfig.rechargeReminderCollapseTime),
      () {
        rechargeReminderExpanded.value = false;
      },
    );
  }

  /// 点击充值提醒
  void onRechargeReminderClick() {
    if (!rechargeReminderExpanded.value) {
      rechargeReminderExpanded.value = true;
      
      // 重新设置收起计时器
      _rechargeCollapseTimer?.cancel();
      _rechargeCollapseTimer = Timer(
        const Duration(milliseconds: CallConfig.rechargeReminderCollapseTime),
        () {
          rechargeReminderExpanded.value = false;
        },
      );
    }
  }

  /// 格式化充值倒计时
  String get formattedRechargeCountdown {
    final seconds = rechargeCountdown.value;
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  /// 清除充值相关计时器
  void _clearRechargeTimers() {
    _rechargeTimer?.cancel();
    _rechargeTimer = null;
    _rechargeCollapseTimer?.cancel();
    _rechargeCollapseTimer = null;
  }
  // ============ 清理 ============

  @override
  void onClose() {
    debugPrint('[CallController] onClose');
    _hangupDisableTimer?.cancel();
    _clearRechargeTimers();

    // 清除回调
    _callService.onCallEnded = null;
    _callService.onRemoteVideoReady = null;
    _callService.onBalanceWarning = null;

    // 清除 TRTC 回调
    _trtcService.onUserVideoAvailable = null;
    _trtcService.onRemoteUserLeaveRoom = null;
    _trtcService.onFirstVideoFrame = null;

    // 清理聊天资源
    _removeIMListener();
    textController.dispose();
    chatScrollController.dispose();

    super.onClose();
  }
}

/// 来电页面控制器
class IncomingCallController extends GetxController {
  CallService get _callService => Get.find<CallService>();

  CallData? get callData => _callService.callData;
  UserModelEntity? get remoteUserInfo => _callService.remoteUserInfo;
  bool get isIncomingCall => _callService.isIncomingCall;

  /// 是否正在接听中
  final RxBool isAnswering = false.obs;

  /// 接听通话
  Future<void> answerCall() async {
    if (isAnswering.value) return; // 防止重复点击
    
    debugPrint('[IncomingCallController] 接听通话');
    isAnswering.value = true;
    
    final success = await _callService.answerCall();
    if (!success) {
      isAnswering.value = false;
      Get.back();
      ToastUtils.showError('Failed to answer the call');
    }
  }

  /// 拒绝/取消通话
  Future<void> rejectCall() async {
    debugPrint('[IncomingCallController] 拒绝通话');
    Get.back();
    _callService.rejectCall();
  }
}

/// 通话结束页面控制器
class CallEndController extends GetxController {
  CallService get _callService => Get.find<CallService>();

  UserModelEntity? get remoteUserInfo => _callService.remoteUserInfo;
  CallData? get callData => _callService.callData;
  Rx<CallStatusChangeMessage?> get endCallDataRx => _callService.endCallDataRx;
  CallStatusChangeMessage? get endCallData => _callService.endCallData;

  /// 是否已关注
  final RxBool isFollowed = false.obs;

  @override
  void onInit() {
    super.onInit();
    // UserModelEntity 没有 isFollowed 属性，默认为 false
    isFollowed.value = false;
  }

  /// 打开聊天
  void openChat() {
    // TODO: 实现打开聊天功能
    debugPrint('[CallEndController] 打开聊天');
  }

  /// 切换关注状态
  Future<void> toggleFollow() async {
    // TODO: 实现关注/取消关注功能
    isFollowed.value = !isFollowed.value;
    debugPrint('[CallEndController] 切换关注: ${isFollowed.value}');
  }

  /// 关闭页面
  Future<void> closePage() async {
    debugPrint('[CallEndController] 关闭页面');
    await _callService.cleanupCall();
    Get.back();
  }
}
