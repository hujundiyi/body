import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tencent_cloud_chat_sdk/enum/message_elem_type.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_message.dart';
import 'package:tencent_cloud_chat_sdk/utils/utils.dart';
import 'package:weeder/core/constants/app_constants.dart';
import 'package:weeder/core/constants/call_constants.dart';
import 'package:weeder/core/network/api_client.dart';
import 'package:weeder/core/services/auth_service.dart';
import 'package:weeder/core/services/im_service.dart';
import 'package:weeder/core/services/trtc_service.dart';
import 'package:weeder/core/utils/toast_utils.dart';
import 'package:weeder/data/models/call_data_model.dart';
import 'package:weeder/routes/app_routes.dart';
import '../../data/models/user_model_entity.dart';

/// 通话管理服务
/// 参照 H5 SDK 中的 CallUtils.js 实现
class CallService extends GetxService {
  static CallService get shared => Get.find<CallService>();

  // ============ 依赖服务 ============
  TRTCService get _trtcService => Get.find<TRTCService>();
  IMService get _imService => Get.find<IMService>();
  AuthService get _authService => Get.find<AuthService>();



  // ============ 通话状态 ============
  /// 本地通话状态
  final Rx<LocalCallStatus> _localCallStatus = LocalCallStatus.none.obs;
  Rx<LocalCallStatus> get localCallStatusRx => _localCallStatus;
  LocalCallStatus get localCallStatus => _localCallStatus.value;

  /// 当前通话数据
  final Rx<CallData?> _callData = Rx<CallData?>(null);
  CallData? get callData => _callData.value;

  /// 通话对方用户信息（对于主播端，这是用户信息）
  final Rx<UserModelEntity?> _remoteUserInfo = Rx<UserModelEntity?>(null);
  UserModelEntity? get remoteUserInfo => _remoteUserInfo.value;

  /// 通话结束数据
  final Rx<CallStatusChangeMessage?> _endCallData = Rx<CallStatusChangeMessage?>(null);
  Rx<CallStatusChangeMessage?> get endCallDataRx => _endCallData;
  CallStatusChangeMessage? get endCallData => _endCallData.value;

  /// 是否是匹配通话
  final RxBool _isMatchingCall = false.obs;
  bool get isMatchingCall => _isMatchingCall.value;

  /// 是否是自己主动结束通话
  final RxBool _isMyCallEnd = false.obs;
  bool get isMyCallEnd => _isMyCallEnd.value;

  /// 是否为来电（被叫方）
  final RxBool _isIncomingCall = true.obs;
  bool get isIncomingCall => _isIncomingCall.value;

  /// 通话开始时间
  final RxInt _callStartTime = 0.obs;
  int get callStartTime => _callStartTime.value;

  /// 摄像头开关状态
  final RxBool _isCameraEnabled = true.obs;
  bool get isCameraEnabled => _isCameraEnabled.value;

  /// 麦克风开关状态
  final RxBool _isMicrophoneEnabled = true.obs;
  bool get isMicrophoneEnabled => _isMicrophoneEnabled.value;

  /// 是否使用前置摄像头
  final RxBool _isFrontCamera = true.obs;
  bool get isFrontCamera => _isFrontCamera.value;

  // ============ 计时器 ============
  Timer? _callTimer;
  Timer? _timeoutTimer;

  // ============ 回调函数 ============
  /// 收到来电回调
  Function(CallData callData, UserModelEntity? userInfo)? onIncomingCall;
  /// 通话被接听回调
  Function()? onCallAnswered;
  /// 通话被拒绝回调
  Function(String? reason)? onCallRejected;
  /// 通话结束回调
  Function(CallStatusChangeMessage? endData)? onCallEnded;
  /// 通话超时回调
  Function()? onCallTimeout;
  /// 余额不足提醒回调
  Function(int remainingSeconds)? onBalanceWarning;
  /// 远端视频就绪回调
  Function()? onRemoteVideoReady;

  // ============ 初始化 ============
  
  /// IM 消息监听器
  Worker? _messageWorker;

