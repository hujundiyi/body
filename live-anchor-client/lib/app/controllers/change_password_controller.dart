import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/base/base_controller.dart';
import '../../core/network/anchor_api_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/utils/toast_utils.dart';
import '../../routes/app_routes.dart';

/// 修改密码页控制器
class ChangePasswordController extends BaseController {
  final emailController = TextEditingController();
  final oldPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();

  final RxBool _obscureOld = true.obs;
  final RxBool _obscureNew = true.obs;
  bool get obscureOld => _obscureOld.value;
  bool get obscureNew => _obscureNew.value;

  @override
  void onControllerInit() {
    super.onControllerInit();
    final auth = Get.find<AuthService>();
    final email = auth.userInfo?.email ?? auth.userInfo?.nickname ?? '';
    emailController.text = email;
  }

  @override
  void onControllerClose() {
    emailController.dispose();
    oldPasswordController.dispose();
    newPasswordController.dispose();
    super.onControllerClose();
  }

  void toggleObscureOld() => _obscureOld.value = !_obscureOld.value;
  void toggleObscureNew() => _obscureNew.value = !_obscureNew.value;

  Future<void> submit() async {
    final oldPwd = oldPasswordController.text.trim();
    final newPwd = newPasswordController.text.trim();
    if (oldPwd.isEmpty) {
      showError('Please enter current password');
      return;
    }
    if (oldPwd.length < 6 || oldPwd.length > 18) {
      showError('Password must be 6-18 characters');
      return;
    }
    if (newPwd.isEmpty) {
      showError('Please enter new password');
      return;
    }
    if (newPwd.length < 6 || newPwd.length > 18) {
      showError('Password must be 6-18 characters');
      return;
    }
    await executeWithLoading(() async {
      try {
        await AnchorAPIService.shared.changePassword(oldPassword: oldPwd, newPassword: newPwd);
        ToastUtils.showSuccess('Password changed successfully');
        final auth = Get.find<AuthService>();
        await auth.logout();
        AppRoutes.goToAnchorLogin();
      } catch (e) {
        showErrorUnlessAuth(e, 'Failed to change password: ${e.toString()}');
      }
    });
  }
}
