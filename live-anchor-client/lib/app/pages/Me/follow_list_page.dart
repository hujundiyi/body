import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:weeder/data/models/user_model_entity.dart';
import '../../controllers/follow_list_controller.dart';
import '../../widgets/avatar_network_image.dart';

/// Followers / Following 列表页（Me 页点击 Followers 或 Following 进入）
class FollowListPage extends GetView<FollowListController> {
  const FollowListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        titleSpacing: 0,
        title: TabBar(
          controller: controller.tabController,
          tabs: const [
            Tab(text: 'Followers'),
            Tab(text: 'Following'),
          ],
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.normal),
          indicatorColor: const Color(0xFFFF1493),
          indicatorSize: TabBarIndicatorSize.label,
          indicatorWeight: 3,
          dividerColor: Colors.transparent,
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: controller.tabController,
          children: [_buildUserListView(0), _buildUserListView(1)],
        ),
      ),
    );
  }

  Widget _buildUserListView(int tabIndex) {
    return Obx(() {
      final userList = controller.getListByTab(tabIndex);
      final isLoading = controller.getLoadingByTab(tabIndex);

      if (isLoading && userList.isEmpty) {
        return const Center(child: CircularProgressIndicator(color: Color(0xFFFF1493)));
      }

      if (userList.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.list_alt, size: 64, color: Colors.blue[300]),
              const SizedBox(height: 16),
              const Text('The current list is empty', style: TextStyle(color: Colors.white, fontSize: 16)),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: () => controller.refreshListByTab(tabIndex),
        color: const Color(0xFFFF1493),
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: userList.length,
          itemBuilder: (context, index) {
            final user = userList[index];
            return _buildUserListItem(user);
          },
        ),
      );
    });
  }

  Widget _buildUserListItem(UserModelEntity user) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => controller.openUserDetail(user),
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  _buildAvatar(user),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          user.nickname,
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (user.coinBalance > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF8C00),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Image.asset(
                                    'asset/images/common/coin.png',
                                    width: 14,
                                    height: 14,
                                    fit: BoxFit.contain,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${user.coinBalance}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () => controller.startChat(user),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF00C853)),
                  child: const Icon(Icons.chat_bubble, color: Colors.white, size: 22),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => controller.startVideoCall(user),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFFF1493)),
                  child: const Icon(Icons.videocam, color: Colors.white, size: 24),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(UserModelEntity user) {
    final avatarUrl = user.avatar.isNotEmpty ? user.avatar : null;
    return Stack(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFFFF1493), Color(0xFFFF69B4)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: Colors.transparent, width: 1),
          ),
          padding: const EdgeInsets.all(1),
          child: AvatarNetworkImage(
            imageUrl: avatarUrl,
            size: 54,
            placeholderAssetImage: 'asset/images/common/avatar_placeholder.svg',
            placeholderColor: const Color(0xFF4A4A5A),
            placeholderIconColor: Colors.white54,
          ),
        ),
        if (user.onlineStatus == 0) // 0 表示在线
          Positioned(
            right: 2,
            bottom: 2,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: const Color(0xFF00FF00),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}
