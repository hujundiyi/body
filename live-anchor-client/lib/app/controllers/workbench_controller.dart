import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/base/base_controller.dart';
import '../../core/network/anchor_api_service.dart';
import '../../core/services/storage_service.dart';
import '../../data/models/anchor_model.dart';
import '../../routes/app_routes.dart';

/// 工作台控制器
class WorkbenchController extends BaseController {
  // 主播信息
  final Rx<AnchorModel?> anchorInfo = Rx<AnchorModel?>(null);
  
  // 存储服务
  final StorageService _storage = Get.find<StorageService>();
  
  // 存储键：是否已显示过工作台提示
  static const String _hasShownWorkbenchTipKey = 'has_shown_workbench_tip';

  @override
  void onControllerInit() {
    super.onControllerInit();
    loadAnchorInfo();
  }

  @override
  void onControllerReady() {
    super.onControllerReady();
    // 页面渲染完成后检查是否需要显示提示弹窗
    _checkAndShowTip();
  }

  /// 加载主播信息
  Future<void> loadAnchorInfo({bool useMockData = false}) async {
    await executeWithLoading(() async {
      try {
        AnchorModel anchor;
        
        if (useMockData) {
          // 使用假数据
          anchor = _getMockAnchorInfo();
        } else {
          // 调用真实接口
          anchor = await AnchorAPIService.shared.getAnchorInfo();
        }
        
        anchorInfo.value = anchor;
      } catch (e) {
        debugPrint('Failed to load anchor info: $e');
        // 如果接口失败，使用假数据作为降级方案
        if (!useMockData) {
          debugPrint('Using mock data as fallback');
          anchorInfo.value = _getMockAnchorInfo();
        } else {
          showErrorUnlessAuth(e, 'Failed to load anchor info');
        }
      }
    });
  }

  /// 获取假数据（用于测试和开发）
  AnchorModel _getMockAnchorInfo() {
    return AnchorModel(
      userId: 0,
      walletBalance: 0.0,
      availableBalance: 0.0,
      freezeMoney: 0.0,
      nickname: '',
      avatar: null,
    );
  }

  /// 刷新数据
  @override
  Future<void> refresh() async {
    await loadAnchorInfo();
  }

  /// 获取总收入（钱包余额）
  double get totalIncome => anchorInfo.value?.walletBalance ?? 0.0;

  /// 获取可用余额
  double get availableBalance => anchorInfo.value?.availableBalance ?? 0.0;

  /// 获取待处理余额（总收入 - 可用余额）
  double get pendingBalance => totalIncome - availableBalance;

  /// 检查并显示提示弹窗（仅第一次进入时显示）
  void _checkAndShowTip() {
    // 检查是否已经显示过
    final hasShown = _storage.getBool(_hasShownWorkbenchTipKey) ?? false;
    if (!hasShown) {
      // 延迟一下确保页面完全渲染
      Future.delayed(const Duration(milliseconds: 300), () {
        _showWorkbenchTipDialog();
      });
    }
  }

  /// 显示工作台提示弹窗
  void _showWorkbenchTipDialog() {
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
              // 警告图标（两个感叹号）
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // 背景圆形
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.orange.withOpacity(0.2),
                      ),
                    ),
                    // 感叹号文字
                    const Text(
                      '!!',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                        height: 1.0,
                        shadows: [
                          Shadow(
                            color: Colors.white,
                            blurRadius: 4,
                            offset: Offset(0, 0),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // 提示文本
              const Text(
                'Make sure the APP stays OPEN while working please.If you put app in the background, you won\'t be able to receive call invitations from users, which will impact your income',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // OK 按钮
              GestureDetector(
                onTap: () {
                  // 标记为已显示
                  _storage.setBool(_hasShownWorkbenchTipKey, true);
                  Get.back();
                },
                child: Container(
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
                  child: const Text(
                    'OK',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false, // 不允许点击外部关闭
    );
  }

  /// 显示提现提示弹窗
  void showWithdrawTipDialog() {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF332244),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 标题
              const Text(
                'Tips',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 20),
              
              // 内容文本
              const Text(
                'Every Monday can withdraw. Each withdrawal can only apply for the available commission; and at least\$20 is required for each withdrawal.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // OK 按钮
              GestureDetector(
                onTap: () {
                  Get.back();
                  // 跳转到提现页面
                  Get.toNamed(AppRoutes.withdraw);
                },
                child: Container(
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
                  child: const Text(
                    'OK',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: true, // 允许点击外部关闭
    );
  }

  /// 显示关于收入的说明弹窗
  void showAboutIncomeDialog() {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF332244),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 标题
              const Text(
                'About income',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 20),
              
              // 内容文本
              const Text(
                'The income component is divided into twoparts: available and pending. Available can be withdrawn, and pending can be withdrawn on the next withdrawal date.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // OK 按钮
              GestureDetector(
                onTap: () {
                  Get.back();
                },
                child: Container(
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
                  child: const Text(
                    'OK',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: true, // 允许点击外部关闭
    );
  }
}
