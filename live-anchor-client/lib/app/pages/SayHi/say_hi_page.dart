import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/say_hi_controller.dart';
import '../../../routes/app_routes.dart';
import '../../../data/models/say_hi_model.dart';

/// Say Hi 页面
class SayHiPage extends StatelessWidget {
  const SayHiPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SayHiController>();

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
          'Say Hi',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          // 有数据时显示Add按钮
          Obx(() {
            if (controller.isEmpty) {
              return const SizedBox.shrink();
            }
            final isMaxReached = controller.isMaxReached;
            return Padding(
              padding: const EdgeInsets.only(right: 16),
              child: GestureDetector(
                onTap: isMaxReached
                    ? null
                    : () {
                        Get.toNamed(AppRoutes.addSayHi)?.then((result) {
                          if (result is Map && result['success'] == true) {
                            final isEdit = result['isEdit'] == true;
                            controller.showSuccess(isEdit ? 'Updated successfully' : 'Message submitted successfully');
                          }
                          // 返回时刷新数据
                          controller.loadSayHiMessages(refresh: true);
                        });
                      },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: isMaxReached
                        ? null
                        : const LinearGradient(
                            colors: [Color(0xFFFF1493), Color(0xFF9C27B0)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                    color: isMaxReached ? Colors.grey[700] : null,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Add',
                    style: TextStyle(
                      color: isMaxReached ? Colors.grey[400] : Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading && controller.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF1493)),
            ),
          );
        }

        // 空状态
        if (controller.isEmpty) {
          return _buildEmptyState(controller);
        }

        // 有数据状态
        return _buildListState(controller);
      }),
    );
  }

  /// 构建空状态
  Widget _buildEmptyState(SayHiController controller) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 60),
            // 挥手表情
            const Text(
              '👋',
              style: TextStyle(fontSize: 80),
            ),
            const SizedBox(height: 24),
            // 说明文字
            const Text(
              'After opening the app, your messages will be pushed to users randomly. It might get you more calls. The message will be submitted to the administrator for review; it will be sent after approval. Up to 3 items can be set.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.left,
            ),
            const SizedBox(height: 40),
            // Add按钮
            Obx(() {
              final isMaxReached = controller.isMaxReached;
              return GestureDetector(
                onTap: isMaxReached
                    ? null
                    : () {
                        Get.toNamed(AppRoutes.addSayHi)?.then((result) {
                          if (result is Map && result['success'] == true) {
                            final isEdit = result['isEdit'] == true;
                            controller.showSuccess(isEdit ? 'Updated successfully' : 'Message submitted successfully');
                          }
                          // 返回时刷新数据
                          controller.loadSayHiMessages(refresh: true);
                        });
                      },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: isMaxReached
                        ? null
                        : const LinearGradient(
                            colors: [Color(0xFFFF1493), Color(0xFF9C27B0)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                    color: isMaxReached ? Colors.grey[700] : null,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Center(
                    child: Text(
                      'Add',
                      style: TextStyle(
                        color: isMaxReached ? Colors.grey[400] : Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  /// 构建列表状态
  Widget _buildListState(SayHiController controller) {
    return RefreshIndicator(
      onRefresh: controller.refresh,
      color: const Color(0xFFFF1493),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // 挥手表情和说明文字
              const Text(
                '👋',
                style: TextStyle(fontSize: 80),
              ),
              const SizedBox(height: 16),
              const Text(
                'After opening the app, your messages will be pushed to users randomly. It might get you more calls. The message will be submitted to the administrator for review; it will be sent after approval. Up to 3 items can be set.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.5,
                ),
                textAlign: TextAlign.left,
              ),
              const SizedBox(height: 24),
              // 消息列表
              ...controller.sayHiMessages.map((message) =>
                  _buildMessageItem(controller, message, isPreview: false))
                  .toList(),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建消息项
  /// [isPreview] 为 true 时仅展示状态样式，不显示删除按钮
  Widget _buildMessageItem(SayHiController controller, SayHiMessage message, {bool isPreview = false}) {
    final isApproved = message.auditStatus == 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF362A5A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 第一行：图片 + 文案
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: message.image != null && message.image!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          message.image!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.image,
                              color: Colors.grey,
                              size: 32,
                            );
                          },
                        ),
                      )
                    : const Icon(
                        Icons.image,
                        color: Colors.grey,
                        size: 32,
                      ),
              ),
              const SizedBox(width: 8),
              // 文案：最大高度与图片一致（80），超出显示省略号
              Expanded(
                child: SizedBox(
                  height: 80,
                  child: ClipRect(
                    child: Text(
                      message.content ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        height: 1.25,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      softWrap: true,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 第二行：图标按钮一排，总长度 = 选项总长度（整行）
          Row(
            children: [
              if (!isPreview && isApproved) ...[
                _buildDefaultButton(controller, message),
                const SizedBox(width: 8),
                _buildSmallButton(
                  icon: Icons.edit_outlined,
                  color: const Color(0xFF2196F3),
                  onTap: () {
                    if (message.id != null) {
                      Get.toNamed(AppRoutes.addSayHi, arguments: {'message': message})?.then((result) {
                        if (result is Map && result['success'] == true) {
                          final isEdit = result['isEdit'] == true;
                          controller.showSuccess(isEdit ? 'Updated successfully' : 'Message submitted successfully');
                        }
                        controller.loadSayHiMessages(refresh: true);
                      });
                    }
                  },
                ),
                const SizedBox(width: 8),
              ],
              if (!isPreview) ...[
                _buildSmallButton(
                  icon: Icons.delete_outline,
                  color: const Color(0xFFE53935),
                  onTap: () {
                    if (message.id != null) {
                      controller.deleteMessage(message.id!);
                    }
                  },
                ),
                const SizedBox(width: 8),
              ],
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF362A5A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: message.statusColor,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      message.statusIcon,
                      color: message.statusColor,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      message.statusText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 1),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }

  /// 构建默认按钮（文字按钮）
  Widget _buildDefaultButton(SayHiController controller, SayHiMessage message) {
    final isDefault = message.isDefault == true;
    
    return GestureDetector(
      onTap: () {
        if (message.id != null) {
          if (isDefault) {
            // 已经是默认，不需要操作
            return;
          }
          // 非选中状态，弹出确认对话框
          _showSetDefaultConfirmDialog(controller, message.id!);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isDefault 
              ? const Color(0xFFFFB300).withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDefault 
                ? const Color(0xFFFFB300)
                : Colors.grey[600]!,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isDefault ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isDefault 
                  ? const Color(0xFFFFB300)
                  : Colors.grey[400],
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              'Default',
              style: TextStyle(
                color: isDefault 
                    ? const Color(0xFFFFB300)
                    : Colors.grey[400],
                fontSize: 12,
                fontWeight: isDefault ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 显示设置默认确认对话框
  void _showSetDefaultConfirmDialog(SayHiController controller, int messageId) {
    Get.dialog<bool>(
      AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Set as Default',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Do you want to set this as default?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(
              'No',
              style: TextStyle(color: Colors.grey[400]),
            ),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text(
              'Yes',
              style: TextStyle(color: Color(0xFFFF1493)),
            ),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        controller.setDefaultMessage(messageId);
      }
    });
  }
}
