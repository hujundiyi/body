import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/network/anchor_api_service.dart';
import '../../data/models/call_history_model.dart';

/// 通话历史控制器
class CallHistoryController extends GetxController {
  // API 服务
  AnchorAPIService get _apiService => AnchorAPIService.shared;
  
  // 通话历史列表
  final RxList<CallHistory> callHistoryList = <CallHistory>[].obs;
  
  // 加载状态
  final RxBool isLoading = false.obs;
  
  // 分页
  int _page = 1;
  final int _pageSize = 20;
  final RxBool _hasMore = true.obs;
  
  // 是否还有更多数据
  bool get hasMore => _hasMore.value;
  
  @override
  void onInit() {
    super.onInit();
    _loadCallHistory();
  }
  
  /// 加载通话历史
  Future<void> _loadCallHistory({bool refresh = false}) async {
    if (refresh) {
      _page = 1;
      _hasMore.value = true;
      callHistoryList.clear();
    }
    
    if (!_hasMore.value) return;
    
    isLoading.value = true;
    
    try {
      final list = await _apiService.getCallHistory(
        page: _page,
        size: _pageSize,
      );
      
      if (list.isEmpty || list.length < _pageSize) {
        _hasMore.value = false;
      }
      
      if (refresh) {
        callHistoryList.assignAll(list);
      } else {
        callHistoryList.addAll(list);
      }
      
      _page++;
      
      debugPrint('Call history loaded successfully: ${list.length} records');
    } catch (e) {
      debugPrint('Failed to load call history: $e');
    } finally {
      isLoading.value = false;
    }
  }
  
  /// 刷新通话历史
  Future<void> refresh() async {
    await _loadCallHistory(refresh: true);
  }
  
  /// 加载更多通话历史
  Future<void> loadMore() async {
    if (!isLoading.value && _hasMore.value) {
      await _loadCallHistory();
    }
  }
  
  /// 格式化通话历史时间
  String formatCallTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    
    // 格式化时间部分
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final timeStr = '$hour:$minute';
    
    if (diff.inDays == 0) {
      return timeStr;
    } else if (diff.inDays == 1) {
      return 'Yesterday $timeStr';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago $timeStr';
    } else {
      return '${dateTime.month}/${dateTime.day} $timeStr';
    }
  }
  
  /// 获取通话状态文本
  String getCallStatusText(CallHistory call) {
    // 根据 callStatus 返回不同的状态文本
    // 10: Calling, 20: Connected, 30: Missed, 40: Ended, 50: Cancelled
    switch (call.callStatus) {
      case 10:
        return 'Calling';
      case 20:
        if (call.callTime != null && call.callTime! > 0) {
          return 'Call duration: ${call.formattedDuration}';
        }
        return 'Connected';
      case 30:
        return 'Missed';
      case 40:
        if (call.callTime != null && call.callTime! > 0) {
          return 'Call duration: ${call.formattedDuration}';
        }
        return 'Ended';
      case 50:
        return 'Cancelled';
      default:
        if (call.callTime != null && call.callTime! > 0) {
          return 'Call duration: ${call.formattedDuration}';
        }
        return call.callStatusText;
    }
  }
  
  /// 是否为成功通话
  bool isSuccessfulCall(CallHistory call) {
    // callStatus 20 或 40 且有通话时长视为成功通话
    return (call.callStatus == 20 || call.callStatus == 40) && (call.callTime ?? 0) > 0;
  }

  /// 拨打电话
  void makeCall(CallHistory call) {
    if (call.userId == null) return;
    
    debugPrint('Making call to user: ${call.nickname} (ID: ${call.userId})');
    // TODO: 实现视频通话功能
    Get.snackbar(
      'Calling',
      'Calling ${call.nickname}...',
      snackPosition: SnackPosition.TOP,
      backgroundColor: const Color(0xFFFF1493),
      colorText: Colors.white,
    );
  }
}
