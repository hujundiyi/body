import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tencent_cloud_chat_push/tencent_cloud_chat_push.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/app_config_service.dart';
import '../../core/services/im_service.dart';
import '../../core/network/anchor_api_service.dart';
import '../../routes/app_routes.dart';
import '../widgets/app_update_dialog.dart';

/// 主 Tab 控制器
class MainTabController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();

  // 当前选中的 Tab 索引
  final RxInt currentIndex = 0.obs;

  // PageController 用于页面切换
  late PageController pageController;

  /// 腾讯云 IM 离线推送是否已注册（避免重复注册）
  static bool _pushRegistered = false;

  Worker? _imLoginWorker;

  @override
  void onInit() {
    super.onInit();
    pageController = PageController(initialPage: currentIndex.value);
  }

  @override
  void onReady() {
    super.onReady();
    _callToHome();
    _checkAppUpdate();
    _registerTencentPushWhenImReady();
    if (currentIndex.value == meTabIndex) {
      _authService.refreshUserProfile();
    }
  }

  /// 必须在 IM 登录成功后再调用 registerPush，否则后台收不到「证书ID + 设备Token」上报
  void _registerTencentPushWhenImReady() {
    if (_pushRegistered) return;
    final config = Get.find<AppConfigService>();
    final sdkAppId = config.tencentChatAppId;
    final appKey = 'dOYIAPOgcXdBbW9ZbI3v9PIOIWvmbzelKVWgV2shQzcsxPMEBtSm0IGxZAy1pLbj';
    if (sdkAppId <= 0 || appKey.isEmpty) {
      if (kDebugMode) debugPrint('[Push] 未配置 sdkAppId 或 tencentChatPushId，跳过注册');
      return;
    }
    final imService = Get.find<IMService>();
    if (imService.isLoggedIn) {
      _doRegisterTencentPush(sdkAppId: sdkAppId, appKey: appKey);
      return;
    }
    _imLoginWorker = ever(imService.isLoggedInRx, (bool loggedIn) {
      if (loggedIn && !_pushRegistered) _doRegisterTencentPush(sdkAppId: sdkAppId, appKey: appKey);
    });
  }

  void _doRegisterTencentPush({required int sdkAppId, required String appKey}) {
    if (_pushRegistered) return;
    _pushRegistered = true;
    _imLoginWorker?.dispose();
    _imLoginWorker = null;
    const apnsCertificateID = 8778;
    if (kDebugMode) debugPrint('[Push] IM 已登录，开始注册离线推送 sdkAppId=$sdkAppId');
    TencentCloudChatPush().registerPush(
      onNotificationClicked: _onNotificationClicked,
      sdkAppId: sdkAppId,
      appKey: appKey,
      apnsCertificateID: Platform.isIOS ? apnsCertificateID : 0,
    );
  }

  /// 推送通知点击回调：跳转到对应聊天页
  void _onNotificationClicked({required String ext, String? userID, String? groupID}) {
    String? conversationID;
    final args = <String, dynamic>{};
    if (userID != null && userID.isNotEmpty) {
      conversationID = 'c2c_$userID';
      args['conversationID'] = conversationID;
      args['userID'] = userID;
    } else if (groupID != null && groupID.isNotEmpty) {
      conversationID = 'group_$groupID';
      args['conversationID'] = conversationID;
      args['groupID'] = groupID;
    }
    if (conversationID == null || conversationID.isEmpty) return;
    args['name'] = 'User';
    args['avatar'] = '';
    if (Get.currentRoute != AppRoutes.mainTab) {
      Get.offAllNamed(AppRoutes.mainTab);
    }
    Get.toNamed(AppRoutes.messageChat, arguments: args);
  }

  /// Tab 出现时调用 authorize/toHome
  void _callToHome() {
    AnchorAPIService.shared.toHome().catchError((_) {});
  }

  /// 进入主 Tab 时：先检查是否有未完成/已下载未安装的更新，有则直接弹下载/安装浮层；否则再请求 init/getAppUpdate
  Future<void> _checkAppUpdate() async {
    final showedPending = await checkPendingUpdateAndShowOverlayIfNeeded();
    if (showedPending) return;
    final update = await AnchorAPIService.shared.getAppUpdate();
    if (update != null) {
      showAppUpdateDialog(update);
    }
  }

  @override
  void onClose() {
    _imLoginWorker?.dispose();
    _imLoginWorker = null;
    pageController.dispose();
    super.onClose();
  }

  /// Me 页在 Tab 中的索引，用于进入时拉取用户资料详情（following、follower 等）
  static const int meTabIndex = 4;

  /// Work 页在 Tab 中的索引，用于进入时拉取用户信息并同步腾讯在线状态
  static const int workTabIndex = 2;

  /// 切换 Tab
  void switchTab(int index) {
    currentIndex.value = index;
    pageController.jumpToPage(index);
    if (index == meTabIndex) {
      _authService.refreshUserProfile();
    }
    if (index == workTabIndex && Get.isRegistered<IMService>()) {
      Get.find<IMService>().onWorkTabSelected?.call();
    }
  }

  /// User logout
  Future<void> logout() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: const Text('Cancel')),
          TextButton(onPressed: () => Get.back(result: true), child: const Text('Confirm')),
        ],
      ),
    );

    if (confirmed == true) {
      _pushRegistered = false; // 登出后重置，下次进入首页会重新注册推送
      await _authService.logout();
      Get.offAllNamed('/splash');
    }
  }
}
