import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/base/base_controller.dart';
import '../../core/network/anchor_api_service.dart';
import '../../data/models/commission_model.dart';

/// 数据详情控制器
class DataDetailController extends BaseController {
  // 工作报表数据
  final Rx<WorkReport?> workReport = Rx<WorkReport?>(null);
  
  // 选中的日期（默认为今天）
  final Rx<DateTime> selectedDate = DateTime.now().obs;

  @override
  void onControllerInit() {
    super.onControllerInit();
    loadWorkReport();
  }

  /// 加载工作报表数据
  Future<void> loadWorkReport({bool refresh = false}) async {
    if (refresh) {
      setLoading(true);
    } else {
      // 首次加载时也显示加载状态
      setLoading(true);
    }

    try {
      // 将日期转换为当天的开始时间（00:00:00）
      final filterDate = DateTime(
        selectedDate.value.year,
        selectedDate.value.month,
        selectedDate.value.day,
      );
      
      final report = await AnchorAPIService.shared.getWorkReport(
        filterTime: filterDate,
      );
      workReport.value = report;
    } catch (e) {
      debugPrint('Failed to load work report: $e');
      showErrorUnlessAuth(e, 'Failed to load data');
    } finally {
      setLoading(false);
    }
  }

  /// 刷新数据
  @override
  Future<void> refresh() async {
    await loadWorkReport(refresh: true);
  }

  /// 选择日期
  Future<void> selectDate(DateTime date) async {
    selectedDate.value = date;
    await loadWorkReport(refresh: true);
  }

  /// 格式化在线时长（分钟转为 HH:MM:SS）
  String formatOnlineTime(int? minutes) {
    if (minutes == null || minutes == 0) {
      return '00:00:00';
    }
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    final secs = 0; // 接口返回的是分钟，秒数设为0
    return '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  /// 格式化日期显示
  String formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// 判断是否为今天
  bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && 
           date.month == now.month && 
           date.day == now.day;
  }

  /// 显示关于数据的说明弹窗
  void showAboutDataDialog() {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF362A5A),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF4A3D6B),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 标题
              const Text(
                'About data',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              // 正文内容
              const Text(
                'Data statistics are displayed daily, and you can view the data of the past 30 days. If the recent data performs well, you can contact the staff to adjust your level to obtain higher income.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.5,
                ),
                textAlign: TextAlign.left,
              ),
              const SizedBox(height: 24),
              // OK 按钮
              GestureDetector(
                onTap: () => Get.back(),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF1493), Color(0xFF9C27B0)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      'OK',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }
}
