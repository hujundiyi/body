import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/call_history_controller.dart';
import '../../../data/models/call_history_model.dart';
import '../../../routes/app_routes.dart';

/// 通话历史视图（Call History Tab）
class CallHistoryView extends StatelessWidget {
  final CallHistoryController controller;

  const CallHistoryView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // 加载中
      if (controller.isLoading.value && controller.callHistoryList.isEmpty) {
        return const Center(child: CircularProgressIndicator(color: Color(0xFFFF1493)));
      }

      // 空列表
      if (controller.callHistoryList.isEmpty) {
        return RefreshIndicator(
          onRefresh: controller.refresh,
          color: const Color(0xFFFF1493),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.5,
                child: _buildEmptyState(
                  icon: Icons.phone_missed,
                  title: 'No call history',
                  subtitle: 'Call history will appear here',
                ),
              ),
            ],
          ),
        );
      }

      // 通话历史列表
      return RefreshIndicator(
        onRefresh: controller.refresh,
        color: const Color(0xFFFF1493),
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification is ScrollEndNotification) {
              // 当滚动到底部时加载更多
              if (notification.metrics.pixels >= notification.metrics.maxScrollExtent - 100) {
                controller.loadMore();
              }
            }
            return false;
          },
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            // 额外一个 item 用于显示加载状态
            itemCount: controller.callHistoryList.length + 1,
            itemBuilder: (context, index) {
              // 最后一个 item 显示加载状态或没有更多
              if (index == controller.callHistoryList.length) {
                return _buildLoadMoreIndicator();
              }
              final call = controller.callHistoryList[index];
              return _buildCallHistoryItem(call);
            },
          ),
        ),
      );
    });
  }

  /// 加载更多指示器
  Widget _buildLoadMoreIndicator() {
    return Obx(() {
      // 正在加载
      if (controller.isLoading.value) {
        return Container(
          padding: const EdgeInsets.all(16),
          alignment: Alignment.center,
          child: const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(color: Color(0xFFFF1493), strokeWidth: 2),
          ),
        );
      }

      // 没有更多数据
      if (!controller.hasMore) {
        return Container(
          padding: const EdgeInsets.all(16),
          alignment: Alignment.center,
          child: Text('No more', style: TextStyle(color: Colors.grey[500], fontSize: 14)),
        );
      }

      // 默认空白
      return const SizedBox(height: 16);
    });
  }

  /// 空状态
  Widget _buildEmptyState({required IconData icon, required String title, required String subtitle}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[500]),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(color: Colors.grey[300], fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(subtitle, style: TextStyle(color: Colors.grey[400], fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildCallHistoryItem(CallHistory call) {
    final userId = call.userId;
    final canOpenDetail = userId != null && userId > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFF2A2A4A), borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          // 除拨打按钮外的整条区域：点击进入用户详情
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: canOpenDetail ? () => Get.toNamed(AppRoutes.userDetail, arguments: {'userId': userId}) : null,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      _buildAvatar(call),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              call.nickname ?? 'Unknown',
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Text(
                                  controller.formatCallTime(call.createDateTime),
                                  style: TextStyle(color: Colors.grey[500], fontSize: 11),
                                ),
                                const SizedBox(width: 8),
                                Container(width: 1, height: 12, color: Colors.grey[600]),
                                const SizedBox(width: 8),
                                Text(
                                  call.callResultText,
                                  style: TextStyle(
                                    color: call.isAnswered
                                        ? Colors.green
                                        : (call.isMissed
                                              ? Colors.red
                                              : (call.isDeclined ? Colors.orange : Colors.grey[400])),
                                    fontSize: 12,
                                    fontWeight: call.isAnswered ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // 拨打按钮
          GestureDetector(
            onTap: () => controller.makeCall(call),
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFFF1493)),
              child: const Icon(Icons.videocam, color: Colors.white, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建头像（带加载/失败占位，避免网络异常未捕获）
  Widget _buildAvatar(CallHistory call) {
    final avatar = call.avatar ?? '';
    final name = call.nickname ?? '';
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: avatar.isNotEmpty
          ? Image.network(
              avatar,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _avatarPlaceholder(name),
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return _avatarPlaceholder(name);
              },
            )
          : _avatarPlaceholder(name),
    );
  }

  Widget _avatarPlaceholder(String name) {
    return Container(
      width: 50,
      height: 50,
      color: Colors.grey[700],
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }
}
