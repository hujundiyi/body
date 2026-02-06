import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/base/base_controller.dart';
import '../../core/network/anchor_api_service.dart';
import '../../data/models/commission_model.dart';

/// 账单详情控制器
class BillDetailController extends BaseController {
  // 佣金记录列表
  final RxList<CommissionRecord> commissionRecords = <CommissionRecord>[].obs;

  // 月份时间戳（从参数获取）
  int? monthTimestamp;

  // 分页参数
  int _currentPage = 1;
  final int _pageSize = 20;
  final RxBool _hasMore = true.obs;
  bool get hasMore => _hasMore.value;
  final RxBool _isLoadingMore = false.obs;
  bool get isLoadingMore => _isLoadingMore.value;

  @override
  void onControllerInit() {
    super.onControllerInit();
    // 获取传递的月份时间戳参数
    final args = Get.arguments;
    if (args != null && args is Map) {
      monthTimestamp = args['month'] as int?;
    }
    loadCommissionList();
  }

  /// 加载佣金记录列表（page 从 1 开始，filterTime 传 bill_page 请求下来的 month 字段值）
  Future<void> loadCommissionList({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore.value = true;
      commissionRecords.clear();
    }

    if (!_hasMore.value || _isLoadingMore.value) return;

    _isLoadingMore.value = true;
    await executeWithLoading(() async {
      try {
        final records = await AnchorAPIService.shared.getCommissionList(
          page: _currentPage, // page 从 1 开始
          size: _pageSize,
          filterTimeStamp: monthTimestamp, // bill_page 请求下来的 month 字段值
          coinChangeType: null,
        );

        if (records.isEmpty) {
          _hasMore.value = false;
        } else {
          commissionRecords.addAll(records);
          _currentPage++;
          if (records.length < _pageSize) {
            _hasMore.value = false;
          }
        }
      } catch (e) {
        debugPrint('Failed to load commission list: $e');
        showErrorUnlessAuth(e, 'Failed to load commission records');
      } finally {
        _isLoadingMore.value = false;
      }
    });
  }

  /// 刷新数据
  @override
  Future<void> refresh() async {
    await loadCommissionList(refresh: true);
  }

  /// 格式化日期时间（从 DateTime 转换为 "MM-dd HH:mm" 格式）
  String formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    return '${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// 格式化金额显示
  String formatAmount(double? amount) {
    if (amount == null) return '0.00';
    return amount.toStringAsFixed(2);
  }
}
