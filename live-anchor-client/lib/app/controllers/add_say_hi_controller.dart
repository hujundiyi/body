import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/base/base_controller.dart';
import '../../core/network/anchor_api_service.dart';
import '../../data/models/say_hi_model.dart';

/// 添加Say Hi控制器
class AddSayHiController extends BaseController {
  final formKey = GlobalKey<FormState>();
  final textController = TextEditingController();
  
  // 选中的图片文件
  final Rx<File?> selectedImage = Rx<File?>(null);
  
  // 上传后的图片URL
  final Rx<String?> uploadedImageUrl = Rx<String?>(null);
  
  // 是否正在上传图片
  final RxBool isUploadingImage = false.obs;
  
  // 文本输入状态（用于字符计数）
  final RxInt textLength = 0.obs;

  /// 是否为编辑模式（从 Say Hi 列表带数据进入）
  final RxBool isEditMode = false.obs;

  /// 编辑时的消息 id（Swagger：修改传 id）
  int? editingMessageId;

  @override
  void onControllerInit() {
    super.onControllerInit();
    textController.addListener(() {
      textLength.value = textController.text.length;
    });
    final args = Get.arguments;
    if (args is Map && args['message'] != null) {
      final message = args['message'] as SayHiMessage;
      isEditMode.value = true;
      editingMessageId = message.id;
      if (message.content != null && message.content!.isNotEmpty) {
        textController.text = message.content!;
      }
      if (message.image != null && message.image!.isNotEmpty) {
        uploadedImageUrl.value = message.image;
      }
    }
  }

  @override
  void onControllerClose() {
    textController.dispose();
    super.onControllerClose();
  }

  /// 显示图片选择选项（从底部弹出）
  void showImagePickerOptions() {
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
                takePhoto();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFFFF1493)),
              title: const Text('Choose from Gallery', style: TextStyle(color: Colors.white)),
              onTap: () {
                Get.back();
                pickPhoto();
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

  /// 从相册选择图片
  Future<void> pickPhoto() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        selectedImage.value = File(image.path);
        // 自动上传图片
        await uploadImage();
      }
    } catch (e) {
      debugPrint('Failed to pick image: $e');
      showError('Failed to pick image');
    }
  }

  /// 从相机拍照
  Future<void> takePhoto() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        selectedImage.value = File(image.path);
        // 自动上传图片
        await uploadImage();
      }
    } catch (e) {
      debugPrint('Failed to take photo: $e');
      showError('Failed to take photo');
    }
  }

  /// 上传图片
  Future<void> uploadImage() async {
    if (selectedImage.value == null) return;

    isUploadingImage.value = true;
    try {
      final file = selectedImage.value!;
      
      // 获取上传URL
      final uploadUrls = await AnchorAPIService.shared.getPutFileUrls(
        files: [file],
        type: 'picture',
      );
      
      if (uploadUrls.isEmpty) {
        showError('Failed to get upload URL');
        return;
      }

      final uploadUrl = uploadUrls[0];
      
      // 上传文件
      await AnchorAPIService.shared.uploadFileToUrl(
        file,
        uploadUrl.putUrl ?? '',
      );
      
      // 保存上传后的URL（使用getUrl）
      uploadedImageUrl.value = uploadUrl.getUrl ?? uploadUrl.putUrl;
      showSuccess('Image uploaded successfully');
    } catch (e) {
      debugPrint('Failed to upload image: $e');
      showError('Failed to upload image');
    } finally {
      isUploadingImage.value = false;
    }
  }

  /// 检查是否可以提交
  bool get canSubmit {
    return uploadedImageUrl.value != null && 
           uploadedImageUrl.value!.isNotEmpty &&
           textController.text.trim().isNotEmpty;
  }

  /// 提交Say Hi消息（新增或编辑）
  Future<void> submit() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    if (!canSubmit) {
      showError('Please upload image and enter text');
      return;
    }

    setLoading(true);
    try {
      final request = AddSayHiMessageRequest(
        id: isEditMode.value ? editingMessageId : null,
        image: uploadedImageUrl.value!,
        content: textController.text.trim(),
      );

      await AnchorAPIService.shared.addSayHiMessage(request);

      setLoading(false);
      
      // 立即返回，在 Say Hi 页面显示成功提示
      try {
        final context = Get.context;
        if (context != null && Navigator.canPop(context)) {
          Navigator.of(context).pop({'success': true, 'isEdit': isEditMode.value});
        } else {
          Get.back(result: {'success': true, 'isEdit': isEditMode.value});
        }
      } catch (e) {
        debugPrint('Error when trying to go back: $e');
        Get.back(result: {'success': true, 'isEdit': isEditMode.value});
      }
    } catch (e) {
      setLoading(false);
      debugPrint('Failed to submit message: $e');
      showErrorUnlessAuth(e, 'Failed to submit message');
    }
  }
}
