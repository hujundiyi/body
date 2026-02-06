import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../network/api_exception.dart';
import '../utils/toast_utils.dart';

/// 基础控制器类
/// 提供通用的状态管理和生命周期方法
abstract class BaseController extends GetxController {
  // 加载状态
  final RxBool _isLoading = false.obs;
  bool get isLoading => _isLoading.value;
  
  // 错误状态
  final RxString _errorMessage = ''.obs;
  String get errorMessage => _errorMessage.value;
  
  // 是否有错误
  bool get hasError => _errorMessage.value.isNotEmpty;
  
  @override
  void onInit() {
    super.onInit();
    onControllerInit();
  }
  
  @override
  void onReady() {
    super.onReady();
    onControllerReady();
  }
  
  @override
  void onClose() {
    onControllerClose();
    super.onClose();
  }
  
  /// 控制器初始化时调用
  void onControllerInit() {}
  
  /// 控制器准备就绪时调用
  void onControllerReady() {}
  
  /// 控制器销毁时调用
  void onControllerClose() {}
  
  /// 设置加载状态
  void setLoading(bool loading) {
    _isLoading.value = loading;
  }
  
  /// 设置错误信息
  void setError(String error) {
    _errorMessage.value = error;
  }
  
  /// 清除错误信息
  void clearError() {
    _errorMessage.value = '';
  }
  
  /// 显示加载状态并执行异步操作
  /// 401/403 不设置错误信息、不弹窗，由 api_client 统一跳转登录页
  Future<T?> executeWithLoading<T>(Future<T> Function() operation) async {
    try {
      setLoading(true);
      clearError();
      final result = await operation();
      return result;
    } catch (e) {
      if (e is! APIException || (e.code != 401 && e.code != 403)) {
        setError(e.toString());
      }
      return null;
    } finally {
      setLoading(false);
    }
  }

  /// 是否为 401/403 认证错误（此类错误不弹顶部提示，由 api_client 跳转登录）
  static bool isAuthError(dynamic e) =>
      e is APIException && (e.code == 401 || e.code == 403);

  /// 显示错误提示；若为 401/403 则不弹窗
  void showErrorUnlessAuth(dynamic e, [String? fallbackMessage]) {
    if (isAuthError(e)) return;
    final msg = fallbackMessage ?? (e is APIException ? e.message : e.toString());
    showError(msg);
  }
  
  /// 显示成功消息
  void showSuccess(String message) {
    ToastUtils.showSuccess(message);
  }
  
  /// 显示错误消息
  void showError(String message) {
    ToastUtils.showError(message);
  }
  
  /// 显示警告消息
  void showWarning(String message) {
    ToastUtils.showWarning(message);
  }
  
  /// 显示提示消息
  void showInfo(String message) {
    ToastUtils.showInfo(message);
  }
  
  /// 显示确认对话框
  Future<bool?> showConfirmDialog({
    required String title,
    required String content,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
  }) {
    return Get.dialog<bool>(
      AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(cancelText),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }
}
