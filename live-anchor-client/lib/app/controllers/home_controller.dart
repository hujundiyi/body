import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/base/base_controller.dart';
import '../../core/services/auth_service.dart';
import '../../data/models/user_model_entity.dart';

/// 主页控制器
class HomeController extends BaseController {
  final AuthService _authService = Get.find<AuthService>();
  
  // 用户信息
  final Rx<UserModelEntity?> _user = Rx<UserModelEntity?>(null);
  UserModelEntity? get user => _user.value;
  
  // 计数器
  final RxInt _counter = 0.obs;
  int get counter => _counter.value;
  
  @override
  void onControllerReady() {
    super.onControllerReady();
    _loadUserInfo();
  }
  
  /// 加载用户信息
  void _loadUserInfo() {
    if (_authService.isAuthenticated) {
      // 这里可以从服务中获取用户信息

    }
  }
  
  /// 增加计数器
  void incrementCounter() {
    _counter.value++;
  }
  
  /// 减少计数器
  void decrementCounter() {
    _counter.value--;
  }
  
  /// 重置计数器
  void resetCounter() {
    _counter.value = 0;
  }
  
  /// User logout
  Future<void> logout() async {
    final confirmed = await showConfirmDialog(
      title: 'Confirm Logout',
      content: 'Are you sure you want to logout?',
    );
    
    if (confirmed == true) {
      await executeWithLoading(() async {
        await _authService.logout();
        Get.offAllNamed('/splash');
      });
    }
  }
  
  /// Show user info
  void showUserInfo() {
    if (_user.value != null) {
      Get.dialog(
        AlertDialog(
          title: const Text('User Info'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Username: ${_user.value!.nickname}'),
              Text('Email: ${_user.value!.email}'),
              Text('ID: ${_user.value!.userId}'),
            ],
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
}
