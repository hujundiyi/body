import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../core/base/base_controller.dart';
import '../../core/network/anchor_api_service.dart';
import '../../data/models/say_hi_model.dart';

/// Say Hi 控制器
class SayHiController extends BaseController {
  // Say Hi 消息列表
  final RxList<SayHiMessage> sayHiMessages = <SayHiMessage>[].obs;

  @override
  void onControllerInit() {
    super.onControllerInit();
    loadSayHiMessages();
  }

  /// 加载Say Hi消息列表
  Future<void> loadSayHiMessages({bool refresh = false}) async {
    if (refresh) {
      setLoading(true);
    } else {
      setLoading(true);
    }

    try {
      final messages = await AnchorAPIService.shared.getSayHiMessage();
      sayHiMessages.assignAll(messages);
    } catch (e) {
      debugPrint('Failed to load say hi messages: $e');
      showErrorUnlessAuth(e, 'Failed to load messages');
    } finally {
      setLoading(false);
    }
  }

  /// 刷新数据
  @override
  Future<void> refresh() async {
    await loadSayHiMessages(refresh: true);
  }

  /// 删除Say Hi消息
  Future<void> deleteMessage(int id) async {
    try {
      await AnchorAPIService.shared.delSayHiMessage(id);
      showSuccess('Message deleted successfully');
      await loadSayHiMessages(refresh: true);
    } catch (e) {
      debugPrint('Failed to delete message: $e');
      showErrorUnlessAuth(e, 'Failed to delete message');
    }
  }

  /// 设置 Say Hi 消息为默认
  Future<void> setDefaultMessage(int id) async {
    try {
      await AnchorAPIService.shared.setSayHiMessageDefault(id);
      showSuccess('Set as default successfully');
      await loadSayHiMessages(refresh: true);
    } catch (e) {
      debugPrint('Failed to set default: $e');
      showErrorUnlessAuth(e, 'Failed to set default');
    }
  }

  /// 判断是否为空
  bool get isEmpty => sayHiMessages.isEmpty;

  /// 判断是否已达到最大数量（3条）
  bool get isMaxReached => sayHiMessages.length >= 3;
}
