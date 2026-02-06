import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../controllers/anchor_apply_controller.dart';
import '../../../routes/app_routes.dart';

/// 主播申请页面
class AnchorApplyPage extends StatelessWidget {
  const AnchorApplyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AnchorApplyController());

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          controller.isEditMode ? 'Edit' : (controller.isResubmit ? 'Reapply' : 'Anchor Application'),
          style: const TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => _handleBack(controller),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: controller.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 审核原因提示（如果存在）
              if (controller.rejectReason != null && controller.rejectReason!.isNotEmpty)
                _buildRejectReasonCard(controller.rejectReason!),

              // 照片上传区
              _buildPhotoSection(controller),
              const SizedBox(height: 24),

              // 基本信息
              _buildBasicInfoSection(controller),
              const SizedBox(height: 24),

              // 标签选择
              _buildTagsSection(controller),
              const SizedBox(height: 32),

              // 提交按钮
              _buildSubmitButton(controller),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  /// 处理返回操作
  static void _handleBack(AnchorApplyController controller) {
    // 如果可以返回就返回，否则跳转到登录页
    if (Navigator.of(Get.context!).canPop()) {
      Get.back();
    } else {
      AppRoutes.goToAnchorLogin();
    }
  }

  /// 审核原因卡片
  Widget _buildRejectReasonCard(String reason) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.orange),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Review Notice',
                  style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(reason, style: TextStyle(color: Colors.orange[300], fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 照片上传区域
  Widget _buildPhotoSection(AnchorApplyController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Personal Photos',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Text(
              '(At least ${AnchorApplyController.minPhotos} photos)',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Please upload real and clear personal photos, the first one will be used as cover',
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
        const SizedBox(height: 16),

        Obx(() {
          final existingCount = controller.existingPhotoUrls.length;
          final newCount = controller.photos.length;
          final totalCount = existingCount + newCount;
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1,
            ),
            itemCount: totalCount + 1,
            itemBuilder: (context, index) {
              if (index == totalCount) {
                return _buildAddPhotoButton(controller);
              }
              if (index < existingCount) {
                return _buildExistingPhotoItem(controller, index);
              }
              return _buildPhotoItem(controller, index - existingCount);
            },
          );
        }),
      ],
    );
  }

  /// 添加照片按钮
  Widget _buildAddPhotoButton(AnchorApplyController controller) {
    if (controller.totalPhotoCount >= AnchorApplyController.maxPhotos) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () => _showPhotoOptions(controller),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[700]!, style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate, color: Colors.grey[500], size: 32),
            const SizedBox(height: 8),
            Text('Add Photo', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
          ],
        ),
      ),
    );
  }

  /// 已有照片项（从接口拉取的 URL，编辑时展示；点击图片可重新选择替换）
  Widget _buildExistingPhotoItem(AnchorApplyController controller, int index) {
    final url = controller.existingPhotoUrls[index];
    return Stack(
      children: [
        GestureDetector(
          onTap: () => _showPhotoOptionsForReplace(controller, isExisting: true, index: index),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              url,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: Colors.grey[800],
                child: const Icon(Icons.broken_image, color: Colors.grey, size: 48),
              ),
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: Colors.grey[800],
                  child: const Center(child: CircularProgressIndicator(color: Color(0xFFFF1493), strokeWidth: 2)),
                );
              },
            ),
          ),
        ),
        if (index == 0)
          Positioned(
            left: 4,
            top: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: const Color(0xFFFF1493), borderRadius: BorderRadius.circular(4)),
              child: const Text('Cover', style: TextStyle(color: Colors.white, fontSize: 10)),
            ),
          ),
        Positioned(
          right: 4,
          top: 4,
          child: GestureDetector(
            onTap: () => controller.removeExistingPhoto(index),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
              child: const Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ),
        ),
      ],
    );
  }

  /// 照片项（新选择的本地文件；点击图片可重新选择替换）
  Widget _buildPhotoItem(AnchorApplyController controller, int index) {
    return Stack(
      children: [
        GestureDetector(
          onTap: () => _showPhotoOptionsForReplace(controller, isExisting: false, index: index),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              controller.photos[index],
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        ),
        // 封面标签（仅当没有已有照片时第一张新照片为封面）
        if (controller.existingPhotoUrls.isEmpty && index == 0)
          Positioned(
            left: 4,
            top: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: const Color(0xFFFF1493), borderRadius: BorderRadius.circular(4)),
              child: const Text('Cover', style: TextStyle(color: Colors.white, fontSize: 10)),
            ),
          ),
        // 删除按钮
        Positioned(
          right: 4,
          top: 4,
          child: GestureDetector(
            onTap: () => controller.removePhoto(index),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
              child: const Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ),
        ),
      ],
    );
  }

  /// 显示照片选项（新增照片）
  void _showPhotoOptions(AnchorApplyController controller) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFFFF1493)),
              title: const Text('Take Photo', style: TextStyle(color: Colors.white)),
              onTap: () {
                Get.back();
                controller.takePhoto();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFFFF1493)),
              title: const Text('Choose from Gallery', style: TextStyle(color: Colors.white)),
              onTap: () {
                Get.back();
                controller.pickPhoto();
              },
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Get.back(),
              child: Text('Cancel', style: TextStyle(color: Colors.grey[400])),
            ),
          ],
        ),
      ),
    );
  }

  /// 显示照片选项（替换已传图片：拍照 / 相册）
  void _showPhotoOptionsForReplace(AnchorApplyController controller, {required bool isExisting, required int index}) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFFFF1493)),
              title: const Text('Take Photo', style: TextStyle(color: Colors.white)),
              onTap: () {
                Get.back();
                if (isExisting) {
                  controller.replaceExistingPhotoAt(index, ImageSource.camera);
                } else {
                  controller.replaceNewPhotoAt(index, ImageSource.camera);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFFFF1493)),
              title: const Text('Choose from Gallery', style: TextStyle(color: Colors.white)),
              onTap: () {
                Get.back();
                if (isExisting) {
                  controller.replaceExistingPhotoAt(index, ImageSource.gallery);
                } else {
                  controller.replaceNewPhotoAt(index, ImageSource.gallery);
                }
              },
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Get.back(),
              child: Text('Cancel', style: TextStyle(color: Colors.grey[400])),
            ),
          ],
        ),
      ),
    );
  }

  /// 基本信息区域
  Widget _buildBasicInfoSection(AnchorApplyController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Basic Information',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // 昵称
        _buildTextField(
          controller: controller.nicknameController,
          label: 'Nickname',
          hint: 'Please enter nickname',
          validator: controller.validateNickname,
        ),
        const SizedBox(height: 16),

        // 联系方式（带下拉选择）
        _buildContactField(controller),
        const SizedBox(height: 16),

        // 通话价格选择
        _buildCallPriceSelector(controller),
        const SizedBox(height: 16),

        // 性别选择
        _buildGenderSelector(controller),
        const SizedBox(height: 16),

        // 生日选择
        _buildBirthdaySelector(controller),
        const SizedBox(height: 16),

        // 国家选择
        _buildCountrySelector(controller),
        const SizedBox(height: 16),

        // 签名
        _buildTextField(
          controller: controller.signatureController,
          label: 'Signature',
          hint: 'Tell us about yourself (Optional)',
          maxLines: 3,
        ),
      ],
    );
  }

  /// 联系方式输入框（带下拉选择）
  Widget _buildContactField(AnchorApplyController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Contact', style: TextStyle(color: Colors.grey[400], fontSize: 14)),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 联系方式类型选择器
            Obx(
              () => GestureDetector(
                onTap: () => _showLinkTypePicker(controller),
                child: Container(
                  width: 120,
                  height: 56, // 固定高度，与 TextFormField 一致
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                    border: Border.all(color: Colors.grey[800]!),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Center(
                          child: Text(
                            controller.selectedLinkType.value != null
                                ? _getLinkTypeLabel(controller, controller.selectedLinkType.value!)
                                : 'Select Type',
                            style: TextStyle(
                              color: controller.selectedLinkType.value != null ? Colors.white : Colors.grey[600],
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      Icon(Icons.arrow_drop_down, color: Colors.grey[500], size: 20),
                    ],
                  ),
                ),
              ),
            ),
            // 联系方式输入框（与选择器无缝连接）
            Expanded(
              child: SizedBox(
                height: 56, // 固定高度，与选择器一致
                child: TextFormField(
                  controller: controller.whatsappController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Please enter contact information',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    filled: true,
                    fillColor: Colors.grey[900],
                    border: OutlineInputBorder(
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                      borderSide: BorderSide(color: Colors.grey[800]!, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                      borderSide: const BorderSide(color: Color(0xFFFF1493), width: 2),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                      borderSide: const BorderSide(color: Colors.red, width: 1),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  validator: controller.validateWhatsApp,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 获取联系方式类型标签
  String _getLinkTypeLabel(AnchorApplyController controller, int value) {
    final option = controller.linkTypeOptions.firstWhere(
      (item) => item['value'] == value,
      orElse: () => {'label': 'Unknown'},
    );
    return option['label'] as String;
  }

  /// 显示联系方式类型选择器
  void _showLinkTypePicker(AnchorApplyController controller) {
    Get.bottomSheet(
      Container(
        constraints: BoxConstraints(maxHeight: Get.height * 0.4),
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E1E),
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
                    'Select Contact Type',
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
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: controller.linkTypeOptions.length,
                itemBuilder: (context, index) {
                  final option = controller.linkTypeOptions[index];
                  final isSelected = controller.selectedLinkType.value == option['value'];
                  return ListTile(
                    title: Text(
                      option['label'] as String,
                      style: TextStyle(color: isSelected ? const Color(0xFFFF1493) : Colors.white),
                    ),
                    trailing: isSelected ? const Icon(Icons.check, color: Color(0xFFFF1493)) : null,
                    onTap: () {
                      controller.selectLinkType(option['value'] as int);
                      Get.back();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 文本输入框
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 14)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[600]),
            filled: true,
            fillColor: Colors.grey[900],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[800]!, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFFF1493), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  /// 通话价格选择器
  Widget _buildCallPriceSelector(AnchorApplyController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Call Price', style: TextStyle(color: Colors.grey[400], fontSize: 14)),
        const SizedBox(height: 8),
        Obx(
          () => GestureDetector(
            onTap: () => _showCallPricePicker(controller),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[800]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    controller.selectedCallPrice.value != null
                        ? _getCallPriceLabel(controller, controller.selectedCallPrice.value!)
                        : 'Please select call price',
                    style: TextStyle(
                      color: controller.selectedCallPrice.value != null ? Colors.white : Colors.grey[600],
                    ),
                  ),
                  Icon(Icons.arrow_drop_down, color: Colors.grey[500]),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 获取通话价格标签
  String _getCallPriceLabel(AnchorApplyController controller, double value) {
    final option = controller.callPriceOptions.firstWhere(
      (item) => (item['value'] as double) == value,
      orElse: () => {'label': 'Unknown'},
    );
    return option['label'] as String;
  }

  /// 显示通话价格选择器
  void _showCallPricePicker(AnchorApplyController controller) {
    Get.bottomSheet(
      Container(
        constraints: BoxConstraints(maxHeight: Get.height * 0.4),
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E1E),
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
                    'Select Call Price',
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
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: controller.callPriceOptions.length,
                itemBuilder: (context, index) {
                  final option = controller.callPriceOptions[index];
                  final isSelected = controller.selectedCallPrice.value == option['value'];
                  return ListTile(
                    title: Text(
                      option['label'] as String,
                      style: TextStyle(color: isSelected ? const Color(0xFFFF1493) : Colors.white),
                    ),
                    trailing: isSelected ? const Icon(Icons.check, color: Color(0xFFFF1493)) : null,
                    onTap: () {
                      controller.selectCallPrice(option['value'] as double);
                      Get.back();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 性别选择器
  Widget _buildGenderSelector(AnchorApplyController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Gender', style: TextStyle(color: Colors.grey[400], fontSize: 14)),
        const SizedBox(height: 8),
        Obx(
          () => Row(
            children: [
              // 男（0）- 第一个，默认选中
              Expanded(
                child: GestureDetector(
                  onTap: () => controller.selectGender(0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: controller.selectedGender.value == 0 ? Colors.blue.withOpacity(0.2) : Colors.grey[900],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: controller.selectedGender.value == 0 ? Colors.blue : Colors.grey[800]!),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.male, color: controller.selectedGender.value == 0 ? Colors.blue : Colors.grey[500]),
                        const SizedBox(width: 8),
                        Text(
                          'Male',
                          style: TextStyle(
                            color: controller.selectedGender.value == 0 ? Colors.blue : Colors.grey[500],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // 女（1）
              Expanded(
                child: GestureDetector(
                  onTap: () => controller.selectGender(1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: controller.selectedGender.value == 1
                          ? const Color(0xFFFF1493).withOpacity(0.2)
                          : Colors.grey[900],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: controller.selectedGender.value == 1 ? const Color(0xFFFF1493) : Colors.grey[800]!,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.female,
                          color: controller.selectedGender.value == 1 ? const Color(0xFFFF1493) : Colors.grey[500],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Female',
                          style: TextStyle(
                            color: controller.selectedGender.value == 1 ? const Color(0xFFFF1493) : Colors.grey[500],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Unknown（2）
              Expanded(
                child: GestureDetector(
                  onTap: () => controller.selectGender(2),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: controller.selectedGender.value == 2
                          ? Colors.grey[700]!.withOpacity(0.2)
                          : Colors.grey[900],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: controller.selectedGender.value == 2 ? Colors.grey[600]! : Colors.grey[800]!,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.help_outline,
                          color: controller.selectedGender.value == 2 ? Colors.grey[400] : Colors.grey[500],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Unknown',
                          style: TextStyle(
                            color: controller.selectedGender.value == 2 ? Colors.grey[400] : Colors.grey[500],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 生日选择器
  Widget _buildBirthdaySelector(AnchorApplyController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Birthday', style: TextStyle(color: Colors.grey[400], fontSize: 14)),
        const SizedBox(height: 8),
        Obx(
          () => GestureDetector(
            onTap: () => controller.selectBirthday(Get.context!),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[800]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    controller.birthday.value != null
                        ? '${controller.birthday.value!.year}-${controller.birthday.value!.month.toString().padLeft(2, '0')}-${controller.birthday.value!.day.toString().padLeft(2, '0')}'
                        : 'Please select birthday',
                    style: TextStyle(color: controller.birthday.value != null ? Colors.white : Colors.grey[600]),
                  ),
                  Row(
                    children: [
                      if (controller.age != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF1493),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${controller.age} years old',
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      const SizedBox(width: 8),
                      Icon(Icons.calendar_today, color: Colors.grey[500], size: 20),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 国家选择器
  Widget _buildCountrySelector(AnchorApplyController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Country/Region', style: TextStyle(color: Colors.grey[400], fontSize: 14)),
        const SizedBox(height: 8),
        Obx(
          () => GestureDetector(
            onTap: () => _showCountryPicker(controller),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[800]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    controller.selectedCountry.value != null
                        ? _getCountryName(controller, controller.selectedCountry.value!)
                        : 'Please select country/region',
                    style: TextStyle(color: controller.selectedCountry.value != null ? Colors.white : Colors.grey[600]),
                  ),
                  Icon(Icons.arrow_drop_down, color: Colors.grey[500]),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 获取国家名称
  String _getCountryName(AnchorApplyController controller, int code) {
    final country = controller.countries.firstWhere(
      (c) => c['code'] == code,
      orElse: () => {'name': 'Unknown', 'flag': '🌍'},
    );
    return '${country['flag']} ${country['name']}';
  }

  /// 显示国家选择器
  void _showCountryPicker(AnchorApplyController controller) {
    Get.bottomSheet(
      Container(
        height: Get.height * 0.6,
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select Country/Region',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: controller.countries.length,
                itemBuilder: (context, index) {
                  final country = controller.countries[index];
                  final isSelected = controller.selectedCountry.value == country['code'];
                  return ListTile(
                    leading: Text(country['flag'], style: const TextStyle(fontSize: 24)),
                    title: Text(
                      country['name'],
                      style: TextStyle(color: isSelected ? const Color(0xFFFF1493) : Colors.white),
                    ),
                    trailing: isSelected ? const Icon(Icons.check, color: Color(0xFFFF1493)) : null,
                    onTap: () {
                      controller.selectCountry(country['code']);
                      Get.back();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 标签选择区域
  Widget _buildTagsSection(AnchorApplyController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Personal Tags',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Text('(Max 5)', style: TextStyle(color: Colors.grey[500], fontSize: 14)),
          ],
        ),
        const SizedBox(height: 16),
        Obx(
          () => Wrap(
            spacing: 10,
            runSpacing: 10,
            children: controller.availableTags.map((tag) {
              final isSelected = controller.isTagSelected(tag);
              return GestureDetector(
                onTap: () => controller.toggleTag(tag),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFFF1493).withOpacity(0.2) : Colors.grey[900],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isSelected ? const Color(0xFFFF1493) : Colors.grey[700]!),
                  ),
                  child: Text(
                    tag.dictLabel ?? '',
                    style: TextStyle(
                      color: isSelected ? const Color(0xFFFF1493) : Colors.grey[400],
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  /// 提交按钮
  Widget _buildSubmitButton(AnchorApplyController controller) {
    return Center(
      child: Obx(
        () => Container(
          height: 56,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF1493), Color(0xFFFF69B4)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(color: const Color(0xFFFF1493).withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 8)),
            ],
          ),
          child: ElevatedButton(
            onPressed: controller.isLoading ? null : controller.submitApplication,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            ),
            child: controller.isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Sure',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
          ),
        ),
      ),
    );
  }
}
