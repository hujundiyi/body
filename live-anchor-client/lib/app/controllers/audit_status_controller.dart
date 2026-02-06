import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/base/base_controller.dart';
import '../../core/network/anchor_api_service.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/anchor_model.dart';
import '../../routes/app_routes.dart';

/// 审核状态控制器
class AuditStatusController extends BaseController {
  // 主播信息
  final Rx<AnchorModel?> anchorInfo = Rx<AnchorModel?>(null);

  // 审核状态
  final Rx<int?> auditStatus = Rx<int?>(null);

  // 审核原因
  final RxString auditReason = ''.obs;

  // 定时器（用于自动刷新）
  Timer? _refreshTimer;

  @override
  void onControllerInit() {
    super.onControllerInit();
    _loadAuditStatus();
    _startAutoRefresh();
  }

  @override
  void onControllerClose() {
    _refreshTimer?.cancel();
    super.onControllerClose();
  }

  /// 加载审核状态
  Future<void> _loadAuditStatus() async {
    await executeWithLoading(() async {
      try {
        final anchor = await AnchorAPIService.shared.getAnchorInfo();
        anchorInfo.value = anchor;
        auditStatus.value = anchor.auditStatus;
        auditReason.value = anchor.auditReason ?? '';

        // 如果审核通过，自动跳转
        if (anchor.isApproved) {
          _refreshTimer?.cancel();
          Get.offAllNamed(AppRoutes.mainTab);
        }
      } catch (e) {
        debugPrint('Failed to get audit status: $e');
        showErrorUnlessAuth(e, 'Failed to get audit status');
      }
    });
  }

  /// 开始自动刷新（每30秒刷新一次）
  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _loadAuditStatus();
    });
  }

  /// 手动刷新
  @override
  Future<void> refresh() async {
    await _loadAuditStatus();
  }

  /// 重新提交申请
  void resubmit() {
    Get.offAllNamed(AppRoutes.anchorApply, arguments: {'resubmit': true, 'reason': auditReason.value});
  }

  /// 退出登录
  Future<void> logout() async {
    try {
      await AnchorAPIService.shared.loginOut();
    } catch (e) {
      debugPrint('Failed to logout: $e');
    }
    AppRoutes.goToAnchorLogin();
  }

  /// Contact support
  void contactSupport() {
    showInfo('Please contact customer service via WhatsApp: +1234567890');
  }

  /// Get status title
  String get statusTitle {
    switch (auditStatus.value) {
      case AuditStatus.pending:
        return 'Under Review';
      case AuditStatus.approved:
        return 'Approved';
      case AuditStatus.rejected:
        return 'Rejected';
      default:
        return 'Loading...';
    }
  }

  /// Get status description
  String get statusDescription {
    switch (auditStatus.value) {
      case AuditStatus.pending:
        return 'Your application is under review, please wait patiently\nEstimated review time: within 24 hours';
      case AuditStatus.approved:
        return 'Congratulations! Your application has been approved\nRedirecting to homepage...';
      case AuditStatus.rejected:
        return 'Sorry, your application was not approved\nPlease modify according to the following reasons and resubmit';
      default:
        return 'Getting review status...';
    }
  }

  /// 获取状态颜色
  Color get statusColor {
    switch (auditStatus.value) {
      case AuditStatus.pending:
        return Colors.orange;
      case AuditStatus.approved:
        return Colors.green;
      case AuditStatus.rejected:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// 获取状态图标
  IconData get statusIcon {
    switch (auditStatus.value) {
      case AuditStatus.pending:
        return Icons.hourglass_top;
      case AuditStatus.approved:
        return Icons.check_circle;
      case AuditStatus.rejected:
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }
}
