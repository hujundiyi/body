import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../controllers/service_controller.dart';

/// 客服页面
class ServicePage extends StatelessWidget {
  const ServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ServiceController>();

    return Scaffold(
      backgroundColor: const Color(0xFF1A0D2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A0D2E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Customer service',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 40),
            // 耳机图标
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B6B), // 浅珊瑚粉色
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.headset_mic,
                color: Colors.white,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            // 介绍文字
            const Text(
              'You can contact our customer service through the following methods.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            // 联系方式列表
            Obx(() {
              if (controller.contacts.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'No contact methods available',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                );
              }
              return Column(
                children: controller.contacts.map((contact) => 
                  _buildContactCard(controller, contact)
                ).toList(),
              );
            }),
          ],
        ),
      ),
    );
  }

  /// 构建联系方式卡片
  Widget _buildContactCard(ServiceController controller, contact) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF362A5A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // 左侧图标
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              shape: BoxShape.circle,
            ),
            child: contact.icon != null && contact.icon!.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      contact.icon!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.person,
                          color: Colors.grey,
                          size: 24,
                        );
                      },
                    ),
                  )
                : const Icon(
                    Icons.person,
                    color: Colors.grey,
                    size: 24,
                  ),
          ),
          const SizedBox(width: 16),
          // 中间文字
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.title ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  contact.number ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // 右侧 COPY 按钮
          GestureDetector(
            onTap: () => _copyToClipboard(controller, contact.number ?? ''),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF1493), Color(0xFF9C27B0)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'COPY',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 复制到剪贴板
  Future<void> _copyToClipboard(ServiceController controller, String text) async {
    if (text.isEmpty) return;
    
    try {
      await Clipboard.setData(ClipboardData(text: text));
      controller.showSuccess('Copied: $text');
    } catch (e) {
      controller.showError('Failed to copy');
    }
  }
}
