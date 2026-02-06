import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:tencent_rtc_sdk/trtc_cloud.dart';
import 'package:tencent_rtc_sdk/trtc_cloud_def.dart';
import 'package:tencent_rtc_sdk/trtc_cloud_listener.dart';
import 'package:tencent_rtc_sdk/trtc_cloud_video_view.dart';
import 'package:tencent_rtc_sdk/tx_audio_effect_manager.dart';
import 'package:tencent_rtc_sdk/tx_device_manager.dart';
import 'package:weeder/core/constants/app_constants.dart';
import 'app_config_service.dart';
import 'storage_service.dart';

/// 腾讯云 TRTC 服务
/// 参照 H5 SDK 中的 AgoraRTCManager 实现
class TRTCService extends GetxService {
  static TRTCService get shared => Get.find<TRTCService>();

  /// TRTC 实例
  TRTCCloud? _trtcCloud;
  TRTCCloud? get trtcCloud => _trtcCloud;

  /// 设备管理器
  TXDeviceManager? _deviceManager;
  TXDeviceManager? get deviceManager => _deviceManager;

  /// 音效管理器
  TXAudioEffectManager? _audioEffectManager;
  TXAudioEffectManager? get audioEffectManager => _audioEffectManager;

  /// SDK 是否已初始化
  final RxBool _isInitialized = false.obs;
  bool get isInitialized => _isInitialized.value;

  /// 是否已进入房间
  final RxBool _isInRoom = false.obs;
  bool get isInRoom => _isInRoom.value;

  /// 当前房间ID
  String? _currentRoomId;
  String? get currentRoomId => _currentRoomId;

  /// 当前用户ID
  String? _currentUserId;
  String? get currentUserId => _currentUserId;

  /// 本地视频是否开启
  final RxBool _isLocalVideoEnabled = true.obs;
  bool get isLocalVideoEnabled => _isLocalVideoEnabled.value;

  /// 本地音频是否开启
  final RxBool _isLocalAudioEnabled = true.obs;
  bool get isLocalAudioEnabled => _isLocalAudioEnabled.value;

  /// 是否使用前置摄像头
  final RxBool _isFrontCamera = true.obs;
  bool get isFrontCamera => _isFrontCamera.value;

  /// 美颜是否开启
  final RxBool _isBeautyEnabled = true.obs;
  bool get isBeautyEnabled => _isBeautyEnabled.value;

  /// 美颜风格（smooth=磨皮明显适合秀场, nature=自然保留细节）
  TRTCBeautyStyle _beautyStyle = TRTCBeautyStyle.smooth;
  TRTCBeautyStyle get beautyStyle => _beautyStyle;

  /// 美颜/美白/红润等级 0-9
  int _beautyLevel = 5;
  int _whitenessLevel = 5;
  int _ruddinessLevel = 5;
  int get beautyLevel => _beautyLevel;
  int get whitenessLevel => _whitenessLevel;
  int get ruddinessLevel => _ruddinessLevel;

  /// 远端用户列表
  final RxList<String> _remoteUsers = <String>[].obs;
  List<String> get remoteUsers => _remoteUsers;

  /// 远端视频是否就绪
  final RxBool _isRemoteVideoReady = false.obs;
  bool get isRemoteVideoReady => _isRemoteVideoReady.value;

  // ============ 事件回调 ============
  /// 远端用户进入房间回调
  Function(String userId)? onRemoteUserEnterRoom;
  /// 远端用户离开房间回调
  Function(String userId, int reason)? onRemoteUserLeaveRoom;
  /// 远端用户开始推送视频回调
  Function(String userId, TRTCVideoStreamType streamType)? onUserVideoAvailable;
  /// 远端用户停止推送视频回调
  Function(String userId, bool available)? onUserVideoAvailableChanged;
  /// 远端用户开始推送音频回调
  Function(String userId, bool available)? onUserAudioAvailable;
  /// 进入房间回调
  Function(int result)? onEnterRoom;
  /// 退出房间回调
  Function(int reason)? onExitRoom;
  /// 错误回调
  Function(int errCode, String errMsg)? onError;
  /// 网络质量回调
  Function(TRTCQualityInfo localQuality, List<TRTCQualityInfo> remoteQuality)? onNetworkQuality;
  /// 首帧视频画面回调
  Function(String userId, TRTCVideoStreamType streamType, int width, int height)? onFirstVideoFrame;

