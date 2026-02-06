import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:weeder/app/controllers/call_controller.dart';
import 'package:weeder/core/utils/toast_utils.dart';
import 'package:weeder/routes/app_routes.dart';

/// 通话结束页面
class CallEndPage extends StatefulWidget {
  const CallEndPage({super.key});

  @override
  State<CallEndPage> createState() => _CallEndPageState();
}

class _CallEndPageState extends State<CallEndPage> {
  late CallEndController controller;

  @override
  void initState() {
    super.initState();
    // 在页面内部初始化 controller
    controller = Get.put(CallEndController());
  }

  @override
  void dispose() {
    // 页面销毁时删除 controller
    Get.delete<CallEndController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Obx(() {
        // 监听 endCallData 变化
        final _ = controller.endCallDataRx.value;
        return Column(
          children: [
            // 顶部红色区域 + 头像
            _buildTopSection(),
            // 内容区域
            Expanded(
              child: _buildContentSection(),
            ),
            // 底部按钮
            _buildBottomButton(),
          ],
        );
      }),
    );
  }

  /// 构建顶部红色区域
  Widget _buildTopSection() {
    final avatar = controller.remoteUserInfo?.avatar ?? '';
    
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        // 红色渐变背景
        Container(
          height: 220,
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFF6B6B),
                Color(0xFFFF8E8E),
              ],
            ),
          ),
          child: SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                onPressed: () => Get.back(),
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
              ),
            ),
          ),
        ),
        // 头像（突出到白色区域）
        Positioned(
          bottom: -50,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipOval(
              child: avatar.isNotEmpty
                  ? Image.network(
                      avatar,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.person, size: 50, color: Colors.grey),
                      ),
                    )
                  : Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.person, size: 50, color: Colors.grey),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  /// 构建内容区域
  Widget _buildContentSection() {
    final endData = controller.endCallData;
    final callNo = controller.callData?.callNo ?? '';
    
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 70, 24, 24),
      child: Column(
        children: [
          // Duration
          _buildInfoRow(
            label: 'Duration:',
            value: endData?.formattedDuration ?? '00:00:00',
          ),
          const Divider(height: 32),
          
          // Call Income
          _buildInfoRow(
            label: 'Call Income',
            valueWidget: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${endData?.spendCoin?.toStringAsFixed(0) ?? 0}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 4),
                _buildCoinIcon(),
              ],
            ),
          ),
          const Divider(height: 32),
          
          // Gift Income
          // _buildInfoRow(
          //   label: 'Gift Income',
          //   valueWidget: GestureDetector(
          //     onTap: _onGiftIncomePressed,
          //     child: Row(
          //       mainAxisSize: MainAxisSize.min,
          //       children: [
          //         Text(
          //           'Go message get',
          //           style: TextStyle(
          //             fontSize: 16,
          //             fontWeight: FontWeight.w500,
          //             color: Colors.blue[400],
          //           ),
          //         ),
          //         Icon(Icons.chevron_right, color: Colors.blue[400], size: 20),
          //       ],
          //     ),
          //   ),
          // ),
          // const Divider(height: 32),
          
          // // Program Income
          // _buildInfoRow(
          //   label: 'Program Income',
          //   valueWidget: Row(
          //     mainAxisSize: MainAxisSize.min,
          //     children: [
          //       const Text(
          //         '0',
          //         style: TextStyle(
          //           fontSize: 16,
          //           fontWeight: FontWeight.w500,
          //           color: Colors.black87,
          //         ),
          //       ),
          //       const SizedBox(width: 4),
          //       _buildCoinIcon(),
          //     ],
          //   ),
          // ),
          // const Divider(height: 32),
          
          // Call ID
          _buildInfoRow(
            label: 'Call ID:',
            valueWidget: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    callNo,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _copyCallId(callNo),
                  child: Icon(Icons.copy, size: 18, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建信息行
  Widget _buildInfoRow({
    required String label,
    String? value,
    Widget? valueWidget,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Colors.black87,
            ),
          ),
          if (valueWidget != null)
            Flexible(child: valueWidget)
          else if (value != null)
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
        ],
      ),
    );
  }

  /// 构建金币图标
  Widget _buildCoinIcon() {
    return Image.asset(
      'asset/images/common/coin.png',
      width: 20,
      height: 20,
      fit: BoxFit.contain,
    );
  }

  /// 构建底部按钮
  Widget _buildBottomButton() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: controller.closePage,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B6B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Confirm',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 点击礼物收入 - 跳转到与对方的聊天界面
  void _onGiftIncomePressed() {
    final user = controller.remoteUserInfo;
    if (user == null || user.userId <= 0) {
      return;
    }
    Get.toNamed(
      AppRoutes.messageChat,
      arguments: {
        'conversationID': 'c2c_${user.userId}',
        'userID': '${user.userId}',
        'groupID': null,
        'name': user.nickname,
        'avatar': user.avatar,
      },
    );
  }

  /// 复制通话ID
  void _copyCallId(String callId) {
    if (callId.isEmpty) return;
    Clipboard.setData(ClipboardData(text: callId));
    ToastUtils.showSuccess('Call ID copied');
  }
}
