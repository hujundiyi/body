import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/base/base_controller.dart';
import '../../core/network/anchor_api_service.dart';
import '../../core/services/auth_service.dart';
import '../../data/models/commission_model.dart';
import '../../data/models/dict_model.dart';

/// 提现控制器
class WithdrawController extends BaseController {
  // 表单控制器
  final formKey = GlobalKey<FormState>();
  final payeeNameController = TextEditingController();
  final accountController = TextEditingController();
  final amountController = TextEditingController();
  
  // 选中的支付方式（value值）
  final Rx<int?> selectedPayType = Rx<int?>(null);
  
  // 支付方式列表（从接口获取）
  final RxList<DictItem> payMethods = <DictItem>[].obs;
  
  // 可用余额（从工作台获取）
  final RxDouble availableBalance = 0.0.obs;
  
  // 实际到账金额信息
  final Rx<ActualAmountReceived?> actualAmount = Rx<ActualAmountReceived?>(null);
  
  // 输入框文本状态（用于清除按钮显示）
  final RxBool payeeNameHasText = false.obs;
  final RxBool accountHasText = false.obs;
  final RxBool amountHasText = false.obs;

  @override
  void onControllerInit() {
    super.onControllerInit();
    _loadAvailableBalance();
    _setupTextListeners();
    _loadPayMethods();
  }

  @override
  void onControllerClose() {
    payeeNameController.removeListener(_onPayeeNameChanged);
    accountController.removeListener(_onAccountChanged);
    amountController.removeListener(_onAmountChanged);
    payeeNameController.dispose();
    accountController.dispose();
    amountController.dispose();
    super.onControllerClose();
  }

  /// 设置文本监听器
  void _setupTextListeners() {
    payeeNameController.addListener(_onPayeeNameChanged);
    accountController.addListener(_onAccountChanged);
    amountController.addListener(_onAmountChanged);
  }

  /// 收款人姓名变化监听
  void _onPayeeNameChanged() {
    payeeNameHasText.value = payeeNameController.text.isNotEmpty;
  }

  /// 账号变化监听
  void _onAccountChanged() {
    accountHasText.value = accountController.text.isNotEmpty;
  }

  /// 金额变化监听
  void _onAmountChanged() {
    amountHasText.value = amountController.text.isNotEmpty;
    onAmountChanged(amountController.text);
  }

  /// 加载可用余额
  void _loadAvailableBalance() {
    try {
      final authService = Get.find<AuthService>();
      final anchorInfo = authService.userInfo;
      if (anchorInfo != null) {
        availableBalance.value = anchorInfo.availableBalance ?? 0.0;
        // 设置金额输入框的提示文本
        amountController.text = '';
      }
    } catch (e) {
      debugPrint('Failed to load available balance: $e');
    }
  }

  /// 加载支付方式列表
  Future<void> _loadPayMethods() async {
    try {
      final dictList = await AnchorAPIService.shared.getDict(['withdrawal_pay_type']);
      
      for (final dict in dictList) {
        if (dict.dictType == 'withdrawal_pay_type') {
          payMethods.assignAll(dict.dictItems);
          // 默认选择第一个支付方式
          if (payMethods.isNotEmpty && selectedPayType.value == null) {
            selectedPayType.value = payMethods[0].value;
          }
          break;
        }
      }
    } catch (e) {
      debugPrint('Failed to load pay methods: $e');
      showErrorUnlessAuth(e, 'Failed to load payment methods');
    }
  }

  /// 选择支付方式
  void selectPayType(int payTypeValue) {
    selectedPayType.value = payTypeValue;
    // 清除之前的实际到账金额
    actualAmount.value = null;
    // 如果金额已输入，重新计算实际到账金额
    if (amountController.text.isNotEmpty) {
      _calculateActualAmount();
    }
  }

  /// 设置全部金额
  void setAllAmount() {
    amountController.text = availableBalance.value.toStringAsFixed(2);
    _calculateActualAmount();
  }

  /// 计算实际到账金额
  Future<void> _calculateActualAmount() async {
    final amountText = amountController.text.trim();
    if (amountText.isEmpty) {
      actualAmount.value = null;
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      actualAmount.value = null;
      return;
    }

    if (selectedPayType.value == null) {
      return;
    }

    try {
      final result = await AnchorAPIService.shared.getActualAmountReceived(
        payType: selectedPayType.value!,
        money: amount,
      );
      actualAmount.value = result;
    } catch (e) {
      debugPrint('Failed to calculate actual amount: $e');
      actualAmount.value = null;
    }
  }

  /// 金额输入变化监听
  void onAmountChanged(String value) {
    _calculateActualAmount();
  }

  /// 验证收款人姓名
  String? validatePayeeName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your true name';
    }
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  /// 验证账号
  String? validateAccount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your withdrawal account';
    }
    return null;
  }

  /// 验证金额
  String? validateAmount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter withdrawal amount';
    }
    final amount = double.tryParse(value);
    if (amount == null || amount <= 0) {
      return 'Please enter a valid amount';
    }
    if (amount < 20) {
      return 'Minimum withdrawal amount is \$20';
    }
    if (amount > availableBalance.value) {
      return 'Amount cannot exceed available balance';
    }
    // 检查是否为整数
    if (amount != amount.roundToDouble()) {
      return 'Amount must be a whole number';
    }
    return null;
  }

  /// 提交提现申请
  Future<void> submitWithdrawal() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    if (selectedPayType.value == null) {
      showError('Please select a payment method');
      return;
    }

    final amount = double.tryParse(amountController.text.trim());
    if (amount == null || amount < 20) {
      showError('Minimum withdrawal amount is \$20');
      return;
    }

    await executeWithLoading(() async {
      try {
        final request = WithdrawalRequest(
          payType: selectedPayType.value!,
          money: amount,
          payUsername: payeeNameController.text.trim(),
          payAccount: accountController.text.trim(),
        );

        await AnchorAPIService.shared.withdrawal(request);
        
        showSuccess('Withdrawal request submitted successfully');
        
        // 返回上一页
        Get.back();
      } catch (e) {
        debugPrint('Failed to submit withdrawal: $e');
        showErrorUnlessAuth(e, 'Failed to submit withdrawal request');
      }
    });
  }
}
