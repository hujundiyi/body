import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../core/base/base_controller.dart';
import '../../core/services/storage_service.dart';
import '../../data/models/contact_model.dart';

/// 客服页面控制器
class ServiceController extends BaseController {
  // 联系方式列表
  final RxList<ContactModel> contacts = <ContactModel>[].obs;

  @override
  void onControllerInit() {
    super.onControllerInit();
    loadContacts();
  }

  /// 从本地配置加载联系方式
  void loadContacts() {
    try {
      final storage = Get.find<StorageService>();
      final configJson = storage.getString('app_config');
      
      if (configJson != null && configJson.isNotEmpty) {
        final Map<String, dynamic> configData = json.decode(configJson);
        final contactsJson = configData['ANCHOR_OPERATE_CONTACTS'];
        
        if (contactsJson != null) {
          List<ContactModel> contactList = [];
          
          // 如果是字符串，先解析为 JSON
          if (contactsJson is String) {
            final decoded = json.decode(contactsJson);
            if (decoded is List) {
              contactList = decoded
                  .map((item) => ContactModel.fromJson(item as Map<String, dynamic>))
                  .toList();
            }
          } else if (contactsJson is List) {
            contactList = contactsJson
                .map((item) => ContactModel.fromJson(item as Map<String, dynamic>))
                .toList();
          }
          
          contacts.assignAll(contactList);
          debugPrint('加载联系方式成功: ${contacts.length} 条');
        }
      }
    } catch (e) {
      debugPrint('加载联系方式失败: $e');
    }
  }

  /// 复制号码到剪贴板
  Future<void> copyNumber(String number) async {
    try {
      // 使用 Flutter 的 Clipboard
      // 需要导入 'package:flutter/services.dart'
      // 这里先提示，实际复制功能在页面中实现
      showSuccess('Copied: $number');
    } catch (e) {
      debugPrint('复制失败: $e');
      showError('Failed to copy');
    }
  }
}
