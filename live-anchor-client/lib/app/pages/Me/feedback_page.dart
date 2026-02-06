import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/feedback_controller.dart';
import '../../../data/models/contact_model.dart';
import '../../../data/models/dict_model.dart';

/// 反馈页（从 Me 页点击 Feedback 进入）
class FeedbackPage extends StatelessWidget {
  const FeedbackPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(FeedbackController());
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Feedback',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Question type',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Obx(() {
              final options = controller.feedbackTypeOptions;
              if (options.isEmpty) {
                return const SizedBox(
                  height: 52,
                  child: Center(
                    child: Text('Loading...', style: TextStyle(color: Colors.grey)),
                  ),
                );
              }
              return Row(
                children: [
                  for (int i = 0; i < options.length; i++) ...[
                    if (i > 0) const SizedBox(width: 12),
                    Expanded(
                      child: _buildTypeButton(controller, options[i]),
                    ),
                  ],
                ],
              );
            }),
            const SizedBox(height: 24),
            const Text(
              'Detailed description',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller.descriptionController,
              maxLines: 5,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Tell us how we can do better?',
                hintStyle: TextStyle(color: Colors.grey[500]),
                filled: true,
                fillColor: const Color(0xFF2A2A4A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade800, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFFF1493), width: 2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Contact',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A4A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade800),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Obx(() => _buildContactPrefixIcon(controller)),
                  Expanded(
                    child: TextField(
                      controller: controller.contactController,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.text,
                      decoration: InputDecoration(
                        hintText: 'Enter contact',
                        hintStyle: TextStyle(color: Colors.grey[500]),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[400], size: 24),
                    onPressed: () => _showContactPicker(controller),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tips: Please leave your contact information for us to contact you as soon as possible.',
              style: TextStyle(color: Colors.red, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: controller.submit,
              child: Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF1493), Color(0xFF9C27B0)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(26),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'Submit',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 输入框左侧的联系方式图标（左对齐，不占中间）
  Widget _buildContactPrefixIcon(FeedbackController controller) {
    final contact = controller.selectedContact.value;
    Widget iconWidget;
    if (contact?.icon != null && contact!.icon!.isNotEmpty) {
      iconWidget = ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.network(
          contact.icon!,
          width: 28,
          height: 28,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Icon(Icons.chat_bubble_outline, color: Colors.amber.shade300, size: 22),
        ),
      );
    } else {
      iconWidget = Icon(Icons.chat_bubble_outline, color: Colors.amber.shade300, size: 22);
    }
    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(width: 28, height: 28, child: iconWidget),
      ),
    );
  }

  /// 底部弹窗：仅显示联系方式的 icon + title，选中后更新输入框前缀图标并可选预填号码
  void _showContactPicker(FeedbackController controller) {
    Get.bottomSheet(
      Container(
        constraints: BoxConstraints(maxHeight: Get.height * 0.4),
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E2E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select Contact',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
            ),
            Flexible(
              child: Obx(() {
                if (controller.contactOptions.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No contact options',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: controller.contactOptions.length,
                  itemBuilder: (context, index) {
                    final option = controller.contactOptions[index];
                    final title = option.title ?? 'Contact ${index + 1}';
                    return ListTile(
                      leading: _buildListContactIcon(option),
                      title: Text(
                        title,
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      onTap: () {
                        controller.selectContact(option);
                        Get.back();
                      },
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  /// 底部弹窗列表项左侧 icon
  Widget _buildListContactIcon(ContactModel contact) {
    if (contact.icon != null && contact.icon!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          contact.icon!,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Icon(Icons.person, color: Colors.grey[400], size: 24),
        ),
      );
    }
    return Icon(Icons.person, color: Colors.grey[400], size: 24);
  }

  Widget _buildTypeButton(FeedbackController controller, DictItem item) {
    final isSelected = controller.selectedFeedbackType.value?.value == item.value;
    return GestureDetector(
      onTap: () => controller.setSelectedFeedbackType(item),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4A148C) : const Color(0xFF2A2A4A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFFFF1493) : Colors.grey.shade700,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            item.label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
