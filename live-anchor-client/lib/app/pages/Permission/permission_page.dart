import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/permission_controller.dart';

/// 权限设置页面
class PermissionPage extends StatelessWidget {
  const PermissionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PermissionController>();

    return Scaffold(
      backgroundColor: const Color(0xFF1A0D2E), // 深紫色背景
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A0D2E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Permission',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 通知权限
                  _buildPermissionItem(
                    controller: controller,
                    title: 'Notification',
                    description: 'Once opened, the app will receive some push messages when placed in the background.',
                    isEnabled: controller.notificationEnabled,
                    onChanged: controller.toggleNotification,
                  ),
                  const SizedBox(height: 16),
                  // 应用内通知权限
                  _buildPermissionItem(
                    controller: controller,
                    title: 'In-app notification',
                    description: 'Once turned on, you will receive message notifications during use.',
                    isEnabled: controller.inAppNotificationEnabled,
                    onChanged: controller.toggleInAppNotification,
                  ),
                  const SizedBox(height: 16),
                  // 声音权限
                  _buildPermissionItem(
                    controller: controller,
                    title: 'Sounding',
                    description: 'After opening it, a ringtone will sound when you receive a new message or call invitation.',
                    isEnabled: controller.soundingEnabled,
                    onChanged: controller.toggleSounding,
                  ),
                ],
              ),
            ),
          ),
          // 底部横幅
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
            margin: EdgeInsets.only(bottom: 70),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFF1493), Color(0xFF9C27B0)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            child: const Text(
              'For your better work, please open all permissions below.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建权限设置项
  Widget _buildPermissionItem({
    required PermissionController controller,
    required String title,
    required String description,
    required RxBool isEnabled,
    required Function(bool) onChanged,
  }) {
    return Obx(() {
      final enabled = isEnabled.value;
      final descriptionColor = enabled 
          ? const Color(0xFF4CAF50) // 绿色（开启时）
          : const Color(0xFFE53935); // 红色（关闭时）

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF362A5A),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(
                      color: descriptionColor,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // 开关
            Switch(
              value: enabled,
              onChanged: onChanged,
              activeColor: const Color(0xFF4CAF50),
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: Colors.grey[700],
            ),
          ],
        ),
      );
    });
  }
}
