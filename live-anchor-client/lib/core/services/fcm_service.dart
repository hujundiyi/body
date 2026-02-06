import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:weeder/core/services/im_service.dart';

/// FCM 推送服务：申请权限、获取 Token、处理前台/后台消息
/// 后台消息需在 main 中注册 [firebaseMessagingBackgroundHandler]
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (kDebugMode) {
    debugPrint('[FCM] Background: ${message.messageId}');
  }
}

class FCMService extends GetxService {
  static FCMService get shared => Get.find<FCMService>();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// 当前 FCM Token（可上报给后端用于推送目标）
  String? get fcmToken => _fcmToken;
  String? _fcmToken;

  Future<FCMService> init() async {
    // 请求通知权限（Android 13+ 需要）
    await _requestPermission();

    // 设置前台展示选项（可选：前台也弹通知）
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 后台消息回调（必须在 runApp 前调用 setBackgroundMessageHandler）
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 前台消息
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // 用户点击通知打开应用
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);

    // 应用由通知冷启动（getInitialMessage 只生效一次）
    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      _handleNotificationTap(initial);
    }

    // 获取并缓存 Token
    await _refreshToken();

    // 将 FCM Token 注册到腾讯 IM（Android 离线推送）
    _registerFCMTokenToIM();

    // Token 刷新时：上报后端并重新注册到腾讯 IM
    _messaging.onTokenRefresh.listen((token) {
      _fcmToken = token;
      if (kDebugMode) debugPrint('[FCM] Token refreshed: ${token.substring(0, 20)}...');
      _onTokenRefreshed(token);
      _registerFCMTokenToIM();
    });

    return this;
  }

  /// 将当前 FCM Token 注册到腾讯云 IM（仅 Android 使用 FCM）
  void _registerFCMTokenToIM() {
    if (!Platform.isAndroid) return;
    final token = _fcmToken;
    if (token == null || token.isEmpty) return;
    if (!Get.isRegistered<IMService>()) return;
    Get.find<IMService>().registerOfflinePushToken(token, isTPNSToken: false);
  }

  Future<void> _requestPermission() async {
    if (!Platform.isAndroid) {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (kDebugMode) {
        debugPrint('[FCM] Permission: ${settings.authorizationStatus}');
      }
      return;
    }
    // Android 13+ 由 firebase_messaging 内部申请 POST_NOTIFICATIONS
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (kDebugMode) {
      debugPrint('[FCM] Permission: ${settings.authorizationStatus}');
    }
  }

  void _onForegroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      debugPrint('[FCM] Foreground: ${message.messageId}');
      debugPrint('[FCM] Title: ${message.notification?.title}');
      debugPrint('[FCM] Body: ${message.notification?.body}');
      debugPrint('[FCM] Data: ${message.data}');
    }
    // 可在此处显示应用内弹窗或更新 UI
  }

  void _onMessageOpenedApp(RemoteMessage message) {
    _handleNotificationTap(message);
  }

  void _handleNotificationTap(RemoteMessage message) {
    if (kDebugMode) {
      debugPrint('[FCM] Opened from notification: ${message.data}');
    }
    // 根据 message.data 跳转页面，例如：conversationID、callId 等
    final data = message.data;
    if (data.isEmpty) return;
    // 示例：若有 conversationID 可跳转到聊天页
    // if (data['conversationID'] != null) Get.toNamed(AppRoutes.messageChat, arguments: data);
  }

  /// Token 刷新时回调（子类或外部可覆盖，用于上报后端）
  void _onTokenRefreshed(String token) {}

  /// 主动刷新 FCM Token 并返回
  Future<String?> refreshToken() async {
    await _refreshToken();
    return _fcmToken;
  }

  Future<void> _refreshToken() async {
    try {
      _fcmToken = await _messaging.getToken();
      if (kDebugMode && _fcmToken != null) {
        debugPrint('[FCM] Token: ${_fcmToken!.substring(0, 20)}...');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[FCM] getToken error: $e');
    }
  }
}
