import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_conversation.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_message.dart';
import '../../core/network/api_client.dart';
import '../../core/services/im_service.dart';
import '../../data/models/call_data_model.dart';

/// 用户信息模型（用于缓存）
class UserBasicInfo {
  final int userId;
  final String? nickname;
  final String? avatar;

  UserBasicInfo({
    required this.userId,
    this.nickname,
    this.avatar,
  });

  factory UserBasicInfo.fromJson(Map<String, dynamic> json) {
    return UserBasicInfo(
      userId: json['userId'] as int? ?? 0,
      nickname: json['nickname'] as String?,
      avatar: json['avatar'] as String?,
    );
  }
}

/// 消息列表控制器
class MessageListController extends GetxController {
  // IM 服务
  IMService get _imService => Get.find<IMService>();
  
  // 会话列表（IM 服务已过滤黑名单）
  final RxList<V2TimConversation> conversationList = <V2TimConversation>[].obs;
  
  // 未读消息总数
  final RxInt totalUnreadCount = 0.obs;
  
  // 加载状态
  final RxBool isLoading = false.obs;

  // 消息监听
  Worker? _messageWorker;

  // 用户信息缓存 (userId -> UserBasicInfo)
  final RxMap<String, UserBasicInfo> userInfoCache = <String, UserBasicInfo>{}.obs;

  // 是否已登录 IM
  bool get isIMLoggedIn => _imService.isLoggedIn;

  @override
  void onInit() {
    super.onInit();
    _setupListeners();
    _loadConversations();
  }
  
  @override
  void onClose() {
    _removeListeners();
    super.onClose();
  }
  
  /// 设置监听器
  void _setupListeners() {
    // 监听会话变更（新消息到达时会话也会更新，会触发此回调）
    _imService.onConversationChanged = (conversations) {
      debugPrint('会话变更: ${conversations.length}');
      _updateConversations(conversations);
    };
  }
  
  /// 移除监听器
  void _removeListeners() {
    _imService.onConversationChanged = null;
  }
  
