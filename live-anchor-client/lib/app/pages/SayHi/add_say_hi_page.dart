import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/add_say_hi_controller.dart';

/// 添加Say Hi页面
class AddSayHiPage extends StatelessWidget {
  const AddSayHiPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AddSayHiController>();

    return Scaffold(
      backgroundColor: const Color(0xFF1A0D2E), // 深紫色背景
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A0D2E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: Obx(() => Text(
          controller.isEditMode.value ? 'Update' : 'Add Say Hi',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        )),
        centerTitle: true,
      ),
      body: GestureDetector(
        onTap: () {
          // 点击页面其他区域时收起键盘
          FocusScope.of(context).unfocus();
        },
        behavior: HitTestBehavior.opaque,
        child: Form(
          key: controller.formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pic标签
              const Text(
                'Pic',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              // 图片上传区域
              Obx(() {
                final screenWidth = MediaQuery.of(context).size.width;
                final imageWidth = screenWidth / 3;
                final imageHeight = imageWidth * 4 / 3; // 宽高比 3:4
                
                return GestureDetector(
                  onTap: controller.isUploadingImage.value
                      ? null
                      : () {
                          // 先收起键盘
                          FocusScope.of(context).unfocus();
                          // 延迟一点再显示选择框，确保键盘完全收起
                          Future.delayed(const Duration(milliseconds: 100), () {
                            controller.showImagePickerOptions();
                          });
                        },
                  child: Container(
                    width: imageWidth,
                    height: imageHeight,
                    decoration: BoxDecoration(
                      color: const Color(0xFF362A5A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey[700]!,
                        width: 1,
                      ),
                    ),
                    child: controller.isUploadingImage.value
                        ? const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF1493)),
                            ),
                          )
                        : controller.uploadedImageUrl.value != null
                            ? Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      controller.uploadedImageUrl.value!,
                                      width: imageWidth,
                                      height: imageHeight,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return _buildPlaceholder();
                                      },
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: GestureDetector(
                                      onTap: () {
                                        controller.selectedImage.value = null;
                                        controller.uploadedImageUrl.value = null;
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : _buildPlaceholder(),
                  ),
                );
              }),
              const SizedBox(height: 8),
              // 提示文字
              const Text(
                'Adding pics makes it easier to get user responses!',
                style: TextStyle(
                  color: Color(0xFFFF1493),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 24),
              // Text message标签和字符计数
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Text message',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Obx(() => Text(
                    '${controller.textLength.value}/200',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                  )),
                ],
              ),
              const SizedBox(height: 12),
              // 文本输入框
              TextFormField(
                controller: controller.textController,
                maxLength: 200,
                maxLines: 5,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Please enter text',
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  filled: true,
                  fillColor: const Color(0xFF362A5A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[700]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[700]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFFF1493)),
                  ),
                  counterStyle: const TextStyle(color: Colors.transparent),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter text';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 40),
              // 提交按钮
              Obx(() => GestureDetector(
                onTap: controller.canSubmit && !controller.isLoading
                    ? controller.submit
                    : null,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: controller.canSubmit && !controller.isLoading
                        ? const LinearGradient(
                            colors: [Color(0xFFFF1493), Color(0xFF9C27B0)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          )
                        : null,
                    color: controller.canSubmit && !controller.isLoading
                        ? null
                        : Colors.grey[700],
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: controller.isLoading
                      ? const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                        )
                      : const Center(
                          child: Text(
                            'Submit',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                ),
              )),
            ],
          ),
        ),
        ),
      ),
    );
  }

  /// 构建占位符
  Widget _buildPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            color: Colors.grey[500],
            size: 48,
          ),
          const SizedBox(height: 8),
          Text(
            'Tap to add image',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