  // ============ 初始化 ============

  /// 从本地加载美颜设置
  void _loadBeautySettings() {
    try {
      final storage = Get.find<StorageService>();
      final enabled = storage.getBool(AppConstants.keyBeautyEnabled);
      if (enabled != null) _isBeautyEnabled.value = enabled;
      final beauty = storage.getInt(AppConstants.keyBeautyLevel);
      if (beauty != null) _beautyLevel = beauty.clamp(0, 9);
      final white = storage.getInt(AppConstants.keyWhitenessLevel);
      if (white != null) _whitenessLevel = white.clamp(0, 9);
      final ruddy = storage.getInt(AppConstants.keyRuddinessLevel);
      if (ruddy != null) _ruddinessLevel = ruddy.clamp(0, 9);
      debugPrint('[TRTC] 已加载美颜设置: enabled=$_isBeautyEnabled, b=$_beautyLevel, w=$_whitenessLevel, r=$_ruddinessLevel');
    } catch (e) {
      debugPrint('[TRTC] 加载美颜设置失败: $e');
    }
  }

  /// 保存美颜设置到本地
  Future<void> _saveBeautySettings() async {
    try {
      final storage = Get.find<StorageService>();
      await storage.setBool(AppConstants.keyBeautyEnabled, _isBeautyEnabled.value);
      await storage.setInt(AppConstants.keyBeautyLevel, _beautyLevel);
      await storage.setInt(AppConstants.keyWhitenessLevel, _whitenessLevel);
      await storage.setInt(AppConstants.keyRuddinessLevel, _ruddinessLevel);
    } catch (e) {
      debugPrint('[TRTC] 保存美颜设置失败: $e');
    }
  }

  /// 初始化 TRTC SDK
  Future<bool> init() async {
    if (_isInitialized.value) {
      debugPrint('[TRTC] SDK 已初始化');
      return true;
    }

    try {
      _loadBeautySettings();
      debugPrint('[TRTC] 开始初始化 SDK...');
      _trtcCloud = (await TRTCCloud.sharedInstance())!;
      
      // 获取管理器
      _deviceManager = _trtcCloud!.getDeviceManager();
      _audioEffectManager = _trtcCloud!.getAudioEffectManager();

      // 注册事件监听
      _registerListeners();

      _isInitialized.value = true;
      debugPrint('[TRTC] SDK 初始化成功');
      return true;
    } catch (e) {
      debugPrint('[TRTC] SDK 初始化失败: $e');
      return false;
    }
  }

  /// TRTC 事件监听器
  TRTCCloudListener? _listener;

  /// 注册事件监听
  void _registerListeners() {
    if (_trtcCloud == null) return;

    _listener = TRTCCloudListener(
      onError: (errCode, errMsg) {
        debugPrint('[TRTC] 错误: code=$errCode, msg=$errMsg');
        onError?.call(errCode, errMsg);
      },
      onWarning: (warningCode, warningMsg) {
        debugPrint('[TRTC] 警告: code=$warningCode, msg=$warningMsg');
      },
      onEnterRoom: (result) {
        debugPrint('[TRTC] 进入房间: result=$result');
        if (result > 0) {
          _isInRoom.value = true;
        }
        onEnterRoom?.call(result);
      },
      onExitRoom: (reason) {
        debugPrint('[TRTC] 退出房间回调: reason=$reason');
        _isInRoom.value = false;
        _currentRoomId = null;
        _remoteUsers.clear();
        _isRemoteVideoReady.value = false;
        _exitRoomCompleter?.complete();
        onExitRoom?.call(reason);
      },
      onRemoteUserEnterRoom: (userId) {
        debugPrint('[TRTC] 远端用户进入房间: $userId');
        if (!_remoteUsers.contains(userId)) {
          _remoteUsers.add(userId);
        }
        onRemoteUserEnterRoom?.call(userId);
      },
      onRemoteUserLeaveRoom: (userId, reason) {
        debugPrint('[TRTC] 远端用户离开房间: userId=$userId, reason=$reason');
        _remoteUsers.remove(userId);
        if (_remoteUsers.isEmpty) {
          _isRemoteVideoReady.value = false;
        }
        onRemoteUserLeaveRoom?.call(userId, reason);
      },
      onUserVideoAvailable: (userId, available) {
        debugPrint('[TRTC] 远端用户视频可用状态: userId=$userId, available=$available');
        if (available) {
          onUserVideoAvailable?.call(userId, TRTCVideoStreamType.big);
        }
        onUserVideoAvailableChanged?.call(userId, available);
      },
      onUserSubStreamAvailable: (userId, available) {
        debugPrint('[TRTC] 远端用户辅流可用状态: userId=$userId, available=$available');
        if (available) {
          onUserVideoAvailable?.call(userId, TRTCVideoStreamType.sub);
        }
      },
      onUserAudioAvailable: (userId, available) {
        debugPrint('[TRTC] 远端用户音频可用状态: userId=$userId, available=$available');
        onUserAudioAvailable?.call(userId, available);
      },
      onFirstVideoFrame: (userId, streamType, width, height) {
        debugPrint('[TRTC] 首帧视频: userId=$userId, streamType=$streamType, ${width}x$height');
        if (userId.isNotEmpty && userId != _currentUserId) {
          _isRemoteVideoReady.value = true;
        }
        onFirstVideoFrame?.call(
          userId,
          streamType,
          width,
          height,
        );
      },
    );

    _trtcCloud!.registerListener(_listener!);
  }

