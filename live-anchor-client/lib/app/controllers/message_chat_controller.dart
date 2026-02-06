import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_message.dart';
import 'package:tencent_cloud_chat_sdk/enum/message_elem_type.dart';
import '../../core/services/im_service.dart';
import '../../core/services/call_service.dart';
import '../../core/utils/toast_utils.dart';
import '../../data/models/call_data_model.dart';
import '../../data/models/user_model_entity.dart';

/// 聊天详情控制器
class MessageChatController extends GetxController {
  // IM 服务
  IMService get _imService => Get.find<IMService>();

  // 聊天参数
  late String conversationID;
  late String? userID;
  late String? groupID;
  late String userName;
  late String userAvatar;

  // 消息列表
  final RxList<V2TimMessage> messageList = <V2TimMessage>[].obs;

  // 状态
  final RxBool isLoading = false.obs;
  final RxBool isSending = false.obs;
  final RxBool hasMore = true.obs;

  // 输入控制器
  final TextEditingController textController = TextEditingController();
  final FocusNode inputFocusNode = FocusNode();
  final ScrollController scrollController = ScrollController();

  // 是否显示表情面板
  final RxBool showEmojiPanel = false.obs;

  // 输入框是否有内容
  final RxBool hasInputContent = false.obs;

  // 消息监听
  Worker? _messageWorker;
  Worker? _modifiedMessageWorker;

  // 当前用户ID
  String? get currentUserID => _imService.currentUserID;

  @override
  void onInit() {
    super.onInit();
    _initArguments();
    _imService.setActiveConversation(userID: userID, groupID: groupID);
    _setupListeners();
    _loadMessages();
    
    // 监听输入框内容变化
    textController.addListener(_onInputChanged);
  }
  
  /// 输入内容变化监听
  void _onInputChanged() {
    hasInputContent.value = textController.text.trim().isNotEmpty;
  }

  @override
  void onClose() {
    textController.removeListener(_onInputChanged);
    textController.dispose();
    inputFocusNode.dispose();
    scrollController.dispose();
    _removeListeners();
    _imService.clearActiveConversation();
    super.onClose();
  }

  /// 初始化参数
  void _initArguments() {
    final args = Get.arguments as Map<String, dynamic>?;
    conversationID = args?['conversationID'] ?? '';
    userID = args?['userID'];
    groupID = args?['groupID'];
    userName = args?['name'] ?? 'User';
    userAvatar = args?['avatar'] ?? '';
  }

  /// 设置监听器
  void _setupListeners() {
    // 监听新消息
    _messageWorker = ever(_imService.newMessages, (messages) {
      for (var msg in messages) {
        // 判断消息是否属于当前会话
        if (_isCurrentConversation(msg)) {
          messageList.insert(0, msg);
        }
      }
    });

    // 监听消息被服务端修改（如翻译完成写入 IM），更新当前会话 messageList
    _modifiedMessageWorker = ever(_imService.modifiedMessages, (messages) {
      for (final message in messages) {
        if (!_isCurrentConversation(message)) continue;
        final msgID = message.msgID;
        if (msgID == null || msgID.isEmpty) continue;
        final index = messageList.indexWhere((m) => m.msgID == msgID);
        if (index >= 0) {
          messageList[index] = message;
        }
      }
    });

    // 监听滚动加载更多
    scrollController.addListener(() {
      if (scrollController.position.pixels >=
          scrollController.position.maxScrollExtent - 100) {
        loadMoreMessages();
      }
    });
  }

  /// 移除监听器
  void _removeListeners() {
    _modifiedMessageWorker?.dispose();
    _modifiedMessageWorker = null;
    _messageWorker?.dispose();
    _messageWorker = null;
  }

  /// 判断消息是否属于当前会话
  bool _isCurrentConversation(V2TimMessage message) {
    if (userID != null && userID!.isNotEmpty) {
      return message.userID == userID || message.sender == userID;
    }
    if (groupID != null && groupID!.isNotEmpty) {
      return message.groupID == groupID;
    }
    return false;
  }

