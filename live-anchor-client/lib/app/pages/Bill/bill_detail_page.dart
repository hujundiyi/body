import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/bill_detail_controller.dart';
import '../../../data/models/commission_model.dart';

/// 账单详情页面
class BillDetailPage extends StatelessWidget {
  const BillDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(BillDetailController());

    // 格式化月份显示
    String monthDisplay = '';
    if (controller.monthTimestamp != null) {
      final date = DateTime.fromMillisecondsSinceEpoch(controller.monthTimestamp! * 1000);
      final year = date.year;
      final month = date.month.toString().padLeft(2, '0');
      monthDisplay = '$year-$month';
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E), // 深蓝色背景
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: Text(
          monthDisplay,
          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.isLoading && controller.commissionRecords.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF1493))),
          );
        }

        if (controller.commissionRecords.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[600]),
                const SizedBox(height: 16),
                Text('No records yet', style: TextStyle(color: Colors.grey[400], fontSize: 16)),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.refresh,
          color: const Color(0xFFFF1493),
          child: NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification scrollInfo) {
              if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
                // 滚动到底部时加载更多
                if (controller.hasMore && !controller.isLoadingMore) {
                  controller.loadCommissionList();
                }
              }
              return false;
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: controller.commissionRecords.length + (controller.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == controller.commissionRecords.length) {
                  // 加载更多指示器
                  if (controller.isLoadingMore) {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(
                        child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF1493))),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                }

                final record = controller.commissionRecords[index];
                return _buildCommissionItem(controller, record);
              },
            ),
          ),
        );
      }),
    );
  }

  /// 构建佣金记录项
  Widget _buildCommissionItem(BillDetailController controller, CommissionRecord record) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 左侧：头像
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF362A5A), // 深紫色背景
              shape: BoxShape.circle,
            ),
            child: record.image != null && record.image!.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      record.image!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildDefaultAvatar();
                      },
                    ),
                  )
                : _buildDefaultAvatar(),
          ),

          const SizedBox(width: 12),

          // 中间：标题和日期
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  record.title ?? '',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  controller.formatDateTime(record.createTime),
                  style: TextStyle(color: Colors.grey[400], fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // 右侧：金额和 data，靠右对齐
          Flexible(
            child: Align(
              alignment: Alignment.centerRight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    controller.formatAmount(record.money),
                    style: const TextStyle(color: Color(0xFF4CAF50), fontSize: 16, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    record.data ?? '',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建默认头像
  Widget _buildDefaultAvatar() {
    return Container(
      decoration: const BoxDecoration(color: Color(0xFF362A5A), shape: BoxShape.circle),
      child: const Icon(Icons.person, color: Colors.white, size: 24),
    );
  }
}