  // ============ 房间操作 ============

  /// 进入房间并发布流
  /// [roomId] 房间ID（使用 callNo）
  /// [userId] 用户ID
  /// [userSig] 用户签名（RTC Token）
  /// [role] 用户角色
  Future<bool> enterRoom({
    required String roomId,
    required String userId,
    required String userSig,
    TRTCRoleType role = TRTCRoleType.anchor,
  }) async {
    if (!_isInitialized.value) {
      final initResult = await init();
      if (!initResult) return false;
    }

    try {
      debugPrint('[TRTC] 进入房间: roomId=$roomId, userId=$userId');
      
      _currentRoomId = roomId;
      _currentUserId = userId;

      // 获取 sdkAppId
      final sdkAppId = AppConfigService.shared.tencentRtcAppId;
      
      // 构建进房参数
      final params = TRTCParams(
        sdkAppId: sdkAppId,
        userId: userId,
        userSig: userSig,
        strRoomId: roomId, // 使用字符串房间号
        role: role,
      );
      debugPrint('[CallService] enterRoom: callStatus=${params.toString()}');
      // 设置默认视频编码参数
      _trtcCloud!.setVideoEncoderParam(TRTCVideoEncParam(
        videoResolution: TRTCVideoResolution.res_1280_720,
        videoResolutionMode: TRTCVideoResolutionMode.portrait,
        videoFps: 15,
        videoBitrate: 600,
        minVideoBitrate: 200,
        enableAdjustRes: true,
      ));

      // 进入房间
      _trtcCloud!.enterRoom(params, TRTCAppScene.videoCall);

      // 开启本地音频
      _trtcCloud!.startLocalAudio(TRTCAudioQuality.music);
      _isLocalAudioEnabled.value = true;

      debugPrint('[TRTC] 进房请求已发送');
      return true;
    } catch (e) {
      debugPrint('[TRTC] 进入房间失败: $e');
      return false;
    }
  }

  /// 开始本地视频预览
  Future<void> startLocalPreview({
    required int viewId,
    bool frontCamera = true,
  }) async {
    if (_trtcCloud == null) return;

    debugPrint('[TRTC] 开始本地视频预览: viewId=$viewId, frontCamera=$frontCamera');
    
    // 设置本地预览渲染参数
    _trtcCloud!.setLocalRenderParams(TRTCRenderParams(
      fillMode: TRTCVideoFillMode.fill,
      mirrorType: TRTCVideoMirrorType.auto,
      rotation: TRTCVideoRotation.rotation0,
    ));
    
    _isFrontCamera.value = frontCamera;
    _trtcCloud!.startLocalPreview(frontCamera, viewId);
    _isLocalVideoEnabled.value = true;

    // 应用美颜效果
    if (_isBeautyEnabled.value) {
      _applyBeautyStyle();
    }
  }

  /// 停止本地视频预览
  Future<void> stopLocalPreview() async {
    if (_trtcCloud == null) return;

    debugPrint('[TRTC] 停止本地视频预览');
    _trtcCloud!.stopLocalPreview();
    _isLocalVideoEnabled.value = false;
  }

