import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/main_tab_controller.dart';
import '../../core/services/im_service.dart';
import 'Discover/user_list_page.dart';
import 'Workbench/workbench_page.dart';
import 'Work/work_page.dart';
import './Message/message_page.dart';
import 'Me/me_page.dart';

/// 主 Tab 页面
class MainTabPage extends GetView<MainTabController> {
  const MainTabPage({super.key});

  IMService get _imService => Get.find<IMService>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView(
        controller: controller.pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: const [
          UserListPage(),
          WorkbenchPage(), // 改名为 Assets
          WorkPage(), // 新增 Work 页面（中间）
          MessagePage(),
          MePage(),
        ],
      ),
      bottomNavigationBar: Obx(() => _buildBottomNavBar()),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(index: 0, icon: Icons.people_outline, label: 'User'),
              _buildNavItem(index: 1, icon: Icons.grid_view_rounded, label: 'Assets'),
              _buildNavItem(index: 2, icon: Icons.work_outline, label: 'Work'),
              Obx(
                () => _buildNavItem(
                  index: 3,
                  icon: Icons.chat_bubble_outline,
                  label: 'Message',
                  badge: _formatBadge(_imService.totalUnreadCountRx.value),
                ),
              ),
              _buildNavItem(index: 4, icon: Icons.person_outline, label: 'Me'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({required int index, required IconData icon, required String label, String? badge}) {
    final isSelected = controller.currentIndex.value == index;

    return GestureDetector(
      onTap: () => controller.switchTab(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 26, color: isSelected ? const Color(0xFFFF1493) : Colors.grey),
                const SizedBox(height: 4),
                Text(label, style: TextStyle(fontSize: 11, color: isSelected ? const Color(0xFFFF1493) : Colors.grey)),
              ],
            ),
            if (badge != null)
              Positioned(
                right: 3,
                top: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Color(0xFFFF1493), borderRadius: BorderRadius.circular(10)),
                  child: Text(
                    badge,
                    style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String? _formatBadge(int unreadCount) {
    if (unreadCount <= 0) return null;
    if (unreadCount > 99) return '99+';
    return unreadCount.toString();
  }
}
