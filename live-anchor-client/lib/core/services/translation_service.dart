import 'dart:convert';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_message.dart';
import 'package:weeder/core/network/api_client.dart';
import 'package:weeder/core/utils/toast_utils.dart';

import 'auth_service.dart';

/// 翻译服务
/// 提供消息翻译功能，支持缓存和状态管理
class TranslationService extends GetxService {
  static TranslationService get shared => Get.find<TranslationService>();

  /// 正在翻译的消息ID集合
  final RxSet<String> translatingMsgIds = <String>{}.obs;


  /// 获取设备语言代码
  String getDeviceLanguage() {
    final locale = PlatformDispatcher.instance.locale;
    return locale.languageCode; // 如 'en', 'zh', 'ja' 等
  }

  /// 获取消息的翻译文本
  /// 优先从缓存获取，其次从 cloudCustomData 中解析
  String? getTranslatedText(V2TimMessage message) {
    final msgId = message.msgID ?? '';
    if (msgId.isEmpty) return null;

    // 从 cloudCustomData 中解析
    final cloudCustomData = message.cloudCustomData;
    if (cloudCustomData == null || cloudCustomData.isEmpty) {
      return null;
    }

    try {
      final customData = jsonDecode(cloudCustomData);
      final translatedText = customData['translatedText'] as String?;
      return translatedText;
    } catch (e) {
      debugPrint('[TranslationService] 解析 cloudCustomData 失败: $e');
      return null;
    }
  }

  /// 翻译消息
  /// [message] 要翻译的消息
  /// [toUserId] 接收方用户ID（可选，用于API调用）
  Future<String?> translateMessage(
    V2TimMessage message, {
    String? toUserId,
  }) async {
    final msgId = message.msgID ?? '';
    if (msgId.isEmpty) return null;
    AuthService  _authService = Get.find<AuthService>();

    // 正在翻译中
    if (translatingMsgIds.contains(msgId)) return null;

    final text = message.textElem?.text;
    if (text == null || text.isEmpty) return null;

    translatingMsgIds.add(msgId);
    final anchor = _authService.userInfo;

    try {
      // final fromUserId = message.sender ?? '';
      final fromUserId = (anchor?.userId ?? 0).toString();
      final target = getDeviceLanguage();
      final seq = message.seq ?? 0;
      final random = message.random ?? 0;
      final interval = message.timestamp ?? 0;
      final msgKey = '${seq}_${random}_$interval';

      debugPrint('[TranslationService] 翻译消息: msgKey=$msgKey, text=$text, target=$target');

      final response = await APIClient.shared.request<Null>(
        'message/translationMsg',
        params: {
          'fromUserId': fromUserId,
          'toUserId': toUserId ?? '',
          'content': text,
          'target': target,
          'msgKey': msgKey,
        },
      );

      // final translatedText = response['translatedText'] as String? ??
      //     response['content'] as String?;
      // if (translatedText != null && translatedText.isNotEmpty) {
      //   translatedTexts[msgId] = translatedText;
      //   debugPrint('[TranslationService] 翻译成功: $translatedText');
      //   return translatedText;
      // } else {
        debugPrint('[TranslationService] 翻译返回为空');
      //   ToastUtils.showError('Translation failed');
      //   return null;
      // }
    } catch (e) {
      debugPrint('[TranslationService] 翻译失败: $e');
      ToastUtils.showError('Translation failed');
      return null;
    } finally {
      translatingMsgIds.remove(msgId);
    }
  }

  /// 检查消息是否正在翻译
  bool isTranslating(String msgId) => translatingMsgIds.contains(msgId);

  /// 清除翻译缓存
  void clearCache() {
    translatingMsgIds.clear();
  }
}
