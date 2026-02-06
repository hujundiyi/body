import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/withdraw_controller.dart';
import '../../../core/services/app_config_service.dart';

/// 提现页面
class WithdrawPage extends StatelessWidget {
  const WithdrawPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(WithdrawController());

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E), // 深蓝色背景
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Withdraw',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: controller.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 支付方式选择
              _buildPayeeMethodSection(controller),

              const SizedBox(height: 24),

              // 收款人姓名
              _buildPayeeNameField(controller),

              const SizedBox(height: 16),

              // 账号
              _buildAccountField(controller),

              const SizedBox(height: 16),

              // 金额
              _buildAmountField(controller),

              const SizedBox(height: 24),

              // 提现说明
              _buildWithdrawalInstructions(),

              const SizedBox(height: 32),

              // 提现按钮
              _buildWithdrawButton(controller),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建支付方式选择区域
  Widget _buildPayeeMethodSection(WithdrawController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payee Method',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 12),
        Obx(() {
          if (controller.payMethods.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF1493))),
              ),
            );
          }

          return Row(
            children: [
              ...controller.payMethods.asMap().entries.map((entry) {
                final index = entry.key;
                final payMethod = entry.value;
                final isSelected = controller.selectedPayType.value == payMethod.value;

                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: index < controller.payMethods.length - 1 ? 12 : 0),
                    child: GestureDetector(
                      onTap: () => controller.selectPayType(payMethod.value),
                      child: Container(
                        height: 80,
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF362A5A) : Colors.grey[900]!.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF4CAF50) // 绿色边框（选中）
                                : Colors.grey[700]!, // 浅灰色边框（未选中）
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // 如果有图标，显示图标
                                  if (payMethod.icon != null && payMethod.icon!.isNotEmpty)
                                    Image.network(
                                      payMethod.icon!,
                                      width: 32,
                                      height: 32,
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Icon(Icons.payment, color: Color(0xFF00BCD4), size: 32);
                                      },
                                    )
                                  else
                                    const Icon(Icons.payment, color: Color(0xFF00BCD4), size: 32),
                                  const SizedBox(height: 4),
                                  Text(
                                    payMethod.label,
                                    style: TextStyle(
                                      color: isSelected
                                          ? const Color(0xFF00BCD4) // 青色文字（选中）
                                          : Colors.grey[500], // 浅灰色文字（未选中）
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // 选中标记
                            if (isSelected)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: const BoxDecoration(color: Color(0xFF4CAF50), shape: BoxShape.circle),
                                  child: const Icon(Icons.check, color: Colors.white, size: 14),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          );
        }),
      ],
    );
  }

  /// 构建收款人姓名字段
  Widget _buildPayeeNameField(WithdrawController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payee Name',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller.payeeNameController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter your true name',
            hintStyle: TextStyle(color: Colors.grey[600]),
            filled: true,
            fillColor: const Color(0xFF362A5A),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[800]!, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFFF1493), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            suffixIcon: Obx(() {
              if (controller.payeeNameHasText.value) {
                return IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    controller.payeeNameController.clear();
                  },
                );
              }
              return const SizedBox.shrink();
            }),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          validator: controller.validatePayeeName,
        ),
      ],
    );
  }

  /// 构建账号字段
  Widget _buildAccountField(WithdrawController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Account',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller.accountController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter your withdrawal account',
            hintStyle: TextStyle(color: Colors.grey[600]),
            filled: true,
            fillColor: const Color(0xFF362A5A),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[800]!, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFFF1493), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            suffixIcon: Obx(() {
              if (controller.accountHasText.value) {
                return IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    controller.accountController.clear();
                  },
                );
              }
              return const SizedBox.shrink();
            }),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          validator: controller.validateAccount,
        ),
      ],
    );
  }

  /// 构建金额字段
  Widget _buildAmountField(WithdrawController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Amount',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Obx(
          () => TextFormField(
            controller: controller.amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Withdrawable capital \$${controller.availableBalance.value.toStringAsFixed(1)}',
              hintStyle: TextStyle(color: Colors.grey[600]),
              filled: true,
              fillColor: const Color(0xFF362A5A),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[800]!, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFFF1493), width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 1),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
              suffixIcon: Obx(
                () => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // All 按钮
                    TextButton(
                      onPressed: controller.setAllAmount,
                      child: const Text(
                        'All',
                        style: TextStyle(color: Color(0xFFFF1493), fontWeight: FontWeight.bold),
                      ),
                    ),
                    // 清除按钮
                    if (controller.amountHasText.value)
                      IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          controller.amountController.clear();
                        },
                      ),
                  ],
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            validator: controller.validateAmount,
          ),
        ),
      ],
    );
  }

  /// 构建提现说明（最低金额与手续费比例从配置 ANCHOR_WITHDRAWAL_MIN_MONEY、ANCHOR_WITHDRAWAL_COMMISSION 读取）
  Widget _buildWithdrawalInstructions() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Obx(() {
        final config = Get.find<AppConfigService>();
        final minMoney = config.anchorWithdrawalMinMoney;
        final commissionRaw = config.anchorWithdrawalCommission;
        final minMoneyDisplay = minMoney.startsWith(r'$') ? minMoney : '\$$minMoney';
        // 后台配置为小数（如 0.04），展示为百分比（4%）
        final commissionNum = double.tryParse(commissionRaw) ?? 0.0;
        final pct = commissionNum * 100;
        final pctStr = pct == pct.roundToDouble() ? '${pct.toInt()}' : pct.toStringAsFixed(1);
        final commissionDisplay = '$pctStr%';
        return RichText(
          text: TextSpan(
            style: TextStyle(color: Colors.grey[400], fontSize: 14, height: 1.5),
            children: [
              const TextSpan(text: 'The withdrawal amount cannot be less than '),
              TextSpan(
                text: minMoneyDisplay,
                style: const TextStyle(color: Color(0xFFFF1493), fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const TextSpan(text: ' and can only be withdrawn in whole amounts; '),
              const TextSpan(text: 'the third-party service platform will charge a '),
              TextSpan(
                text: commissionDisplay,
                style: const TextStyle(color: Color(0xFFFF1493), fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const TextSpan(text: ' handling fee for each withdrawal.'),
            ],
          ),
        );
      }),
    );
  }

  /// 构建提现按钮
  Widget _buildWithdrawButton(WithdrawController controller) {
    return Obx(
      () => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF1493), Color(0xFF9C27B0)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: controller.isLoading ? null : controller.submitWithdrawal,
            borderRadius: BorderRadius.circular(30),
            child: Center(
              child: controller.isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Withdraw',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