  /// 开始远端视频渲染
  Future<void> startRemoteView({
    required String userId,
    required int viewId,
    TRTCVideoStreamType streamType = TRTCVideoStreamType.big,
  }) async {
    if (_trtcCloud == null) return;

    debugPrint('[TRTC] 开始远端视频渲染: userId=$userId, viewId=$viewId');
    
    // 设置远端渲染参数
    _trtcCloud!.setRemoteRenderParams(userId, streamType, TRTCRenderParams(
      fillMode: TRTCVideoFillMode.fill,
      mirrorType: TRTCVideoMirrorType.disable,
      rotation: TRTCVideoRotation.rotation0,
    ));
    
    _trtcCloud!.startRemoteView(userId, streamType, viewId);
  }

  /// 停止远端视频渲染
  Future<void> stopRemoteView({
    required String userId,
    TRTCVideoStreamType streamType = TRTCVideoStreamType.big,
  }) async {
    if (_trtcCloud == null) return;

    debugPrint('[TRTC] 停止远端视频渲染: userId=$userId');
    _trtcCloud!.stopRemoteView(userId, streamType);
  }

  /// 更新本地视频渲染视图（用于切换全屏/小窗时重新绑定）
  void updateLocalView(int viewId) {
    if (_trtcCloud == null) return;
    debugPrint('[TRTC] 更新本地视频视图: viewId=$viewId');
    _trtcCloud!.updateLocalView(viewId);
  }

  /// 更新远端视频渲染视图（用于切换全屏/小窗时重新绑定）
  void updateRemoteView({
    required String userId,
    required int viewId,
    TRTCVideoStreamType streamType = TRTCVideoStreamType.big,
  }) {
    if (_trtcCloud == null) return;
    debugPrint('[TRTC] 更新远端视频视图: userId=$userId, viewId=$viewId');
    _trtcCloud!.updateRemoteView(userId, streamType, viewId);
  }

  Completer<void>? _exitRoomCompleter;

