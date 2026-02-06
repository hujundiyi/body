import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/base/base_controller.dart';
import '../../core/network/anchor_api_service.dart';
import '../../data/models/commission_model.dart';

/// 账单控制器
class BillController extends BaseController {
  // 月度账单列表
  final RxList<MonthCommission> monthBills = <MonthCommission>[].obs;
  
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
    loadMonthBills();
  }

  /// 加载月度账单列表
  Future<void> loadMonthBills({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore.value = true;
      monthBills.clear();
    }

    if (!_hasMore.value || _isLoadingMore.value) return;

    _isLoadingMore.value = true;
    await executeWithLoading(() async {
      try {
        final bills = await AnchorAPIService.shared.getMonthCommissionList(
          page: _currentPage,
          size: _pageSize,
        );

        if (bills.isEmpty) {
          _hasMore.value = false;
        } else {
          monthBills.addAll(bills);
          _currentPage++;
          if (bills.length < _pageSize) {
            _hasMore.value = false;
          }
        }
      } catch (e) {
        debugPrint('Failed to load month bills: $e');
        showErrorUnlessAuth(e, 'Failed to load bills');
      } finally {
        _isLoadingMore.value = false;
      }
    });
  }

  /// 刷新数据
  @override
  Future<void> refresh() async {
    await loadMonthBills(refresh: true);
  }

  /// 格式化月份显示（从时间戳转换为日期格式）
  String formatMonth(int? monthTimestamp) {
    if (monthTimestamp == null) return '';
    
    // 时间戳是秒级，转换为 DateTime
    final date = DateTime.fromMillisecondsSinceEpoch(monthTimestamp * 1000);
    
    // 格式化为 "yyyy-MM" 格式
    final year = date.year;
    final month = date.month.toString().padLeft(2, '0');
    return '$year-$month';
  }

  /// 格式化金额显示
  String formatAmount(double? amount) {
    if (amount == null) return '0.0';
    return amount.toStringAsFixed(2);
  }
}