  /// 加载会话列表
  Future<void> _loadConversations() async {
    if (!isIMLoggedIn) {
      debugPrint('IM 未登录，跳过加载会话列表');
      return;
    }
    
    isLoading.value = true;
    
    try {
      final list = await _imService.getConversationList();
      conversationList.assignAll(list);
      
      // 计算未读总数
      int unread = 0;
      for (var conv in list) {
        unread += conv.unreadCount ?? 0;
      }
      totalUnreadCount.value = unread;
      debugPrint('Conversation list loaded: ${list.length} conversations, $unread unread');
      // 批量获取用户信息
      await _fetchUserInfoBatch(list);
    } catch (e) {
      debugPrint('加载会话列表失败: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// 批量获取用户信息
  Future<void> _fetchUserInfoBatch(List<V2TimConversation> conversations) async {
    // 收集需要获取信息的用户ID（排除已缓存的）
    final userIds = <int>[];
    for (var conv in conversations) {
      final userId = conv.userID;
      if (userId != null && userId.isNotEmpty && !userInfoCache.containsKey(userId)) {
        final id = int.tryParse(userId);
        if (id != null && !userIds.contains(id)) {
          userIds.add(id);
        }
      }
    }

    if (userIds.isEmpty) {
      debugPrint('[MessageListController] 无需获取用户信息');
      return;
    }

    debugPrint('[MessageListController] 批量获取用户信息: $userIds');

    try {
      final response = await APIClient.shared.request<List<dynamic>>(
        'userStatus/getBatchList',
        arrayParams: userIds,
      );

      for (var item in response) {
        if (item is Map<String, dynamic>) {
          final userInfo = UserBasicInfo.fromJson(item);
          if (userInfo.userId > 0) {
            userInfoCache[userInfo.userId.toString()] = userInfo;
          }
        }
      }

      debugPrint('[MessageListController] 用户信息获取成功: ${response.length} 条');
    } catch (e) {
      debugPrint('[MessageListController] 批量获取用户信息失败: $e');
    }
  }
  
  /// 更新会话列表
  void _updateConversations(List<V2TimConversation> updatedList) {
    for (var conv in updatedList) {
      final index = conversationList.indexWhere(
        (c) => c.conversationID == conv.conversationID,
      );
      if (index >= 0) {
        conversationList[index] = conv;
      } else {
        conversationList.add(conv);
      }
    }
    
    // 按最后消息时间排序
    conversationList.sort((a, b) {
      // 置顶优先
      if (a.isPinned == true && b.isPinned != true) return -1;
      if (b.isPinned == true && a.isPinned != true) return 1;
      
      // 按时间排序
      final timeA = a.lastMessage?.timestamp ?? 0;
      final timeB = b.lastMessage?.timestamp ?? 0;
      return timeB.compareTo(timeA);
    });
    
    // 更新未读总数
    int unread = 0;
    for (var conv in conversationList) {
      unread += conv.unreadCount ?? 0;
    }
    totalUnreadCount.value = unread;
  }
  
  /// 刷新会话列表
  @override
  Future<void> refresh() async {
    await _loadConversations();
  }
  
  /// 删除会话
  Future<bool> deleteConversation(String conversationID) async {
    final success = await _imService.deleteConversation(conversationID);
    if (success) {
      conversationList.removeWhere((c) => c.conversationID == conversationID);
    }
    return success;
  }
  
  /// 置顶/取消置顶会话
  Future<bool> pinConversation(String conversationID, bool isPinned) async {
    final success = await _imService.pinConversation(
      conversationID: conversationID,
      isPinned: isPinned,
    );
    if (success) {
      final index = conversationList.indexWhere(
        (c) => c.conversationID == conversationID,
      );
      if (index >= 0) {
        // 刷新列表以更新排序
        await _loadConversations();
      }
    }
    return success;
  }
  
  /// 标记会话已读
  Future<void> markAsRead(V2TimConversation conversation) async {
    final userID = conversation.userID;
    final groupID = conversation.groupID;
    
    if (userID != null && userID.isNotEmpty) {
      await _imService.markC2CMessageAsRead(userID);
    } else if (groupID != null && groupID.isNotEmpty) {
      await _imService.markGroupMessageAsRead(groupID);
    }
    
    // 刷新会话列表
    await _loadConversations();
  }
  
  /// 获取会话显示名称
  String getConversationName(V2TimConversation conversation) {
    // 优先使用缓存的用户信息
    final userId = conversation.userID;
    if (userId != null && userInfoCache.containsKey(userId)) {
      final cachedInfo = userInfoCache[userId]!;
      if (cachedInfo.nickname != null && cachedInfo.nickname!.isNotEmpty) {
        return cachedInfo.nickname!;
      }
    }
    
    return conversation.showName ?? 
           conversation.userID ?? 
           conversation.groupID ?? 
           'Unknown';
  }
  
  /// 获取会话头像
  String getConversationAvatar(V2TimConversation conversation) {
    // 优先使用缓存的用户信息
    final userId = conversation.userID;
    if (userId != null && userInfoCache.containsKey(userId)) {
      final cachedInfo = userInfoCache[userId]!;
      if (cachedInfo.avatar != null && cachedInfo.avatar!.isNotEmpty) {
        return cachedInfo.avatar!;
      }
    }
    
    return conversation.faceUrl ?? '';
  }

  /// 解析通话消息摘要（与 message_chat_page._buildCallMessageItem 文案一致）
  String _getCallMessageSummary(V2TimMessage lastMessage) {
    final data = lastMessage.customElem?.data ?? '';
    if (data.isEmpty) return '[Call Message]';
    final callMessage = CallStatusChangeMessage.fromJsonString(data);
    if (callMessage == null) return '[Call Message]';
    if (callMessage.hasValidCallTime) return callMessage.formattedDuration;
    if (callMessage.isMissed) return '[Call Missed]';
    if (callMessage.isDeclined) return '[Call Declined]';
    if (callMessage.isCanceled) return '[Call Canceled]';
    final typeText = callMessage.formattedTypeText;
    return typeText.isNotEmpty ? typeText : '[Call Message]';
  }
  
  /// 获取最后一条消息摘要
  String getLastMessageSummary(V2TimConversation conversation) {
    final lastMessage = conversation.lastMessage;
    if (lastMessage == null) return '';
    
    // 根据消息类型返回不同的摘要
    final elemType = lastMessage.elemType;
    
    switch (elemType) {
      case 1: // 文本消息
        return lastMessage.textElem?.text ?? '';
      case 2: // 自定义消息（通话消息），解析内容与 message_chat_page._buildCallMessageItem 一致
        return _getCallMessageSummary(lastMessage);
      case 3: // 图片消息
        return '[Image]';
      case 4: // 语音消息
        return '[Voice]';
      case 5: // 视频消息
        return '[Video]';
      case 6: // 文件消息
        return '[File]';
      case 7: // 位置消息
        return '[Location]';
      case 8: // 表情消息
        return '[Emoji]';
      default:
        return '[Message]';
    }
  }
  
  /// 格式化时间
  String formatTime(int? timestamp) {
    if (timestamp == null || timestamp == 0) return '';
    
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    
    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${dateTime.month}/${dateTime.day}';
    }
  }
}