  /// 退出房间
  /// 会等待 onExitRoom 回调完成后再返回，避免 TextureView 未释放导致 log 刷屏
  Future<void> exitRoom() async {
    if (_trtcCloud == null) return;

    debugPrint('[TRTC] 退出房间');
    _exitRoomCompleter = Completer<void>();

    // 先停止本地预览和远端渲染，再退出房间
    _trtcCloud!.stopLocalAudio();
    _trtcCloud!.stopLocalPreview();
    for (final userId in List<String>.from(_remoteUsers)) {
      _trtcCloud!.stopRemoteView(userId, TRTCVideoStreamType.big);
    }
    _trtcCloud!.exitRoom();

    // 等待 onExitRoom 回调后再返回，避免 TextureView 未释放导致 log 刷屏
    try {
      await _exitRoomCompleter!.future.timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          debugPrint('[TRTC] exitRoom 等待 onExitRoom 超时');
        },
      );
    } on TimeoutException catch (_) {
      // 超时也继续，不阻塞后续流程
    } finally {
      _exitRoomCompleter = null;
    }
  }

  // ============ 音视频控制 ============

  /// 切换摄像头
  Future<void> switchCamera() async {
    if (_deviceManager == null) return;

    _isFrontCamera.value = !_isFrontCamera.value;
    await _deviceManager!.switchCamera(_isFrontCamera.value);
    debugPrint('[TRTC] 切换摄像头: 前置=$_isFrontCamera');
  }

  /// 设置本地视频开关
  Future<void> setLocalVideoEnabled(bool enabled) async {
    if (_trtcCloud == null) return;

    if (enabled) {
      // 恢复视频需要重新调用 startLocalPreview
      // 这里通过静音本地视频来实现
      _trtcCloud!.muteLocalVideo(TRTCVideoStreamType.big, false);
    } else {
      _trtcCloud!.muteLocalVideo(TRTCVideoStreamType.big, true);
    }
    _isLocalVideoEnabled.value = enabled;
    debugPrint('[TRTC] 本地视频: enabled=$enabled');
  }

  /// 设置本地音频开关
  Future<void> setLocalAudioEnabled(bool enabled) async {
    if (_trtcCloud == null) return;

    _trtcCloud!.muteLocalAudio(!enabled);
    _isLocalAudioEnabled.value = enabled;
    debugPrint('[TRTC] 本地音频: enabled=$enabled');
  }

  /// 静音远端音频
  Future<void> muteRemoteAudio(String userId, bool mute) async {
    if (_trtcCloud == null) return;

    _trtcCloud!.muteRemoteAudio(userId, mute);
    debugPrint('[TRTC] 远端音频静音: userId=$userId, mute=$mute');
  }

  /// 静音所有远端音频
  Future<void> muteAllRemoteAudio(bool mute) async {
    if (_trtcCloud == null) return;

    _trtcCloud!.muteAllRemoteAudio(mute);
    debugPrint('[TRTC] 所有远端音频静音: mute=$mute');
  }

  // ============ 美颜 ============

  /// 应用 TRTCBeautyStyle 基础美颜（磨皮/美白/红润）
  void _applyBeautyStyle() {
    if (_trtcCloud == null) return;

    _trtcCloud!.setBeautyStyle(
      _beautyStyle,
      _beautyLevel,
      _whitenessLevel,
      _ruddinessLevel,
    );
    debugPrint('[TRTC] 美颜已应用: style=$_beautyStyle, beauty=$_beautyLevel, white=$_whitenessLevel, ruddy=$_ruddinessLevel');
  }

  /// 设置美颜开关
  Future<void> setBeautyEnabled(bool enabled) async {
    _isBeautyEnabled.value = enabled;

    if (_trtcCloud != null) {
      if (enabled) {
        _applyBeautyStyle();
      } else {
        _trtcCloud!.setBeautyStyle(
          _beautyStyle,
          0,
          0,
          0,
        );
      }
    }
    await _saveBeautySettings();
    debugPrint('[TRTC] 美颜: enabled=$enabled');
  }

  /// 设置美颜风格与等级（0-9）
  /// [style] smooth=磨皮明显, nature=自然
  Future<void> setBeautyStyle(
    TRTCBeautyStyle style, {
    int beautyLevel = 5,
    int whitenessLevel = 5,
    int ruddinessLevel = 5,
  }) async {
    _beautyStyle = style;
    _beautyLevel = beautyLevel.clamp(0, 9);
    _whitenessLevel = whitenessLevel.clamp(0, 9);
    _ruddinessLevel = ruddinessLevel.clamp(0, 9);

    if (_trtcCloud != null && _isBeautyEnabled.value) {
      _applyBeautyStyle();
    }
    await _saveBeautySettings();
  }

  // ============ 销毁 ============

  /// 销毁资源
  Future<void> destroy() async {
    debugPrint('[TRTC] 销毁资源');

    if (_isInRoom.value) {
      await exitRoom();
    }

    // 清除回调
    onRemoteUserEnterRoom = null;
    onRemoteUserLeaveRoom = null;
    onUserVideoAvailable = null;
    onUserVideoAvailableChanged = null;
    onUserAudioAvailable = null;
    onEnterRoom = null;
    onExitRoom = null;
    onError = null;
    onNetworkQuality = null;
    onFirstVideoFrame = null;

    // 销毁 TRTC 实例
    if (_trtcCloud != null) {
      if (_listener != null) {
        _trtcCloud!.unRegisterListener(_listener!);
        _listener = null;
      }
      TRTCCloud.destroySharedInstance();
      _trtcCloud = null;
    }

    _deviceManager = null;
    _audioEffectManager = null;
    _isInitialized.value = false;
    _remoteUsers.clear();
  }

  @override
  void onClose() {
    destroy();
    super.onClose();
  }
}

/// 创建本地视频 Widget
class TRTCLocalVideoView extends StatelessWidget {
  final Function(int viewId) onViewCreated;

  const TRTCLocalVideoView({
    super.key,
    required this.onViewCreated,
  });

  @override
  Widget build(BuildContext context) {
    return TRTCCloudVideoView(
      onViewCreated: (viewId) {
        onViewCreated(viewId);
      },
    );
  }
}

/// 创建远端视频 Widget
class TRTCRemoteVideoView extends StatelessWidget {
  final String userId;
  final Function(int viewId) onViewCreated;
  final TRTCVideoStreamType streamType;

  const TRTCRemoteVideoView({
    super.key,
    required this.userId,
    required this.onViewCreated,
    this.streamType = TRTCVideoStreamType.big,
  });

  @override
  Widget build(BuildContext context) {
    return TRTCCloudVideoView(
      onViewCreated: (viewId) {
        onViewCreated(viewId);
      },
    );
  }
}
