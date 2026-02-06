import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../core/base/base_controller.dart';
import '../../core/services/auth_service.dart';
import '../../core/network/anchor_api_service.dart';
import '../../data/models/anchor_model.dart';
import '../../routes/app_routes.dart';

/// 启动时直接根据认证状态跳转（无启动页、无延迟）
class InitialRedirectController extends BaseController {
  final AuthService _authService = Get.find<AuthService>();

  @override
  void onControllerReady() {
    super.onControllerReady();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    if (_authService.isAuthenticated) {
      try {
        final anchor = await AnchorAPIService.shared.getAnchorInfo();
        await _navigateByAuditStatus(anchor);
      } catch (e) {
        debugPrint('获取主播信息失败: $e');
        if (Get.currentRoute != AppRoutes.anchorLogin) {
          AppRoutes.goToAnchorLogin();
        }
      }
    } else {
      if (Get.currentRoute != AppRoutes.anchorLogin) {
        AppRoutes.goToAnchorLogin();
      }
    }
  }

  Future<void> _navigateByAuditStatus(AnchorModel anchor) async {
    if (anchor.auditStatus == 2 || anchor.auditStatus == 3) {
      await _authService.logout();
      AppRoutes.goToAnchorLogin();
      return;
    }
    if (anchor.auditStatus == 0) {
      Get.offAllNamed(AppRoutes.mainTab);
      return;
    }
    if (anchor.auditStatus == 1) {
      final arguments = <String, dynamic>{};
      if (anchor.auditReason != null && anchor.auditReason!.isNotEmpty) {
        arguments['reason'] = anchor.auditReason;
      }
      Get.offAllNamed(AppRoutes.anchorApply, arguments: arguments.isEmpty ? null : arguments);
    } else {
      Get.offAllNamed(AppRoutes.mainTab);
    }
  }
}
