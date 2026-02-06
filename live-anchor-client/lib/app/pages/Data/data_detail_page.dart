import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/data_detail_controller.dart';

/// 数据详情页面
class DataDetailPage extends StatelessWidget {
  const DataDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(DataDetailController());

    return Scaffold(
      backgroundColor: const Color(0xFF1A0D2E), // 深紫色背景
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(controller),
            _buildDateSelector(controller),
            const SizedBox(height: 16),
            Expanded(
              child: RefreshIndicator(
                onRefresh: controller.refresh,
                color: const Color(0xFFFF1493),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: _buildDataList(controller),
                ),
              ),
            ),
            _buildTotalIncomeFooter(controller),
          ],
        ),
      ),
    );
  }

  /// 构建顶部导航栏
  Widget _buildAppBar(DataDetailController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
          ),
          const Text(
            'Data',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          GestureDetector(
            onTap: () {
              controller.showAboutDataDialog();
            },
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: const Center(
                child: Text(
                  '!',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建日期选择器
  Widget _buildDateSelector(DataDetailController controller) {
    return Obx(() {
      final isToday = controller.isToday(controller.selectedDate.value);
      final dateStr = controller.formatDate(controller.selectedDate.value);

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF9C27B0), Color(0xFF673AB7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isToday ? 'Today' : 'Selected Date', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  dateStr,
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: Get.context!,
                  initialDate: controller.selectedDate.value,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.dark(
                          primary: Color(0xFFFF1493),
                          onPrimary: Colors.white,
                          surface: Color(0xFF1A0D2E),
                          onSurface: Colors.white,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (picked != null) {
                  await controller.selectDate(picked);
                }
              },
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.calendar_today, color: Colors.white, size: 24),
              ),
            ),
          ],
        ),
      );
    });
  }

  /// 构建数据列表
  Widget _buildDataList(DataDetailController controller) {
    return Obx(() {
      // 显示加载指示器
      if (controller.isLoading) {
        return const SizedBox(
          height: 400,
          child: Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF1493)))),
        );
      }

      // 即使数据为空，也显示所有数据项（值为0或默认值）
      final report = controller.workReport.value;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            _buildDataItem(
              label: 'Online time',
              value: controller.formatOnlineTime(report?.onlineTime),
              valueColor: Colors.white,
            ),
            const SizedBox(height: 12),
            _buildDataItem(
              label: 'Incoming call',
              value: '${report?.callingNum ?? 0}/${report?.callNum ?? 0}',
              valueColor: const Color(0xFF4CAF50), // 绿色
            ),
            const SizedBox(height: 12),
            _buildDataItem(
              label: 'Connection rate',
              value: '${(report?.connectionRate ?? 0.0).toStringAsFixed(1)}',
              valueColor: const Color(0xFFE53935), // 红色
            ),
            const SizedBox(height: 12),
            _buildDataItem(
              label: 'Call income',
              value: (report?.callIncome ?? 0.0).toStringAsFixed(2),
              valueColor: Colors.white,
            ),
            const SizedBox(height: 12),
            _buildDataItem(
              label: 'Match conversion',
              value: (report?.matchConversion ?? 0.0).toStringAsFixed(0),
              valueColor: Colors.white,
            ),
            const SizedBox(height: 12),
            _buildDataItem(
              label: 'Match conversion rewards',
              value: (report?.matchConversionRewards ?? 0.0).toStringAsFixed(1),
              valueColor: Colors.white,
            ),
            const SizedBox(height: 12),
            _buildDataItem(
              label: 'Gift income',
              value: (report?.giftIncome ?? 0.0).toStringAsFixed(1),
              valueColor: Colors.white,
            ),
            const SizedBox(height: 12),
            _buildDataItem(
              label: 'Video income',
              value: (report?.videoIncome ?? 0.0).toStringAsFixed(1),
              valueColor: Colors.white,
            ),
            const SizedBox(height: 16), // 底部留一些空间
          ],
        ),
      );
    });
  }

  /// 构建单个数据项
  Widget _buildDataItem({required String label, required String value, required Color valueColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF362A5A), // 深紫色卡片背景
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 16)),
          Text(
            value,
            style: TextStyle(color: valueColor, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  /// 构建底部总收入
  Widget _buildTotalIncomeFooter(DataDetailController controller) {
    return Obx(() {
      final totalIncome = controller.workReport.value?.totalIncome ?? 0.0;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFF1493), Color(0xFFFF69B4)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Total income:',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
            ),
            Text(
              '\$ ${totalIncome.toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    });
  }
}
