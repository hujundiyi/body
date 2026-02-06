import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/base/base_controller.dart';
import '../../core/services/auth_service.dart';
import '../../core/utils/validators.dart';
import '../../routes/app_routes.dart';
import '../../data/models/anchor_model.dart';

/// 注册控制器
class RegisterController extends BaseController {
  final AuthService _authService = Get.find<AuthService>();
  
  // 表单控制器
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final invitationCodeController = TextEditingController();
  
  // 表单状态
  final RxBool _obscurePassword = true.obs;
  bool get obscurePassword => _obscurePassword.value;
  
  final RxBool _obscureConfirmPassword = true.obs;
  bool get obscureConfirmPassword => _obscureConfirmPassword.value;
  
  // 同意条款
  final RxBool _agreeTerms = false.obs;
  bool get agreeTerms => _agreeTerms.value;
  
  @override
  void onControllerClose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    invitationCodeController.dispose();
    super.onControllerClose();
  }
  
  /// 切换密码可见性
  void togglePasswordVisibility() {
    _obscurePassword.value = !_obscurePassword.value;
  }
  
  /// 切换确认密码可见性
  void toggleConfirmPasswordVisibility() {
    _obscureConfirmPassword.value = !_obscureConfirmPassword.value;
  }
  
  /// 切换同意条款
  void toggleAgreeTerms() {
    _agreeTerms.value = !_agreeTerms.value;
  }
  
  /// 邮箱验证
  String? validateEmail(String? value) {
    return Validators.email(value);
  }
  
  /// 密码验证
  String? validatePassword(String? value) {
    return Validators.password(value);
  }
  
  /// 确认密码验证
  String? validateConfirmPassword(String? value) {
    return Validators.confirmPassword(value, passwordController.text);
  }
  
  /// 注册
  Future<void> register() async {
    if (!formKey.currentState!.validate()) {
      return;
    }
    
    if (!_agreeTerms.value) {
      showError('Please agree to the Terms of Service and Privacy Policy first');
      return;
    }
    
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final invitationCode = invitationCodeController.text.trim().isEmpty 
        ? null 
        : invitationCodeController.text.trim();
    
    await executeWithLoading(() async {
      final anchor = await _authService.register(
        email: email,
        password: password,
        invitationCode: invitationCode,
      );
      
      if (anchor != null) {
        showSuccess('Registration successful');
        // 根据审核状态跳转
        _navigateByAuditStatus(anchor);
      } else {
        showError('Registration failed, please try again');
      }
    });
  }
  
  /// 根据审核状态跳转
  void _navigateByAuditStatus(AnchorModel anchor) {
    // 根据 auditStatus 字段判断
    // auditStatus 为 0 进入首页，非 0 进入资料申请页面
    if (anchor.auditStatus == 0) {
      // auditStatus 为 0，进入首页
      Get.offAllNamed(AppRoutes.mainTab);
    } else {
      // auditStatus 非 0，进入资料申请页面
      // 如果 auditReason 不为空，传递审核原因
      final arguments = <String, dynamic>{};
      if (anchor.auditReason != null && anchor.auditReason!.isNotEmpty) {
        arguments['reason'] = anchor.auditReason;
      }
      // 使用 offNamed 移除注册页面，保留登录页面在栈中
      Get.offNamed(AppRoutes.anchorApply, arguments: arguments.isEmpty ? null : arguments);
    }
  }
  
  /// 返回登录页面
  void goToLogin() {
    Get.back();
  }
  
  /// View user agreement
  void viewUserAgreement() {
    Get.dialog(
      AlertDialog(
        title: const Text('Terms of Service'),
        content: const SingleChildScrollView(
          child: Text(
            'Terms of Service content...\n\n'
            '1. User Rights and Obligations\n'
            '2. Service Terms\n'
            '3. Privacy Protection\n'
            '4. Disclaimer\n\n'
            'Please view the full agreement for details.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  /// View privacy policy
  void viewPrivacyPolicy() {
    Get.dialog(
      AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'Privacy Policy content...\n\n'
            '1. Information Collection\n'
            '2. Information Usage\n'
            '3. Information Protection\n'
            '4. Information Sharing\n\n'
            'Please view the full policy for details.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
