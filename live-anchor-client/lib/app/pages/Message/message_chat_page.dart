import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_message.dart';
import 'package:tencent_cloud_chat_sdk/enum/message_elem_type.dart';
import 'package:weeder/core/services/translation_service.dart';
import 'package:weeder/core/network/anchor_api_service.dart';
import 'package:weeder/core/services/blocked_user_service.dart';
import 'package:weeder/core/utils/toast_utils.dart';
import 'package:weeder/data/models/dict_model.dart';
import '../../controllers/message_chat_controller.dart';
import '../../../data/models/call_data_model.dart';
import '../../../routes/app_routes.dart';

/// 聊天详情页面
class MessageChatPage extends StatelessWidget {
  MessageChatPage({super.key});
  final _translationService = Get.find<TranslationService>();
  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MessageChatController());

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: _buildAppBar(context, controller),
      body: Column(
        children: [
          // 顶部固定提示文案
          _buildTopTipBanner(),
          // 消息列表
          Expanded(
            child: _buildMessageList(controller),
          ),
          // 输入框
          _buildInputBar(controller),
        ],
      ),
    );
  }

  /// 构建导航栏
  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    MessageChatController controller,
  ) {
    return AppBar(
      backgroundColor: const Color(0xFF1A1A1A),
      elevation: 0,
      leading: IconButton(
        onPressed: () => Get.back(),
        icon: const Icon(Icons.chevron_left, color: Colors.white, size: 32),
      ),
      title: GestureDetector(
        onTap: () => _openUserDetail(controller.userID),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              controller.userName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6),
            // const Text('👑', style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
      centerTitle: false,
      actions: [
        // 视频通话按钮
        Container(
          margin: const EdgeInsets.only(right: 16),
          decoration: const BoxDecoration(
            color: Color(0xFFFF1493),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            onPressed: controller.startVideoCall,
            icon: const Icon(
              Icons.videocam,
              color: Colors.white,
              size: 24,
            ),
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
          ),
        ),
        IconButton(
          onPressed: () => _showMoreMenu(context, controller),
          icon: const Icon(Icons.more_horiz, color: Colors.white),
        ),
      ],
    );
  }

  /// 顶部固定提示文案
  Widget _buildTopTipBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: const Color(0xFF252545),
      child: Text(
        'Respond enthusiastically to the user and you will have a chance to receive more calls.',
        style: const TextStyle(
          color: Color(0xFFB8B8D0),
          fontSize: 13,
          height: 1.35,
        ),
      ),
    );
  }

  /// 右上角更多菜单
  void _showMoreMenu(BuildContext context, MessageChatController controller) {
    if (controller.userID == null || controller.userID!.isEmpty) {
      ToastUtils.showInfo('Unavailable');
      return;
    }
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Color(0xFF2A2A4A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMoreMenuItem(
                label: 'Report',
                color: const Color(0xFFFF1493),
                onTap: () {
                  Get.back();
                  _showReportDialog(controller.userID);
                },
              ),
              _buildMoreMenuItem(
                label: 'Block',
                color: const Color(0xFFFF1493),
                onTap: () {
                  Get.back();
                  _blockUser(controller.userID);
                },
              ),
              _buildMoreMenuItem(
                label: 'Cancel',
                color: Colors.grey,
                onTap: () => Get.back(),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
    );
  }

  Widget _buildMoreMenuItem({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              decoration: TextDecoration.none,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _blockUser(String? userId) async {
    final id = int.tryParse(userId ?? '') ?? 0;
    if (id <= 0) return;
    try {
      final code = await AnchorAPIService.shared.blackStatus(
        blackUserId: id,
        black: true,
      );
      final explicitFail = code != null && code != 1 && code != 3;
      if (explicitFail) {
        ToastUtils.showError('Operation failed');
        return;
      }
      try {
        BlockedUserService.shared.addBlocked(id);
      } catch (_) {}
      ToastUtils.showSuccess('Blocked');
    } catch (_) {
      ToastUtils.showError('Operation failed');
    }
  }

  Future<void> _showReportDialog(String? userId) async {
    final id = int.tryParse(userId ?? '') ?? 0;
    if (id <= 0) return;
    final options = await _loadReportTypes();
    if (options.isEmpty) {
      ToastUtils.showError('No report types available');
      return;
    }
    Get.dialog(
      Align(
        alignment: Alignment.center,
        child: Material(
          color: Colors.transparent,
          child: _ChatReportDialogContent(
            options: options,
            onSubmit: (reportType) async {
              try {
                await AnchorAPIService.shared.reportUser(
                  reportType: reportType,
                  reportedType: 'USER_INFO',
                  reportedId: id,
                );
                Get.back();
                ToastUtils.showSuccess('Report submitted');
              } catch (_) {
                ToastUtils.showError('Submit failed');
              }
            },
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  Future<List<DictItem>> _loadReportTypes() async {
    try {
      final list = await AnchorAPIService.shared.getDict(['report_type']);
      for (final res in list) {
        if (res.dictType == 'report_type' && res.dictItems.isNotEmpty) {
          return res.dictItems;
        }
      }
    } catch (_) {}
    return [];
  }

  /// 构建消息列表
  Widget _buildMessageList(MessageChatController controller) {
    return Obx(() {
      if (controller.isLoading.value && controller.messageList.isEmpty) {
        return const Center(
          child: CircularProgressIndicator(color: Color(0xFFFF1493)),
        );
      }

      if (controller.messageList.isEmpty) {
        return _buildEmptyState();
      }

      return Align(
        alignment: Alignment.topCenter,
        child: ListView.builder(
          controller: controller.scrollController,
          reverse: true,
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: controller.messageList.length,
          itemBuilder: (context, index) {
            final message = controller.messageList[index];
            final showTimeDivider = controller.shouldShowTimeDivider(index);

            return Column(
              children: [
                // 时间分割线
                if (showTimeDivider) _buildTimeDivider(controller, message),
                // 消息项
                _buildMessageItem(controller, message),
              ],
            );
          },
        ),
      );
    });
  }

  /// 空状态
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[600]),
          const SizedBox(height: 16),
          Text(
            'No Messages',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 16,
            ),
          ),
          // const SizedBox(height: 8),
          // Text(
          //   '发送消息开始聊天吧',
          //   style: TextStyle(
          //     color: Colors.grey[600],
          //     fontSize: 14,
          //   ),
          // ),
        ],
      ),
    );
  }

  /// 构建时间分割线
  Widget _buildTimeDivider(
      MessageChatController controller, V2TimMessage message) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        controller.formatMessageTime(message.timestamp),
        style: TextStyle(
          color: Colors.grey[500],
          fontSize: 12,
        ),
      ),
    );
  }

  /// 构建消息项
  Widget _buildMessageItem(
      MessageChatController controller, V2TimMessage message) {
    final isSelf = controller.isSelfMessage(message);
    final elemType = message.elemType;

    // 判断是否是通话消息
    if (elemType == MessageElemType.V2TIM_ELEM_TYPE_CUSTOM) {
      return _buildCallMessageItem(controller, message, isSelf);
    }

    // 只有文本消息才显示翻译功能
    final isTextMessage = elemType == MessageElemType.V2TIM_ELEM_TYPE_TEXT;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isSelf ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 对方头像
          if (!isSelf) ...[
            GestureDetector(
              onTap: () => _openUserDetail(controller.userID),
              child: _buildAvatar(controller.userAvatar, controller.userName),
            ),
            const SizedBox(width: 8),
          ],
          // 消息内容（包含气泡和翻译结果）
          Flexible(
            child: Column(
              crossAxisAlignment: isSelf ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                _buildMessageBubble(controller, message, isSelf),
                // 翻译结果（对方的文本消息）
                if (!isSelf && isTextMessage)
                  _buildTranslationResult(message),
              ],
            ),
          ),
          // 翻译按钮（对方的文本消息）
          if (!isSelf && isTextMessage) ...[
            const SizedBox(width: 8),
            _buildTranslateButton(controller, message),
          ],
        ],
      ),
    );
  }

  /// 构建翻译结果
  Widget _buildTranslationResult(V2TimMessage message) {
    final translatedText = _translationService.getTranslatedText(message);
    // {\"clientLocalId\":null,\"translatedText\":\"唯一的方法\"}
    // return Obx(() {
      if (translatedText == null || translatedText.isEmpty) {
        return const SizedBox.shrink();
      }

      return Container(
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          translatedText,
          style: TextStyle(
            color: Colors.blue[200],
            fontSize: 14,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    // });
  }

  /// 构建头像
  Widget _buildAvatar(String avatarUrl, String name) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[700],
        image: avatarUrl.isNotEmpty
            ? DecorationImage(
                image: NetworkImage(avatarUrl),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: avatarUrl.isEmpty
          ? Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
    );
  }

  void _openUserDetail(String? userId) {
    if (userId == null || userId.isEmpty) return;
    final int? id = int.tryParse(userId);
    if (id == null || id <= 0) return;
    Get.toNamed(AppRoutes.userDetail, arguments: {'userId': id});
  }

  /// 构建消息气泡
  Widget _buildMessageBubble(
      MessageChatController controller, V2TimMessage message, bool isSelf) {
    final elemType = message.elemType;

    // 图片消息
    if (elemType == MessageElemType.V2TIM_ELEM_TYPE_IMAGE) {
      return _buildImageMessage(message, isSelf);
    }

    // 文本消息
    return Container(
      constraints: BoxConstraints(
        maxWidth: Get.width * 0.65,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isSelf ? const Color(0xFFFFE4E1) : const Color(0xFF3A3A3A),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isSelf ? 16 : 4),
          bottomRight: Radius.circular(isSelf ? 4 : 16),
        ),
      ),
      child: Text(
        controller.getMessageContent(message),
        style: TextStyle(
          color: isSelf ? Colors.black87 : Colors.white,
          fontSize: 15,
          height: 1.4,
        ),
      ),
    );
  }

  /// 构建图片消息
  Widget _buildImageMessage(V2TimMessage message, bool isSelf) {
    final imageElem = message.imageElem;
    final imageUrl = imageElem?.imageList?.first?.url ?? '';

    return Container(
      constraints: BoxConstraints(
        maxWidth: Get.width * 0.5,
        maxHeight: 200,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: imageUrl.isNotEmpty
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    width: 150,
                    height: 150,
                    color: Colors.grey[800],
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFFF1493),
                        strokeWidth: 2,
                      ),
                    ),
                  );
                },
              )
            : Container(
                width: 150,
                height: 150,
                color: Colors.grey[800],
                child: const Icon(Icons.image, color: Colors.grey, size: 48),
              ),
      ),
    );
  }

  /// 构建翻译按钮
  Widget _buildTranslateButton(MessageChatController controller, V2TimMessage message) {
    final msgId = message.msgID ?? '';

    return Obx(() {
      final isTranslating = _translationService.isTranslating(msgId);
      final translatedText = _translationService.getTranslatedText(message);
      // 已翻译则不显示按钮
      if (translatedText != null) return const SizedBox.shrink();

      return GestureDetector(
        onTap: isTranslating
            ? null
            : () => _translationService.translateMessage(
                  message,
                  toUserId: controller.userID ?? '',
                ),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.grey[800],
            shape: BoxShape.circle,
          ),
          child: isTranslating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: Colors.grey,
                    strokeWidth: 2,
                  ),
                )
              : const Icon(
                  Icons.translate,
                  color: Colors.grey,
                  size: 16,
                ),
        ),
      );
    });
  }

  /// 构建通话消息项
  Widget _buildCallMessageItem(
      MessageChatController controller, V2TimMessage message, bool isSelf) {
    // 解析通话消息
    final customElem = message.customElem;
    final data = customElem?.data ?? '';

    // 使用模型解析数据
    final callMessage = CallStatusChangeMessage.fromJsonString(data);

    // 获取显示信息
    String displayText;
    Color textColor;
    Color iconColor;

    if (callMessage != null) {
      if (callMessage.hasValidCallTime) {
        // 已接听 - 显示时长
        displayText = callMessage.formattedDuration;
        textColor = isSelf ? Colors.black87 : Colors.white;
        iconColor = Colors.green;
      } else if (callMessage.isMissed) {
        // 未接听
        displayText = 'Missed';
        textColor = Colors.red;
        iconColor = Colors.red;
      } else if (callMessage.isDeclined) {
        // 拒接
        displayText = 'Declined';
        textColor = Colors.orange;
        iconColor = Colors.orange;
      } else if (callMessage.isCanceled) {
        // 取消
        displayText = 'Canceled';
        textColor = Colors.grey;
        iconColor = Colors.grey;
      } else {
        // 默认使用 formattedTypeText
        displayText = callMessage.formattedTypeText;
        textColor = isSelf ? Colors.black87 : Colors.white;
        iconColor = isSelf ? Colors.black54 : Colors.white70;
      }
    } else {
      // 解析失败，使用默认显示
      displayText = 'Call';
      textColor = isSelf ? Colors.black87 : Colors.white;
      iconColor = isSelf ? Colors.black54 : Colors.white70;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isSelf ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 对方头像
          if (!isSelf) ...[
            _buildAvatar(controller.userAvatar, controller.userName),
            const SizedBox(width: 8),
          ],
          // 通话消息气泡
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelf ? const Color(0xFFFFE4E1) : const Color(0xFF3A3A3A),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.videocam,
                  color: iconColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  displayText,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                // 显示花费金币（如果有）
                if (callMessage != null && 
                    callMessage.spendCoin != null && 
                    callMessage.spendCoin! > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.monetization_on,
                          color: Colors.orange,
                          size: 12,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${callMessage.spendCoin!.toInt()}',
                          style: const TextStyle(
                            color: Colors.orange,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建输入框
  Widget _buildInputBar(MessageChatController controller) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(Get.context!).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        border: Border(
          top: BorderSide(color: Colors.grey[800]!, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // 输入框
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: controller.textController,
                focusNode: controller.inputFocusNode,
                maxLines: 4,
                minLines: 1,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                ),
                decoration: InputDecoration(
                  hintText: 'Message',
                  hintStyle: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 15,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onTap: controller.hideEmojiPanel,
                onSubmitted: (_) => controller.sendTextMessage(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // 发送按钮
          Obx(() => GestureDetector(
            onTap: controller.sendTextMessage,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: controller.hasInputContent.value 
                    ? const Color(0xFFFF1493) 
                    : Colors.grey[700],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.send,
                color: controller.hasInputContent.value 
                    ? Colors.white 
                    : Colors.grey,
                size: 22,
              ),
            ),
          )),
        ],
      ),
    );
  }
}

/// 举报弹窗内容：单选列表 + Cancel/Submit
class _ChatReportDialogContent extends StatefulWidget {
  final List<DictItem> options;
  final void Function(int value) onSubmit;

  const _ChatReportDialogContent({
    required this.options,
    required this.onSubmit,
  });

  @override
  State<_ChatReportDialogContent> createState() => _ChatReportDialogContentState();
}

class _ChatReportDialogContentState extends State<_ChatReportDialogContent> {
  DictItem? _selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A4A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Report',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 20),
          ...widget.options.map((item) => _buildOption(item)),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Get.back(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFF1493), width: 1),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (_selected == null) {
                      ToastUtils.showError('Please select a report reason');
                      return;
                    }
                    widget.onSubmit(_selected!.value);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF1493), Color(0xFF9C27B0)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'Submit',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOption(DictItem item) {
    final isSelected = _selected?.value == item.value;
    return GestureDetector(
      onTap: () => setState(() => _selected = item),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                item.label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 15,
                  decoration: TextDecoration.none,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? Colors.white : Colors.grey.withOpacity(0.5),
                border: Border.all(color: isSelected ? Colors.white : Colors.grey, width: 1),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Color(0xFF4CAF50), size: 16)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