  @override
  void onInit() {
    super.onInit();
    _setupIMListener();
  }


  /// 设置 IM 消息监听
  void _setupIMListener() {
    debugPrint('[CallService] 设置 IM 消息监听');
    
    _messageWorker = ever(_imService.newMessages, (messages) {
      for (V2TimMessage message in messages) {
        _handleIMMessage(message);
      }
    });
  }

  /// 处理 IM 消息
  void _handleIMMessage(V2TimMessage message) {
    try {
      // 检查是否为自定义消息
      debugPrint(message.customElem?.data ?? '');
      if (message.elemType != MessageElemType.V2TIM_ELEM_TYPE_CUSTOM) return; // 2 = 自定义消息
      debugPrint(message.customElem?.data ?? '');
      final customElem = message.customElem;
      if (customElem?.data == null) return;

      final Map<String, dynamic> customData = json.decode(customElem?.data ?? '');
      final int? customType = customData['customType'];

      if (customType == null) return;

      debugPrint('[CallService] 收到自定义消息: customType=$customType');

      switch (customType) {
        case CallMessageType.callInvite: case CallMessageType.callStatusChange:
          _handleCallStatusChangeMessage(customData);
          break;
        case CallMessageType.lessThanOneMinute:
          _handleBalanceWarningMessage(customData);
          break;
        default:
          break;
      }
    } catch (e) {
      debugPrint('[CallService] 处理 IM 消息失败: $e');
    }
  }

  /// 处理通话邀请消息
  // void _handleCallInviteMessage(Map<String, dynamic> data) {
  //   final message = CallInviteMessage.fromJson(data);
  //   debugPrint('[CallService] 通话邀请消息: actionType=$message');
  //
  //   // actionType == 1 表示来电邀请
  //   if (message.actionType == 1 && message.callInvite != null) {
  //     _handleIncomingCallInvite(message.callInvite!);
  //     return;
  //   }
  //
  //   if (message.actionType == 3) {
  //     // 对方拒绝/取消通话
  //     if (_isMatchingCall.value) {
  //       if (_localCallStatus.value == LocalCallStatus.waiting) {
  //         // 匹配通话被拒绝，可以触发重新匹配
  //         onCallRejected?.call('Match call rejected');
  //       }
  //     } else {
  //
  //       if (_localCallStatus.value == LocalCallStatus.waiting || message.callStatus == CallStatus.callDone.code) {
  //         _showToast('The caller rejected the call.');
  //         setLocalCallStatus(LocalCallStatus.none);
  //         Get.back();
  //       }
  //     }
  //   } else {
  //     // 通话被接听，跳转到通话中页面
  //     if (_localCallStatus.value == LocalCallStatus.waiting) {
  //       setLocalCallStatus(LocalCallStatus.calling);
  //       onCallAnswered?.call();
  //       // 主播端接听后会自动跳转，这里不需要额外处理
  //     }
  //   }
  // }

