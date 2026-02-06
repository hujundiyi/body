import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/base/base_controller.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/toast_utils.dart';
import '../../data/models/anchor_model.dart';
import '../../routes/app_routes.dart';

/// 主播登录控制器
class AnchorLoginController extends BaseController {
  // 表单控制器
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // 表单状态
  final RxBool _obscurePassword = true.obs;
  bool get obscurePassword => _obscurePassword.value;

  // 记住密码
  final RxBool _rememberPassword = false.obs;
  bool get rememberPassword => _rememberPassword.value;

  // 当前登录的主播信息
  final Rx<AnchorModel?> _anchorInfo = Rx<AnchorModel?>(null);
  AnchorModel? get anchorInfo => _anchorInfo.value;

  @override
  void onControllerInit() {
    super.onControllerInit();
    _loadSavedCredentials();
  }

  @override
  void onControllerClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onControllerClose();
  }

  /// 加载保存的凭证
  void _loadSavedCredentials() {
    try {
      final storage = Get.find<StorageService>();
      final savedEmail = storage.getString('saved_email');
      final savedPassword = storage.getString('saved_password');

      if (savedEmail != null && savedPassword != null) {
        emailController.text = savedEmail;
        passwordController.text = savedPassword;
        _rememberPassword.value = true;
      }
    } catch (e) {
      debugPrint('Failed to load credentials: $e');
    }
  }

  /// 保存凭证
  void _saveCredentials() {
    try {
      final storage = Get.find<StorageService>();
      if (_rememberPassword.value) {
        storage.setString('saved_email', emailController.text.trim());
        storage.setString('saved_password', passwordController.text.trim());
      } else {
        storage.remove('saved_email');
        storage.remove('saved_password');
      }
    } catch (e) {
      debugPrint('Failed to save credentials: $e');
    }
  }

  /// 切换密码可见性
  void togglePasswordVisibility() {
    _obscurePassword.value = !_obscurePassword.value;
  }

  /// 切换记住密码
  void toggleRememberPassword() {
    _rememberPassword.value = !_rememberPassword.value;
  }

  /// Email validation
  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter email';
    }
    final emailRegex = RegExp(AppConstants.emailRegex);
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  /// Password validation（6-18 位）
  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter password';
    }
    if (value.length < AppConstants.minPasswordLength) {
      return 'Password must be 6-18 characters';
    }
    if (value.length > AppConstants.maxPasswordLength) {
      return 'Password must be 6-18 characters';
    }
    return null;
  }

  /// 登录
  Future<void> login() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    await executeWithLoading(() async {
      try {
        final authService = Get.find<AuthService>();
        final success = await authService.login(username: email, password: password);
        if (success) {
          final anchor = authService.userInfo;
          _anchorInfo.value = anchor;

          // 保存凭证
          _saveCredentials();

          // 根据审核状态跳转
          if (anchor != null) {
            await _navigateByAuditStatus(anchor);
          }
        }
        // 登录失败时的 Toast 已在 AuthService.login 中按 API 错误信息弹出
      } catch (e) {
        showError(e.toString());
      }
    });
  }

  /// 根据审核状态跳转
  Future<void> _navigateByAuditStatus(AnchorModel anchor) async {
    final status = anchor.auditStatus;
    // auditStatus == 2：审核中，弹窗提示，不进 apply_page
    if (status == 2) {
      await _clearAuthAndShowUnderReviewDialog();
      return;
    }
    // auditStatus == 3：未通过审核，弹窗提示，不进 apply_page
    if (status == 3) {
      await _clearAuthAndShowNotApprovedDialog();
      return;
    }
    // auditStatus == 0：进入首页
    if (status == 0) {
      Get.offAllNamed(AppRoutes.mainTab);
      return;
    }
    // auditStatus == 1：进入资料申请页面，并带入登录返回的主播信息用于预填
    final arguments = <String, dynamic>{'anchor': anchor.toJson()};
    if (anchor.auditReason != null && anchor.auditReason!.isNotEmpty) {
      arguments['reason'] = anchor.auditReason;
    }
    Get.offAllNamed(AppRoutes.anchorApply, arguments: arguments);
  }

  /// auditStatus==2：清除登录态并弹窗「Account Under Review」
  Future<void> _clearAuthAndShowUnderReviewDialog() async {
    final authService = Get.find<AuthService>();
    await authService.logout();
    Get.dialog(
      _buildCenterDialog(
        title: 'Account Under Review',
        content:
            'Your account is under review and temporarily unavailable.\nPlease contact your Agency if you need assistance.',
      ),
      barrierDismissible: false,
    );
  }

  /// auditStatus==3：清除登录态并弹窗「Account Not Approved」
  Future<void> _clearAuthAndShowNotApprovedDialog() async {
    final authService = Get.find<AuthService>();
    await authService.logout();
    Get.dialog(
      _buildCenterDialog(
        title: 'Account Not Approved',
        content:
            'Your account did not pass the review and cannot be accessed.\nPlease contact your Agency for further assistance.',
      ),
      barrierDismissible: false,
    );
  }

  Widget _buildCenterDialog({required String title, required String content}) {
    return Dialog(
      backgroundColor: const Color(0xFF2A2A4A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              content,
              style: TextStyle(color: Colors.grey[300], fontSize: 14, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF1493),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Got It'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 跳转到注册页面
  void goToRegister() {
    Get.toNamed(AppRoutes.register);
  }

  /// Forgot password
  void forgotPassword() {
    showInfo('Please contact customer service to reset your password');
  }
}