  /// 加载消息
  Future<void> _loadMessages() async {
    if (isLoading.value) return;

    isLoading.value = true;

    try {
      final targetID = userID ?? groupID ?? '';
      final isGroup = groupID != null && groupID!.isNotEmpty;

      final messages = await _imService.getHistoryMessageList(
        userID: targetID,
        isGroup: isGroup,
        count: 20,
      );

      messageList.assignAll(messages);
      hasMore.value = messages.length >= 20;

      // 标记已读
      _markAsRead();
    } catch (e) {
      debugPrint('Failed to load messages: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// 加载更多消息
  Future<void> loadMoreMessages() async {
    if (isLoading.value || !hasMore.value || messageList.isEmpty) return;

    isLoading.value = true;

    try {
      final targetID = userID ?? groupID ?? '';
      final isGroup = groupID != null && groupID!.isNotEmpty;
      final lastMsg = messageList.last;

      final messages = await _imService.getHistoryMessageList(
        userID: targetID,
        isGroup: isGroup,
        count: 20,
        lastMsg: lastMsg,
      );

      if (messages.isNotEmpty) {
        messageList.addAll(messages);
      }
      hasMore.value = messages.length >= 20;
    } catch (e) {
      debugPrint('Failed to load more messages: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// 刷新消息
  Future<void> refresh() async {
    hasMore.value = true;
    await _loadMessages();
  }

  /// 标记已读
  Future<void> _markAsRead() async {
    if (userID != null && userID!.isNotEmpty) {
      await _imService.markC2CMessageAsRead(userID!);
    } else if (groupID != null && groupID!.isNotEmpty) {
      await _imService.markGroupMessageAsRead(groupID!);
    }
  }

  /// 发送文本消息
  Future<void> sendTextMessage() async {
    final text = textController.text.trim();
    if (text.isEmpty || isSending.value) return;

    isSending.value = true;
    textController.clear();

    try {
      final targetID = userID ?? groupID ?? '';
      final isGroup = groupID != null && groupID!.isNotEmpty;

      final message = await _imService.sendTextMessage(
        text: text,
        receiver: targetID,
        isGroup: isGroup,
      );

      if (message != null) {
        messageList.insert(0, message);
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('Failed to send message: $e');
      ToastUtils.showError('Failed to send message, please try again', title: 'Send Failed');
    } finally {
      isSending.value = false;
    }
  }

  /// 发送图片消息
  Future<void> sendImageMessage(String imagePath) async {
    if (isSending.value) return;

    isSending.value = true;

    try {
      final targetID = userID ?? groupID ?? '';
      final isGroup = groupID != null && groupID!.isNotEmpty;

      final message = await _imService.sendImageMessage(
        imagePath: imagePath,
        receiver: targetID,
        isGroup: isGroup,
      );

      if (message != null) {
        messageList.insert(0, message);
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('Failed to send image: $e');
      ToastUtils.showError('Failed to send image, please try again', title: 'Send Failed');
    } finally {
      isSending.value = false;
    }
  }

  /// 滚动到底部
  void _scrollToBottom() {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  /// 切换表情面板
  void toggleEmojiPanel() {
    showEmojiPanel.value = !showEmojiPanel.value;
    if (showEmojiPanel.value) {
      inputFocusNode.unfocus();
    }
  }

  /// 隐藏表情面板
  void hideEmojiPanel() {
    showEmojiPanel.value = false;
  }

  /// 发起视频通话
  Future<void> startVideoCall() async {
    if (userID == null || userID!.isEmpty) {
      ToastUtils.showInfo('Unable to start call, user info incomplete');
      return;
    }

    // 解析用户ID为整数
    final int? targetUserId = int.tryParse(userID!);
    if (targetUserId == null) {
      ToastUtils.showInfo('Invalid user ID format');
      return;
    }

    // 构建用户信息
    final userInfo = UserModelEntity()
      ..userId = targetUserId
      ..nickname = userName
      ..avatar = userAvatar;

    // 发起通话
    if (Get.isRegistered<CallService>()) {
      final callService = Get.find<CallService>();
      await callService.createCall(
        toUserId: targetUserId,
        userInfo: userInfo,
      );
    } else {
      ToastUtils.showInfo('Call service not initialized');
    }
  }

  /// 判断消息是否是自己发送的
  bool isSelfMessage(V2TimMessage message) {
    return message.isSelf ?? false;
  }

  /// 获取消息显示内容
  String getMessageContent(V2TimMessage message) {
    final elemType = message.elemType;

    switch (elemType) {
      case MessageElemType.V2TIM_ELEM_TYPE_TEXT:
        return message.textElem?.text ?? '';
      case MessageElemType.V2TIM_ELEM_TYPE_IMAGE:
        return '[Image]';
      case MessageElemType.V2TIM_ELEM_TYPE_SOUND:
        return '[Voice]';
      case MessageElemType.V2TIM_ELEM_TYPE_VIDEO:
        return '[Video]';
      case MessageElemType.V2TIM_ELEM_TYPE_FILE:
        return '[File]';
      case MessageElemType.V2TIM_ELEM_TYPE_LOCATION:
        return '[Location]';
      case MessageElemType.V2TIM_ELEM_TYPE_FACE:
        return '[Sticker]';
      case MessageElemType.V2TIM_ELEM_TYPE_CUSTOM:
        return _parseCustomMessage(message);
      default:
        return '[Message]';
    }
  }

  /// Parse custom message
  String _parseCustomMessage(V2TimMessage message) {
    final customElem = message.customElem;
    if (customElem == null) return '[Custom Message]';

    // Parse video call message
    final data = customElem.data;
    if (data != null && data.contains('video_call')) {
      return '[Video Call]';
    }

    return '[Custom Message]';
  }

  /// 格式化消息时间
  String formatMessageTime(int? timestamp) {
    if (timestamp == null || timestamp == 0) return '';

    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inDays == 0) {
      // Today, show hour:minute
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      // Yesterday
      return 'Yesterday ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays < 7) {
      // Within a week
      final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return '${weekdays[dateTime.weekday - 1]} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      // Earlier
      return '${dateTime.month}/${dateTime.day} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  /// 判断是否需要显示时间分割
  bool shouldShowTimeDivider(int index) {
    if (index == messageList.length - 1) return true;

    final currentMsg = messageList[index];
    final nextMsg = messageList[index + 1];

    final currentTime = currentMsg.timestamp ?? 0;
    final nextTime = nextMsg.timestamp ?? 0;

    // 间隔超过5分钟显示时间
    return (currentTime - nextTime).abs() > 300;
  }
}
