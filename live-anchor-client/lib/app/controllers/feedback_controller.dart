import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/base/base_controller.dart';
import '../../core/network/anchor_api_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/utils/toast_utils.dart';
import '../../data/models/contact_model.dart';
import '../../data/models/dict_model.dart';

/// 反馈页控制器
class FeedbackController extends BaseController {
  final descriptionController = TextEditingController();
  final contactController = TextEditingController();

  /// 问题类型选项（从字典 feedback_type 获取）
  final RxList<DictItem> feedbackTypeOptions = <DictItem>[].obs;

  /// 当前选中的问题类型
  final Rx<DictItem?> selectedFeedbackType = Rx<DictItem?>(null);

  /// 联系方式列表（从配置 ANCHOR_OPERATE_CONTACTS 加载，供下拉选择）
  final RxList<ContactModel> contactOptions = <ContactModel>[].obs;

  /// 当前选中的联系方式（用于输入框前显示对应 icon）
  final Rx<ContactModel?> selectedContact = Rx<ContactModel?>(null);

  @override
  void onControllerInit() {
    super.onControllerInit();
    _loadContactFromConfig();
    _loadFeedbackTypeDict();
  }

  @override
  void onControllerClose() {
    descriptionController.dispose();
    contactController.dispose();
    super.onControllerClose();
  }

  /// 从配置（ANCHOR_OPERATE_CONTACTS）加载联系方式列表，与补全信息页一致
  void _loadContactFromConfig() {
    try {
      final storage = Get.find<StorageService>();
      final configJson = storage.getString('app_config');
      if (configJson == null || configJson.isEmpty) return;
      final Map<String, dynamic> configData = json.decode(configJson);
      final contactsJson = configData['ANCHOR_OPERATE_CONTACTS'];
      if (contactsJson == null) return;
      List<ContactModel> list = [];
      if (contactsJson is String) {
        final decoded = json.decode(contactsJson);
        if (decoded is List) {
          list = decoded
              .map((e) => ContactModel.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      } else if (contactsJson is List) {
        list = contactsJson
            .map((e) => ContactModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      contactOptions.assignAll(list);
      if (list.isNotEmpty && selectedContact.value == null) {
        selectedContact.value = list.first;
      }
    } catch (e) {
      debugPrint('加载联系方式配置失败: $e');
    }
  }

  /// 选中联系方式（仅更新输入框前的 icon，不预填号码）
  void selectContact(ContactModel? contact) {
    selectedContact.value = contact;
  }

  /// 加载反馈类型字典（feedback_type）
  Future<void> _loadFeedbackTypeDict() async {
    try {
      final dictList = await AnchorAPIService.shared.getDict(['feedback_type']);
      for (final dict in dictList) {
        if (dict.dictType == 'feedback_type' && dict.dictItems.isNotEmpty) {
          feedbackTypeOptions.assignAll(dict.dictItems);
          if (selectedFeedbackType.value == null) {
            selectedFeedbackType.value = dict.dictItems.first;
          }
          break;
        }
      }
    } catch (e) {
      debugPrint('加载反馈类型字典失败: $e');
    }
  }

  void setSelectedFeedbackType(DictItem item) {
    selectedFeedbackType.value = item;
  }

  Future<void> submit() async {
    final reason = descriptionController.text.trim();
    final contactEmail = contactController.text.trim();
    if (reason.isEmpty) {
      showError('Please enter detailed description');
      return;
    }
    if (reason.length > 200) {
      showError('Description must be no more than 200 characters');
      return;
    }
    final selected = selectedFeedbackType.value;
    if (selected == null) {
      showError('Please select question type');
      return;
    }
    if (contactEmail.isEmpty) {
      showError('Please enter contact');
      return;
    }
    await executeWithLoading(() async {
      try {
        final stopwatch = Stopwatch()..start();
        await AnchorAPIService.shared.userFeedback(
          feedbackType: selected.value,
          reason: reason,
          contactEmail: contactEmail,
        );
        const minLoadingDuration = Duration(milliseconds: 1000);
        final elapsed = stopwatch.elapsed;
        if (elapsed < minLoadingDuration) {
          await Future.delayed(minLoadingDuration - elapsed);
        }
        Get.back();
        ToastUtils.showSuccess('Feedback submitted successfully');
      } catch (e) {
        showErrorUnlessAuth(e, 'Submission failed: ${e.toString()}');
      }
    });
  }
}
