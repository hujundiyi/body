import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_conversation.dart';
import '../../controllers/message_list_controller.dart';
import '../../../routes/app_routes.dart';

/// 消息列表视图（Message Tab）
class MessageListView extends StatelessWidget {
  final MessageListController controller;

  const MessageListView({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Group Message 入口
        // _buildGroupMessageEntry(),
        // 会话列表
        Expanded(
          child: _buildMessageList(),
        ),
      ],
    );
  }

  /// Group Message 入口
  Widget _buildGroupMessageEntry() {
    return GestureDetector(
      onTap: () {
        // TODO: 跳转到群发消息页面
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A4A),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // 图标
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.email_outlined,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            // 文字
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Group Message',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Set up auto messages and get more traffic',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    return Obx(() {
      // 加载中
      if (controller.isLoading.value && controller.conversationList.isEmpty) {
        return const Center(
          child: CircularProgressIndicator(color: Color(0xFFFF1493)),
        );
      }

      // IM 未登录
      if (!controller.isIMLoggedIn) {
        return RefreshIndicator(
          onRefresh: controller.refresh,
          color: const Color(0xFFFF1493),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(
                height: MediaQuery.of(Get.context!).size.height * 0.5,
                child: _buildEmptyState(
                  icon: Icons.cloud_off,
                  title: 'Not connected',
                  subtitle: 'Please log in to view messages',
                ),
              ),
            ],
          ),
        );
      }

      // 空列表（含过滤拉黑后的空）
      if (controller.conversationList.isEmpty) {
        return RefreshIndicator(
          onRefresh: controller.refresh,
          color: const Color(0xFFFF1493),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(
                height: MediaQuery.of(Get.context!).size.height * 0.5,
                child: _buildEmptyState(
                  icon: Icons.chat_bubble_outline,
                  title: 'No messages',
                  subtitle: 'Start chatting with users',
                ),
              ),
            ],
          ),
        );
      }

      // 会话列表（已过滤拉黑用户）
      return RefreshIndicator(
        onRefresh: controller.refresh,
        color: const Color(0xFFFF1493),
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: controller.conversationList.length,
          itemBuilder: (context, index) {
            final conversation = controller.conversationList[index];
            return _buildMessageItem(conversation);
          },
        ),
      );
    });
  }

  /// 空状态
  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[500]),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageItem(V2TimConversation conversation) {
    final name = controller.getConversationName(conversation);
    final avatar = controller.getConversationAvatar(conversation);
    final lastMessage = controller.getLastMessageSummary(conversation);
    final time = controller.formatTime(conversation.lastMessage?.timestamp);
    final unreadCount = conversation.unreadCount ?? 0;
    final isPinned = conversation.isPinned ?? false;

    return Dismissible(
      key: Key(conversation.conversationID ?? ''),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await _showDeleteConfirmDialog();
      },
      onDismissed: (direction) {
        controller.deleteConversation(conversation.conversationID ?? '');
      },
      child: GestureDetector(
        onTap: () => _onConversationTap(conversation),
        onLongPress: () => _showConversationOptions(conversation),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isPinned ? const Color(0xFF3A3A5A) : const Color(0xFF2A2A4A),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              // 头像区域（带在线状态和未读数）
              GestureDetector(
                onTap: () => _openUserDetail(conversation.userID),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // 头像（带加载/失败占位，避免网络异常未捕获）
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: avatar.isNotEmpty
                          ? Image.network(
                              avatar,
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _avatarPlaceholder(56, name),
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return _avatarPlaceholder(56, name);
                              },
                            )
                          : _avatarPlaceholder(56, name),
                    ),
                    // 未读消息数（右上角）
                    if (unreadCount > 0)
                      Positioned(
                        right: -4,
                        top: -4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          constraints:
                              const BoxConstraints(minWidth: 20, minHeight: 20),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF1493),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              unreadCount > 99 ? '99+' : '$unreadCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    // 在线状态（左下角）
                    Positioned(
                      left: 0,
                      bottom: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF2A2A4A), width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // 消息内容
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // 昵称
                        Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(width: 6),
                        // New 标签（如果有未读消息）
                        if (unreadCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF1493),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'New',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // 最后消息
                    Text(
                      lastMessage,
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // 右侧信息
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // 时间
                  Text(
                    time,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // 置顶标识
                  if (isPinned)
                    const Icon(
                      Icons.push_pin,
                      size: 16,
                      color: Color(0xFFFF1493),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 点击会话
  void _onConversationTap(V2TimConversation conversation) {
    // 标记已读
    controller.markAsRead(conversation);

    // 跳转到聊天详情页面
    Get.toNamed(
      AppRoutes.messageChat,
      arguments: {
        'conversationID': conversation.conversationID,
        'userID': conversation.userID,
        'groupID': conversation.groupID,
        'name': controller.getConversationName(conversation),
        'avatar': controller.getConversationAvatar(conversation),
      },
    );
  }

  /// 显示会话选项
  void _showConversationOptions(V2TimConversation conversation) {
    final isPinned = conversation.isPinned ?? false;

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF2A2A4A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                isPinned ? Icons.push_pin_outlined : Icons.push_pin,
                color: const Color(0xFFFF1493),
              ),
              title: Text(
                isPinned ? 'Unpin' : 'Pin',
                style: const TextStyle(color: Colors.black),
              ),
              onTap: () {
                Get.back();
                controller.pinConversation(
                  conversation.conversationID ?? '',
                  !isPinned,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.done_all, color: Color(0xFFFF1493)),
              title:
                  const Text('Mark as read', style: TextStyle(color: Colors.black)),
              onTap: () {
                Get.back();
                controller.markAsRead(conversation);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete conversation', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Get.back();
                final confirm = await _showDeleteConfirmDialog();
                if (confirm == true) {
                  controller
                      .deleteConversation(conversation.conversationID ?? '');
                }
              },
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Get.back(),
              child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatarPlaceholder(double size, String name) {
    return Container(
      width: size,
      height: size,
      color: Colors.grey[300],
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.43,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _openUserDetail(String? userId) {
    if (userId == null || userId.isEmpty) return;
    final int? id = int.tryParse(userId);
    if (id == null || id <= 0) return;
    Get.toNamed(AppRoutes.userDetail, arguments: {'userId': id});
  }

  /// 显示删除确认对话框
  Future<bool?> _showDeleteConfirmDialog() {
    return Get.dialog<bool>(
      AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Delete conversation', style: TextStyle(color: Colors.black)),
        content: const Text(
          'Delete this conversation? This cannot be undone.',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
