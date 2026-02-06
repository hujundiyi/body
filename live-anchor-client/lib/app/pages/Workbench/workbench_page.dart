import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/workbench_controller.dart';
import '../../controllers/permission_controller.dart';
import '../../controllers/work_rules_controller.dart';
import '../../controllers/service_controller.dart';
import '../../../routes/app_routes.dart';
import '../../pages/Permission/permission_page.dart';
import '../../pages/WorkRules/work_rules_page.dart';
import '../../pages/Service/service_page.dart';

/// 工作台页面
class WorkbenchPage extends StatelessWidget {
  const WorkbenchPage({super.key});

  // 控制是否显示 Work Rules 入口（隐藏但保留代码）
  static const bool _showWorkRules = false;

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(WorkbenchController());
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // 固定在顶部的头部
            _buildHeader(controller),
            // 可滚动的内容区域
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildIncomeCard(controller),
                    _buildWithdrawButton(controller),
                    _buildMoreSection(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建头部
  Widget _buildHeader(WorkbenchController controller) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Workbench',
            style: TextStyle(
              color: Color(0xFFFF1493),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Obx(() => GestureDetector(
            onTap: controller.isLoading ? null : controller.refresh,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: controller.isLoading 
                    ? Colors.grey 
                    : const Color(0xFF00C853),
                shape: BoxShape.circle,
              ),
              child: controller.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(
                      Icons.refresh,
                      color: Colors.white,
                      size: 24,
                    ),
            ),
          )),
        ],
      ),
    );
  }

  /// 构建收入卡片
  Widget _buildIncomeCard(WorkbenchController controller) {
    return Obx(() {
      final totalIncome = controller.totalIncome;
      final availableBalance = controller.availableBalance;
      final pendingBalance = controller.pendingBalance;
      
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF1493), Color(0xFF9C27B0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Income',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      '\$${totalIncome.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => controller.showAboutIncomeDialog(),
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.help_outline,
                          color: Color(0xFFFF1493),
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        const Text(
                          'Available',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '\$${availableBalance.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        const Text(
                          'Pending',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '\$${pendingBalance.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  /// 构建提现按钮
  Widget _buildWithdrawButton(WorkbenchController controller) {
    return GestureDetector(
      onTap: () {
        controller.showWithdrawTipDialog();
      },
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF1493), Color(0xFFFF69B4)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(30),
        ),
        child: const Center(
          child: Text(
            'Withdraw',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  /// 构建更多功能区
  Widget _buildMoreSection() {
    return Column(
      children: [
        const Text(
          '- MORE -',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMenuItem(
                    icon: Icons.receipt_long,
                    label: 'My Bill',
                    color: const Color(0xFFFF6B35),
                    onTap: () {
                      Get.toNamed(AppRoutes.bill);
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.pie_chart,
                    label: 'Data',
                    color: const Color(0xFF00BCD4),
                    onTap: () {
                      Get.toNamed(AppRoutes.dataDetail);
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.waving_hand,
                    label: 'Say Hi',
                    color: const Color(0xFFFF9800),
                    onTap: () {
                      Get.toNamed(AppRoutes.sayHi);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMenuItem(
                    icon: Icons.security,
                    label: 'Permission',
                    color: const Color(0xFF7C4DFF),
                    onTap: () {
                      Get.to(
                        () => const PermissionPage(),
                        binding: BindingsBuilder(() {
                          Get.put<PermissionController>(PermissionController());
                        }),
                      );
                    },
                  ),
                  // Work Rules 入口（已隐藏，代码保留）
                  if (_showWorkRules)
                    _buildMenuItem(
                      icon: Icons.article,
                      label: 'Work Rules',
                      color: const Color(0xFFFF1493),
                      onTap: () {
                        Get.to(
                          () => const WorkRulesPage(),
                          binding: BindingsBuilder(() {
                            Get.put<WorkRulesController>(WorkRulesController());
                          }),
                        );
                      },
                    ),
                  _buildMenuItem(
                    icon: Icons.headset_mic,
                    label: 'Service',
                    color: const Color(0xFFFF4081),
                    onTap: () {
                      Get.to(
                        () => const ServicePage(),
                        binding: BindingsBuilder(() {
                          Get.put<ServiceController>(ServiceController());
                        }),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap ?? () {
        // TODO: 处理点击
      },
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
