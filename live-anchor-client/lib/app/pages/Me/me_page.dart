import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/utils/toast_utils.dart';
import '../../widgets/avatar_network_image.dart';
import 'setting_page.dart';
import 'assets_page.dart';
import 'faq_page.dart';
import 'feedback_page.dart';
import '../../controllers/follow_list_controller.dart';
import 'block_list_page.dart';
import 'follow_list_page.dart';
import '../Login/anchor_apply_page.dart';

/// 个人中心页面
class MePage extends StatelessWidget {
  const MePage({super.key});

  AuthService get _authService => Get.find<AuthService>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        child: Obx(
          () =>
              Column(children: [_buildProfileHeader(), _buildStatsRow(), const SizedBox(height: 20), _buildMenuList()]),
        ),
      ),
    );
  }

  /// 构建头部个人信息
  Widget _buildProfileHeader() {
    final anchor = _authService.userInfo;
    final avatar = anchor?.avatar ?? '';
    final nickname = anchor?.nickname ?? 'Nickname not set';
    final userId = anchor?.userId?.toString() ?? '--';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFF1493), Color(0xFF9C27B0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          // 头像（点击进入资料补全，加载中/失败时显示占位图）
          GestureDetector(
            onTap: () => Get.to(() => const AnchorApplyPage(), arguments: {'fromAvatar': true}),
            child: AvatarNetworkImage(
              imageUrl: avatar.isNotEmpty ? avatar : null,
              size: 70,
              border: Border.all(color: Colors.white, width: 3),
              placeholderAssetImage: 'asset/images/common/avatar_placeholder.svg',
              placeholderColor: const Color(0xFF4A4A5A),
              placeholderIconColor: Colors.white54,
            ),
          ),
          const SizedBox(width: 16),
          // 用户信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nickname,
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text('ID:$userId', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: userId));
                        ToastUtils.showSuccess('ID copied');
                      },
                      child: const Icon(Icons.copy, color: Colors.white70, size: 16),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // 编辑按钮
          GestureDetector(
            onTap: () {
              Get.to(() => const AssetsPage());
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.edit, color: Color(0xFF00FF00), size: 20),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建统计行
  Widget _buildStatsRow() {
    final anchor = _authService.userInfo;
    final followers = anchor?.follower?.toString() ?? '0';
    final following = anchor?.following?.toString() ?? '0';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          GestureDetector(
            onTap: () => Get.to(
              () => const FollowListPage(),
              arguments: {'initialTab': 0},
              binding: BindingsBuilder(() {
                Get.lazyPut<FollowListController>(() => FollowListController());
              }),
            ),
            child: _StatItem(count: followers, label: 'Followers'),
          ),
          GestureDetector(
            onTap: () => Get.to(
              () => const FollowListPage(),
              arguments: {'initialTab': 1},
              binding: BindingsBuilder(() {
                Get.lazyPut<FollowListController>(() => FollowListController());
              }),
            ),
            child: _StatItem(count: following, label: 'Following'),
          ),
        ],
      ),
    );
  }

  /// 构建菜单列表
  Widget _buildMenuList() {
    return Column(
      children: [
        _buildMenuSection([
          _MenuItem(
            icon: Icons.help_outline,
            iconColor: const Color(0xFFFF9800),
            title: 'FAQ',
            onTap: () => Get.to(() => const FaqPage()),
          ),
          _MenuItem(
            icon: Icons.block,
            iconColor: const Color(0xFFFF4444),
            title: 'Blocklist',
            onTap: () => Get.to(() => const BlockListPage()),
          ),
          _MenuItem(
            icon: Icons.feedback,
            iconColor: const Color(0xFF00C853),
            title: 'Feedback',
            onTap: () => Get.to(() => const FeedbackPage()),
          ),
        ]),
        const SizedBox(height: 16),
        _buildMenuSection([
          _MenuItem(
            icon: Icons.settings,
            iconColor: const Color(0xFF2196F3),
            title: 'Setting',
            onTap: () {
              Get.to(() => const SettingPage());
            },
          ),
        ]),
      ],
    );
  }

  Widget _buildMenuSection(List<_MenuItem> items) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: const Color(0xFF2A2A4A), borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Column(
            children: [
              _buildMenuItemWidget(item),
              if (index < items.length - 1) const Divider(color: Colors.white12, height: 1, indent: 56),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMenuItemWidget(_MenuItem item) {
    return GestureDetector(
      onTap: item.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(color: item.iconColor, shape: BoxShape.circle),
              child: Icon(item.icon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.title,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 24),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String count;
  final String label;

  const _StatItem({required this.count, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
      ],
    );
  }
}

class _MenuItem {
  final IconData icon;
  final Color iconColor;
  final String title;
  final VoidCallback onTap;

  const _MenuItem({required this.icon, required this.iconColor, required this.title, required this.onTap});
}