  /// 处理通话状态变更消息
  void _handleCallStatusChangeMessage(Map<String, dynamic> data) {
    final message = CallStatusChangeMessage.fromJson(data);
    debugPrint('[CallService] message: message=${message}');
    debugPrint('[CallService] 通话状态变更: callStatus=${message.callStatus}');
    debugPrint('[CallService] 本地状态: callStatus=${_localCallStatus.value}');
    if ((_localCallStatus.value == LocalCallStatus.none || _localCallStatus.value == LocalCallStatus.end) && message.actionType == 1 && message.callInvite != null) {
      //来电
      handleIncomingCall(
        callData: message.callInvite!,
        userInfo: message.callInvite!.userInfo,
      );
      return;
    }else if (_localCallStatus.value == LocalCallStatus.calling || _localCallStatus.value == LocalCallStatus.end) {
      // 通话中收到状态变更
      if (message.callStatus == CallStatus.callDone.code
          || message.callStatus == CallStatus.callingErrorDone.code
          || message.callStatus == CallStatus.systemStop.code
          || message.callStatus == CallStatus.notBalanceDone.code
      ) {
        if (_localCallStatus.value == LocalCallStatus.calling) {
          setLocalCallStatus(LocalCallStatus.end);
          if (!_isMyCallEnd.value) {
            _showToast('The other person has left the room.');
          }
          // 检查避免重复跳转
          if (Get.currentRoute != AppRoutes.CALL_END) {
            Get.offAndToNamed(AppRoutes.CALL_END);
          }
        }
        if (message.callTime != null && message.callTime! > 0) {
          setEndCallData(CallStatusChangeMessage.fromJson(data));
        }
        onCallEnded?.call(_endCallData.value);
      }
    } else if (_localCallStatus.value == LocalCallStatus.waiting) {
      // 等待中收到状态变更
      if (message.callStatus == CallStatus.answer.code) {
        setLocalCallStatus(LocalCallStatus.calling);
        // 检查当前是否已经在 CALLING 页面，避免重复跳转
        if (Get.currentRoute != AppRoutes.CALLING) {
          Get.offAndToNamed(AppRoutes.CALLING);
        }
      }else if (message.callStatus == CallStatus.cancelCall.code) {
        setLocalCallStatus(LocalCallStatus.none);
        onCallRejected?.call('Caller rejected');
        Get.until((route) => route.settings.name != AppRoutes.INCOMING_CALL);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showToast('The caller rejected the call.');
        });
      }else if(message.callStatus == CallStatus.callErrorDone.code){
        setLocalCallStatus(LocalCallStatus.none);
        onCallRejected?.call('Caller rejected');
        Get.until((route) => route.settings.name != AppRoutes.INCOMING_CALL);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showToast('The error occurred while calling.');
        });
      }
    }
  }

  /// 处理余额不足提醒消息
  void _handleBalanceWarningMessage(Map<String, dynamic> data) {
    final String? callNo = data['callNo'];
    if (callNo != _callData.value?.callNo) return;

    debugPrint('[CallService] 余额不足提醒');
    onBalanceWarning?.call(60); // 默认60秒
  }

  // ============ 通话操作 ============

  /// 创建通话（主动发起呼叫 - 主播端主动呼叫用户）
  Future<bool> createCall({
    required int toUserId,
    UserModelEntity? userInfo,
  }) async {

    // 请求摄像头和麦克风权限
    final permissionGranted = await _requestCallPermissions();
    if (!permissionGranted) {
      debugPrint('[CallService] 权限未授予');
      return false;
    }

    // 拨打前判断是否已上线，未上线则弹出上线弹窗
    final onWork = await _imService.isCurrentUserOnWork();
    if (!onWork) {
      _showGoOnlineDialog();
      return false;
    }

    try {
      debugPrint('[CallService] 发起通话: toUserId=$toUserId');
      // 调用创建通话 API
      // 先设置状态，以免IM消息先到出现问题

      setLocalCallStatus(LocalCallStatus.waiting);
      
      // 显示加载动画
      _showLoadingDialog();
      
      final response = await CallAPIService.shared.createCall(toUserId: toUserId);
      
      // 关闭加载动画
      _hideLoadingDialog();
      
      if (response.success && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        // 解析通话数据
        final callData = CallData.fromJson(data);
        setCallData(callData);
        if (userInfo != null) {
          setRemoteUserInfo(userInfo);
        }
        // 设置超时计时器
        _startTimeoutTimer();

        // 跳转到通话等待页面（等待对方接听）
        Get.toNamed(AppRoutes.INCOMING_CALL);
        _isIncomingCall.value = false;
        return true;
      } else {
        setLocalCallStatus(LocalCallStatus.none);
        debugPrint('[CallService] 发起通话失败: ${response.msg}');
        _showToast(response.msg ?? 'Failed to initiate call');
        return false;
      }
    } catch (e) {
      // 确保关闭加载动画
      _hideLoadingDialog();
      setLocalCallStatus(LocalCallStatus.none);
      debugPrint('[CallService] 发起通话失败: $e');
      _showToast('Failed to initiate call');
      return false;
    }
  }

  /// 处理来电（被叫方 - 主播端）
  Future<void> handleIncomingCall({
    required CallData callData,
    UserModelEntity? userInfo,
  }) async {
    debugPrint('[CallService] 处理来电: callNo=${callData.callNo}');

    _isIncomingCall.value = true;
    setCallData(callData);
    setRemoteUserInfo(userInfo ?? callData.userInfo);
    final currentStatus = _localCallStatus.value;
    setLocalCallStatus(LocalCallStatus.waiting);

    if (_imService.isSoundingEnabled) {
      try {
        SystemSound.play(SystemSoundType.alert);
      } catch (_) {}
    }

    // 触发来电回调
    onIncomingCall?.call(callData, _remoteUserInfo.value);

    // 跳转到来电页面
    if (currentStatus == LocalCallStatus.end) {
      Get.offAndToNamed(AppRoutes.INCOMING_CALL);
    }else {
      Get.toNamed(AppRoutes.INCOMING_CALL);
    }


    // 设置超时计时器
    _startTimeoutTimer();
  }

  /// 接听通话（主播端）
  Future<bool> answerCall() async {
    if (_callData.value == null) {
      debugPrint('[CallService] 错误: 没有通话数据');
      return false;
    }
    final permissionGranted = await _requestCallPermissions();
    if (!permissionGranted) {
      debugPrint('[CallService] 权限未授予');
      return false;
    }
    try {
      debugPrint('[CallService] 接听通话: callNo=${_callData.value!.callNo}');

      // 取消超时计时器
      _cancelTimeoutTimer();

      // 调用接听 API
      final response = await CallAPIService.shared.answerCall(
        callNo: _callData.value!.callNo,
      );

      if (response.success) {
        setLocalCallStatus(LocalCallStatus.calling);
        
        // 跳转到通话中页面（检查避免重复跳转）
        if (Get.currentRoute != AppRoutes.CALLING) {
          Get.offAndToNamed(AppRoutes.CALLING);
        }
        
        return true;
      } else {
        debugPrint('[CallService] 接听通话失败: ${response.msg}');
        return false;
      }
    } catch (e) {
      debugPrint('[CallService] 接听通话失败: $e');
      return false;
    }
  }

  /// 拒绝通话（主播端）
  Future<bool> rejectCall() async {
    if (_callData.value == null) return false;

    try {
      debugPrint('[CallService] 拒绝通话: callNo=${_callData.value!.callNo}');

      // 取消超时计时器
      _cancelTimeoutTimer();

      // 调用拒绝 API
      final response = await CallAPIService.shared.endCall(
        callNo: _callData.value!.callNo,
        status: CallStatus.refuse.value,
      );

      setLocalCallStatus(LocalCallStatus.none);
      _clearCallData();

      return response.success;
    } catch (e) {
      debugPrint('[CallService] 拒绝通话失败: $e');
      return false;
    }
  }

  /// 结束通话
  Future<bool> endCall({
    CallStatus status = CallStatus.callDone,
  }) async {


    _isMyCallEnd.value = true;

    // 停止计时
    _stopCallTimer();

    // 退出 TRTC 房间
    await _trtcService.exitRoom();

    // if (_localCallStatus.value == LocalCallStatus.calling) {
    setLocalCallStatus(LocalCallStatus.end);
    // 跳转到通话结束页面（检查避免重复跳转）
    if (Get.currentRoute != AppRoutes.CALL_END) {
      Get.offAndToNamed(AppRoutes.CALL_END);
    }
    // }
    try {
      debugPrint('[CallService] 结束通话: callNo=${_callData.value!.callNo}, status=${status.value}');
      if (_callData.value == null) return false;
      // 调用结束 API
      final response = await CallAPIService.shared.endCall(
        callNo: _callData.value!.callNo,
        status: status.value,
      );
      return response.success;
    } catch (e) {
      debugPrint('[CallService] 结束通话失败: $e');
      return false;
    }
  }

  /// 处理通话超时（60 秒未接通）
  void _handleCallTimeout() {
    if (_localCallStatus.value != LocalCallStatus.waiting) {
      return;
    }
    _cancelTimeoutTimer();
    debugPrint('[CallService] 通话超时 60s 未接通');

    if (_isIncomingCall.value) {
      // 别人拨打：超过 60 秒未接听，直接退出页面并重置状态，不调 endCall 接口
      setLocalCallStatus(LocalCallStatus.none);
      onCallTimeout?.call();
      Get.back();
      _clearCallData();
      _showToast('Call timeout');
    } else {
      // 自己拨打：超过 60 秒未接通，调用 endCall 接口，状态为 callTimeoutDone(32)
      _showToast('Call timeout, please try again later');
      if (_callData.value != null) {
        CallAPIService.shared.endCall(
          callNo: _callData.value!.callNo,
          status: CallStatus.callTimeoutDone.value,
        );
      }
      setLocalCallStatus(LocalCallStatus.none);
      onCallTimeout?.call();
      Get.back();
      _clearCallData();
    }
  }

  // ============ TRTC 操作 ============

  /// 进入通话房间
  Future<bool> enterCallRoom() async {
    if (_callData.value == null) {
      debugPrint('[CallService] 错误: 没有通话数据');
      return false;
    }
    _stopCallTimer();
    try {
      final userId = _authService.userId?.toString();

      final rtcToken = _callData.value?.createUserId?.toString() == userId
          ? _callData.value!.createUserSign
          : _callData.value!.toUserSign; // 主播使用被叫方Token
      if (userId == null || rtcToken == null) {
        debugPrint('[CallService] 错误: userId 或 rtcToken 为空');
        return false;
      }

      debugPrint('[CallService] 进入通话房间: roomId=${_callData.value!.callNo},userId=$userId,token=$rtcToken');
      debugPrint('[CallService] 进入通话房间: createUserSign=${_callData.value!.createUserSign}');
      debugPrint('[CallService] 进入通话房间: toUserSign=${_callData.value!.toUserSign}');
      debugPrint('[CallService] 进入通话房间: rtcToken=$rtcToken');
      // 设置 TRTC 回调
      _setupTRTCCallbacks();

      // 进入房间
      final success = await _trtcService.enterRoom(
        roomId: _callData.value!.callNo,
        userId: userId,
        userSig: rtcToken,
      );

      if (success) {
        // 开始通话计时
        _startCallTimer();
      }

      return success;
    } catch (e) {
      debugPrint('[CallService] 进入通话房间失败: $e');
      return false;
    }
  }

  /// 设置 TRTC 回调
  void _setupTRTCCallbacks() {
    _trtcService.onRemoteUserLeaveRoom = (userId, reason) {
      debugPrint('[CallService] 远端用户离开: userId=$userId');
      if (!_isMyCallEnd.value) {
        _showToast('The other person has left the room.');
        endCall(status: CallStatus.callDone);
      }
    };

    _trtcService.onFirstVideoFrame = (userId, streamType, width, height) {
      if (userId != _trtcService.currentUserId) {
        debugPrint('[CallService] 远端视频就绪 ');
        onRemoteVideoReady?.call();
      }
    };

    _trtcService.onError = (errCode, errMsg) {
      debugPrint('[CallService] TRTC 错误: code=$errCode, msg=$errMsg');
      if (errCode != 0) {
        _showToast('Video call error: $errMsg');
      }
    };
  }

  /// 开始本地视频预览
  Future<void> startLocalPreview(int viewId) async {
    await _trtcService.startLocalPreview(
      viewId: viewId,
      frontCamera: _isFrontCamera.value,
    );
  }

  /// 开始远端视频渲染
  Future<void> startRemoteView(String userId, int viewId) async {
    await _trtcService.startRemoteView(
      userId: userId,
      viewId: viewId,
    );
  }

  /// 更新本地视频渲染视图（用于切换全屏/小窗）
  void updateLocalView(int viewId) {
    _trtcService.updateLocalView(viewId);
  }

  /// 更新远端视频渲染视图（用于切换全屏/小窗）
  void updateRemoteView(String userId, int viewId) {
    _trtcService.updateRemoteView(userId: userId, viewId: viewId);
  }

  /// 切换摄像头
  Future<void> switchCamera() async {
    await _trtcService.switchCamera();
    _isFrontCamera.value = _trtcService.isFrontCamera;
  }

  /// 设置摄像头开关
  Future<void> setCameraEnabled(bool enabled) async {
    await _trtcService.setLocalVideoEnabled(enabled);
    _isCameraEnabled.value = enabled;
  }

  /// 设置麦克风开关
  Future<void> setMicrophoneEnabled(bool enabled) async {
    await _trtcService.setLocalAudioEnabled(enabled);
    _isMicrophoneEnabled.value = enabled;
  }

  // ============ 状态管理 ============

  void setLocalCallStatus(LocalCallStatus status) {
    _localCallStatus.value = status;
    debugPrint('[CallService] 本地通话状态: ${status.value}');
  }

  void setCallData(CallData? data) {
    _callData.value = data;
  }

  void setRemoteUserInfo(UserModelEntity? info) {
    _remoteUserInfo.value = info;
  }

  void setEndCallData(CallStatusChangeMessage? data) {
    _endCallData.value = data;
  }

  void setIsMatchingCall(bool value) {
    _isMatchingCall.value = value;
  }

  void setIsMyCallEnd(bool value) {
    _isMyCallEnd.value = value;
  }

  // ============ 计时器 ============

  void _startCallTimer() {
    _callStartTime.value = 0;
    _callTimer?.cancel();
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _callStartTime.value++;
    });
  }

  void _stopCallTimer() {
    _callTimer?.cancel();
    _callTimer = null;
  }

  void _startTimeoutTimer() {
    _cancelTimeoutTimer();
    _timeoutTimer = Timer(
      const Duration(milliseconds: CallConfig.incomingTimeout),
      _handleCallTimeout,
    );
  }

  void _cancelTimeoutTimer() {
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
  }

  /// 获取格式化的通话时长
  String get formattedCallDuration {
    final seconds = _callStartTime.value;
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  // ============ 清理 ============

  void _clearCallData() {
    _callData.value = null;
    _remoteUserInfo.value = null;
    _endCallData.value = null;
    _isMatchingCall.value = false;
    _isMyCallEnd.value = false;
    _isIncomingCall.value = true;
    _callStartTime.value = 0;
    _isCameraEnabled.value = true;
    _isMicrophoneEnabled.value = true;
    _stopCallTimer();
    _cancelTimeoutTimer();
  }

  /// 完全清理通话状态
  Future<void> cleanupCall() async {
    debugPrint('[CallService] 清理通话状态');
    
    // 退出 TRTC 房间
    if (_trtcService.isInRoom) {
      await _trtcService.exitRoom();
    }
    
    _clearCallData();
    setLocalCallStatus(LocalCallStatus.none);
  }

  void _showToast(String message) {
    ToastUtils.showToast(message);
  }

  /// 未上线时弹出提示：确认上线才能继续拨打
  void _showGoOnlineDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Go Online to Call'),
        content: const Text(
          'You need to be online (On Work) to make calls. Please confirm to go online first.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              await _imService.setCurrentUserOnWork();
              _showToast('You are now online. You can make the call again.');
            },
            child: const Text('On Work'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  /// 显示加载对话框
  void _showLoadingDialog() {
    if (Get.isDialogOpen ?? false) return;
    
    Get.dialog(
      PopScope(
        canPop: false,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  color: Colors.blue[400],
                  strokeWidth: 3,
                ),
                const SizedBox(height: 16),
                Text(
                  'Connecting...',
                  style: TextStyle(
                    color: Colors.grey[800],
                    fontSize: 14,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.3),
    );
  }

  /// 隐藏加载对话框
  void _hideLoadingDialog() {
    if (Get.isDialogOpen ?? false) {
      Get.back();
    }
  }

  // ============ 权限管理 ============

  /// 请求通话所需权限（摄像头和麦克风）
  Future<bool> _requestCallPermissions() async {
    try {
      // 检查摄像头权限
      var cameraStatus = await Permission.camera.status;
      if (!cameraStatus.isGranted) {
        cameraStatus = await Permission.camera.request();
        if (!cameraStatus.isGranted) {
          _showToast('Camera permission is required for video calls');
          if (cameraStatus.isPermanentlyDenied) {
            openAppSettings();
          }
          return false;
        }
      }

      // 检查麦克风权限
      var micStatus = await Permission.microphone.status;
      if (!micStatus.isGranted) {
        micStatus = await Permission.microphone.request();
        if (!micStatus.isGranted) {
          _showToast('Microphone permission is required for voice calls');
          if (micStatus.isPermanentlyDenied) {
            openAppSettings();
          }
          return false;
        }
      }

      debugPrint('[CallService] 权限已授予: camera=$cameraStatus, microphone=$micStatus');
      return true;
    } catch (e) {
      debugPrint('[CallService] 请求权限失败: $e');
      return false;
    }
  }

  @override
  void onClose() {
    _messageWorker?.dispose();
    _stopCallTimer();
    _cancelTimeoutTimer();
    super.onClose();
  }
}

/// 通话 API 服务
class CallAPIService {
  static final CallAPIService shared = CallAPIService._();
  CallAPIService._();

  APIClient get _client => APIClient.shared;

  /// 接听通话（主播端调用 callStart）
  Future<CallApiResponse> answerCall({required String callNo}) async {
    try {
      final result = await _client.request<Map<String, dynamic>>(
        APIPaths.callStart,
        params: {'callNo': callNo},
        fromJsonT: (json) => json as Map<String, dynamic>,
      );
      return CallApiResponse(success: true, code: 200, data: result);
    } catch (e) {
      return CallApiResponse(success: false, code: -1, msg: e.toString());
    }
  }

  /// 结束通话
  Future<CallApiResponse> endCall({
    required String callNo,
    required String status,
    String? remark,
  }) async {
    try {
      final result = await _client.request<Map<String, dynamic>>(
        APIPaths.callEnd,
        params: {
          'callNo': callNo,
          'status': status,
          if (remark != null) 'remark': remark,
        },
        fromJsonT: (json) => json as Map<String, dynamic>,
      );
      return CallApiResponse(success: true, code: 200, data: result);
    } catch (e) {
      return CallApiResponse(success: false, code: -1, msg: e.toString());
    }
  }

  /// 创建通话（主动发起呼叫）
  Future<CallApiResponse> createCall({required int toUserId}) async {
    try {
      final result = await _client.request<Map<String, dynamic>>(
        APIPaths.callCreate,
        params: {'userId': toUserId},
        fromJsonT: (json) => json as Map<String, dynamic>,
      );
      return CallApiResponse(success: true, code: 200, data: result);
    } catch (e) {
      return CallApiResponse(success: false, code: -1, msg: e.toString());
    }
  }

  /// 获取通话历史
  Future<CallApiResponse> getCallHistory({
    required int page,
    required int size,
    int? callType,
  }) async {
    try {
      final result = await _client.request<Map<String, dynamic>>(
        APIPaths.getCallHistory,
        params: {
          'page': page,
          'size': size,
          if (callType != null) 'callType': callType,
        },
        fromJsonT: (json) => json as Map<String, dynamic>,
      );
      return CallApiResponse(success: true, code: 200, data: result);
    } catch (e) {
      return CallApiResponse(success: false, code: -1, msg: e.toString());
    }
  }
}

/// 通话 API 响应包装类
class CallApiResponse {
  final bool success;
  final int code;
  final String? msg;
  final dynamic data;

  CallApiResponse({
    required this.success,
    required this.code,
    this.msg,
    this.data,
  });

  factory CallApiResponse.fromJson(Map<String, dynamic> json) {
    return CallApiResponse(
      success: json['code'] == 200 || json['code'] == 0,
      code: json['code'] ?? 0,
      msg: json['msg'] ?? json['message'],
      data: json['data'],
    );
  }
}
