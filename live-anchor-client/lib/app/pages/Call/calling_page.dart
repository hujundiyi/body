import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tencent_cloud_chat_sdk/enum/message_elem_type.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_message.dart';
import 'package:tencent_rtc_sdk/trtc_cloud_def.dart';
import 'package:tencent_rtc_sdk/trtc_cloud_video_view.dart';
import 'package:weeder/app/controllers/call_controller.dart';
import 'package:weeder/core/constants/call_constants.dart';
import 'package:weeder/core/services/trtc_service.dart';
import 'package:weeder/core/utils/toast_utils.dart';

import '../../../core/services/translation_service.dart';

/// 通话中页面
/// 参照 H5 SDK calling.vue 实现
class CallingPage extends StatefulWidget {
  const CallingPage({super.key});

  @override
  State<CallingPage> createState() => _CallingPageState();
}

class _CallingPageState extends State<CallingPage> {
  late CallController controller;
  final _translationService = Get.find<TranslationService>();
  @override
  void initState() {
    super.initState();
    // 在页面内部初始化 controller
    controller = Get.put(CallController());
  }

  @override
  void dispose() {
    // 页面销毁时删除 controller
    Get.delete<CallController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        // 安卓系统返回键：先结束通话（退出 TRTC、上报状态），再由 endCall 内部跳转到结束页
        controller.endCall();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Obx(() {
          return Stack(
            fit: StackFit.expand,
            children: [
              // 全屏视频（根据切换状态显示远端或本地）
              _buildFullScreenVideo(),
              // 默认背景（远端视频未就绪时显示）
              if (!controller.isRemoteVideoReady.value && !controller.isVideoSwapped.value)
                _buildDefaultBackground(),
              // 小窗视频（根据切换状态显示本地或远端）
              _buildSmallVideo(),
              // 本地控制面板（摄像头/麦克风未开启时显示）
              _buildLocalControlPanel(),
              // 顶部渐变背景
              _buildTopGradient(),
              // 顶部信息栏
              _buildTopBar(),
              // 底部操作区域
              _buildBottomArea(),
              // 充值提醒闪烁背景
              if (controller.showRechargeReminder.value &&
                  controller.rechargeCountdown.value <= CallConfig.rechargeReminderFlashTime)
                _buildRechargeFlashBackground(),
              // 设置面板遮罩
              if (controller.showSettings.value) _buildSettingsOverlay(),
              // 设置面板
              _buildSettingsPanel(),
            ],
          );
        }),
      ),
    );
  }

  /// 构建全屏视频（固定视图，通过 update 切换显示本地/远端）
  Widget _buildFullScreenVideo() {
    return Positioned.fill(
      child: Stack(
        fit: StackFit.expand,
        children: [
          TRTCCloudVideoView(
            key: const ValueKey('fullscreen'),
            onViewCreated: (viewId) {
              controller.setFullScreenViewId(viewId);
            },
          ),
          // 摄像头关闭时全屏显示本地占位
          Obx(() {
            if (controller.isVideoSwapped.value && !controller.isCameraEnabled) {
              return Container(
                color: Colors.black,
                child: const Center(
                  child: Icon(Icons.videocam_off, color: Colors.white54, size: 60),
                ),
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
    );
  }

  /// 构建默认背景
  Widget _buildDefaultBackground() {
    final avatar = controller.remoteUserInfo?.avatar;
    
    return Positioned.fill(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 背景图片
          if (avatar != null && avatar.isNotEmpty)
            Transform.scale(
              scale: 1.2,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
                child: Image.network(
                  avatar,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: Colors.black),
                ),
              ),
            )
          else
            Container(color: Colors.black),
          // 遮罩
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.18),
                  Colors.black.withValues(alpha: 0.55),
                ],
              ),
            ),
          ),
          // 连接中提示
          Center(
            child: Text(
              'Connecting...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建小窗视频（固定视图，通过 update 切换显示本地/远端）
  Widget _buildSmallVideo() {
    return Positioned(
      right: 12,
      bottom: 120,
      width: 100,
      height: 150,
      child: GestureDetector(
        onTap: () => controller.toggleVideoSwap(),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.8),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                // 背景
                Container(color: Colors.black.withValues(alpha: 0.5)),
                // 固定视频视图
                TRTCCloudVideoView(
                  key: const ValueKey('small'),
                  onViewCreated: (viewId) {
                    controller.setSmallViewId(viewId);
                  },
                ),
                // 摄像头关闭时小窗显示本地占位
                Obx(() {
                  if (!controller.isVideoSwapped.value && !controller.isCameraEnabled) {
                    return Container(
                      color: Colors.black54,
                      child: const Center(
                        child: Icon(Icons.videocam_off, color: Colors.white54, size: 30),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                }),
                // 小窗顶部 切换按钮
                Positioned(
                  right: 0,
                  top: 0,
                  child: Obx(() {
                    if (!controller.isInitialized.value) return const SizedBox.shrink();
                    return Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(
                          Icons.swap_horiz,
                          color: Colors.white,
                          size: 16,
                        ),
                      );
                  }),
                ),
                // 通话计时器 - 小窗底部 & 切换图标
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 6,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Obx(() {
                        if (!controller.isInitialized.value) return const SizedBox.shrink();
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius:  BorderRadius.circular(6),
                          ),
                          child: Text(
                            controller.formattedCallDuration,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'monospace',
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建本地控制面板
  Widget _buildLocalControlPanel() {
    return Obx(() {
      if (controller.isCameraEnabled && controller.isMicrophoneEnabled) {
        return const SizedBox.shrink();
      }

      return Positioned(
        right: 0,
        bottom: 100,
        width: 100,
        height: 150,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 摄像头按钮
            if (!controller.isCameraEnabled)
              _buildControlButton(
                icon: Icons.videocam_off,
                onTap: controller.toggleCamera,
              ),
            if (!controller.isCameraEnabled && !controller.isMicrophoneEnabled)
              const SizedBox(height: 12),
            // 麦克风按钮
            if (!controller.isMicrophoneEnabled)
              _buildControlButton(
                icon: Icons.mic_off,
                onTap: controller.toggleMicrophone,
              ),
            // 通话计时器
            // if (controller.callStartTime > 0)
            //   Padding(
            //     padding: const EdgeInsets.only(top: 12),
            //     child: Container(
            //       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            //       decoration: BoxDecoration(
            //         color: Colors.black.withValues(alpha: 0.5),
            //         borderRadius: BorderRadius.circular(12),
            //       ),
            //       child: Text(
            //         controller.formattedCallDuration,
            //         style: const TextStyle(
            //           color: Colors.white,
            //           fontSize: 14,
            //           fontWeight: FontWeight.w500,
            //         ),
            //       ),
            //     ),
            //   ),
          ],
        ),
      );
    });
  }

  /// 构建控制按钮
  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.3),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  /// 构建顶部渐变背景
  Widget _buildTopGradient() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: 249,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.6),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }

  /// 构建顶部信息栏
  Widget _buildTopBar() {
    final userInfo = controller.remoteUserInfo;
    final callData = controller.callData;

    return Positioned(
      top: 0,
      left: 12,
      right: 12,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              // 关闭按钮
              Obx(() => GestureDetector(
                onTap: controller.isHangupDisabled.value ? null : controller.onHangupClick,
                child: Opacity(
                  opacity: controller.isHangupDisabled.value ? 0.4 : 1.0,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 20),
                  ),
                ),
              )),
              const SizedBox(width: 10),
              // 头像
              ClipOval(
                child: SizedBox(
                  width: 38,
                  height: 38,
                  child: userInfo?.avatar != null
                      ? Image.network(
                          userInfo!.avatar!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey,
                            child: const Icon(Icons.person, color: Colors.white),
                          ),
                        )
                      : Container(
                          color: Colors.grey,
                          child: const Icon(Icons.person, color: Colors.white),
                        ),
                ),
              ),
              const SizedBox(width: 10),
              // 昵称和价格
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userInfo?.nickname ?? 'Unknown',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Image.asset('asset/images/common/coin.png', width: 14, height: 14, fit: BoxFit.contain),
                        const SizedBox(width: 6),
                        Text(
                          '${callData?.callPrice ?? 0}/min',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.95),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // 关注按钮
              Obx(() => GestureDetector(
                onTap: () => controller.toggleFollow(),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    controller.isFollowing ? Icons.favorite : Icons.favorite_border,
                    color: controller.isFollowing ? Colors.red : Colors.white,
                    size: 20,
                  ),
                ),
              )),

            ],
          ),
        ),
      ),
    );
  }

  /// 构建底部操作区域
  Widget _buildBottomArea() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 充值提醒
            Obx(() => controller.showRechargeReminder.value
                ? _buildRechargeReminder()
                : const SizedBox.shrink()),
            // 聊天区域
            _buildChatArea(),
            // 聊天输入框
            _buildChatInput(),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  /// 构建聊天区域
  Widget _buildChatArea() {
    return Container(
      height: 160,
      margin: const EdgeInsets.only(right: 120), // 避开右边的本地视频窗口
      child: Obx(() {
        if (controller.messageList.isEmpty) {
          return const SizedBox.shrink();
        }

        return ListView.builder(
          controller: controller.chatScrollController,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: controller.messageList.length,
          itemBuilder: (context, index) {
            final message = controller.messageList[index];
            return _buildMessageItem(message);
          },
        );
      }),
    );
  }

  /// 是否为自定义消息
  bool _isCustomMessage(V2TimMessage message) {
    return message.elemType == MessageElemType.V2TIM_ELEM_TYPE_CUSTOM;
  }

  /// 是否为礼物消息（customType === 2000）
  bool _isGiftMessage(V2TimMessage message) {
    final customElem = message.customElem;
    if (customElem == null || customElem.data == null || customElem.data!.isEmpty) {
      return false;
    }
    try {
      final customData = json.decode(customElem.data!) as Map<String, dynamic>?;
      if (customData == null) return false;
      final customType = customData['customType'] ?? customData['type'];
      if (customType == null) return false;
      return customType == CallMessageType.gift;
    } catch (_) {
      return false;
    }
  }

  /// 构建礼物消息项
  Widget _buildGiftMessageItem(V2TimMessage message) {
    final isSelf = message.isSelf ?? false;
    final customElem = message.customElem;
    if (customElem == null || customElem.data == null || customElem.data!.isEmpty) {
      return const SizedBox.shrink();
    }
    try {
      final customData = json.decode(customElem.data!) as Map<String, dynamic>?;
      if (customData == null) return const SizedBox.shrink();
      final content = customData['content'] as Map<String, dynamic>?;
      final name = content?['name'] ?? customData['name'] ?? '';
      final coin = content?['coin'] ?? customData['coin'] ?? 0;
      final giftNum = content?['giftNum'] ?? customData['giftNum'] ?? 1;
      final displayText = '$name [${coin is num ? coin.toInt() : coin} coins] x ${giftNum is num ? giftNum.toInt() : giftNum}';

      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: Container(
                constraints: BoxConstraints(maxWidth: Get.width * 0.6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.card_giftcard,
                      color: isSelf ? const Color(0xFFFFDB0D) : Colors.orange,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        displayText,
                        style: TextStyle(
                          color: isSelf ? const Color(0xFFFFDB0D) : Colors.white.withValues(alpha: 0.95),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    } catch (_) {
      return const SizedBox.shrink();
    }
  }

  /// 构建消息项
  Widget _buildMessageItem(dynamic message) {
    final msg = message as V2TimMessage;
    final isSelf = msg.isSelf ?? false;
    final text = msg.textElem?.text ?? '';
    final msgId = msg.msgID ?? '';

    // 自定义消息：礼物消息单独展示
    if (_isCustomMessage(msg)) {
      if (_isGiftMessage(msg)) {
        return _buildGiftMessageItem(msg);
      }
      return const SizedBox.shrink();
    }

    if (text.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start, // 所有消息靠左
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 消息气泡
                Container(
                  constraints: BoxConstraints(maxWidth: Get.width * 0.6),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    text,
                    style: TextStyle(
                      color: isSelf ? const Color(0xFFFFDB0D) : Colors.white.withValues(alpha: 0.95),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                // 翻译内容（如果有）
                if (!isSelf)
                  _transWidget(message)
              ],
            ),
          ),
          // 翻译按钮（仅对方消息显示）
          if (!isSelf)
            Obx(() {
              final isTranslating = controller.isTranslating(msgId);
              final translatedText = _translationService.getTranslatedText(message);
              
              // 已翻译则不显示按钮
              if (!(translatedText == null || translatedText.isEmpty)) {
                return const SizedBox.shrink();
              }
              
              return GestureDetector(
                onTap: isTranslating ? null : () => controller.translateMessage(message),
                child: Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: isTranslating
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.translate,
                          color: Colors.white,
                          size: 14,
                        ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _transWidget(V2TimMessage message) {
    final translatedText = _translationService.getTranslatedText(message);
      if (translatedText != null && translatedText.isNotEmpty) {
        return Container(
          margin: const EdgeInsets.only(top: 4),
          constraints: BoxConstraints(maxWidth: Get.width * 0.6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            translatedText,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        );
      }
      return const SizedBox.shrink();
  }

  /// 构建聊天输入框
  Widget _buildChatInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // 输入框
          Expanded(
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.65),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: controller.textController,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                ),
                decoration: InputDecoration(
                  hintText: 'Say hi...',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 15,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => controller.sendTextMessage(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // 更多操作按钮
          GestureDetector(
            onTap: controller.toggleSettings,
            child: Container(
              width: 37,
              height: 37,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.more_horiz, color: Colors.white, size: 22),
            ),
          ),
          const SizedBox(width: 8),
          // 礼物按钮

        ],
      ),
    );
  }

  /// 构建充值提醒
  Widget _buildRechargeReminder() {
    return Obx(() => GestureDetector(
      onTap: controller.onRechargeReminderClick,
      child: Container(
        height: controller.rechargeReminderExpanded.value ? 50 : 36,
        margin: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF6B35), Color(0xFFFF8C5A)],
          ),
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(25),
            bottomRight: Radius.circular(25),
          ),
        ),
        child: controller.rechargeReminderExpanded.value
            ? _buildExpandedRechargeContent()
            : _buildCollapsedRechargeContent(),
      ),
    ));
  }

  /// 展开状态的充值提醒内容
  Widget _buildExpandedRechargeContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.access_time, color: Colors.white, size: 24),
          const SizedBox(width: 8),
          const Text(
            'Out of Time',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Obx(() => Text(
            controller.formattedRechargeCountdown,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFamily: 'monospace',
            ),
          )),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              // TODO: 跳转充值页面
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Recharge',
                style: TextStyle(
                  color: Color(0xFFFF6B35),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 收起状态的充值提醒内容
  Widget _buildCollapsedRechargeContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Obx(() => Text(
            controller.formattedRechargeCountdown,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              fontFamily: 'monospace',
            ),
          )),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right, color: Colors.white, size: 12),
        ],
      ),
    );
  }

  /// 构建充值闪烁背景
  Widget _buildRechargeFlashBackground() {
    return Positioned.fill(
      child: IgnorePointer(
        child: _FlashingBackground(),
      ),
    );
  }

  /// 构建设置面板遮罩
  Widget _buildSettingsOverlay() {
    return Positioned.fill(
      child: GestureDetector(
        onTap: controller.closeSettings,
        child: Container(color: Colors.black.withValues(alpha: 0.5)),
      ),
    );
  }

  /// 构建设置面板
  Widget _buildSettingsPanel() {
    return Obx(() => AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      left: 0,
      right: 0,
      bottom: controller.showSettings.value ? 0 : -200,
      child: Container(
        padding: EdgeInsets.only(
          top: 24,
          bottom: MediaQuery.of(Get.context!).padding.bottom + 32,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // 美颜按钮（在 Camera 左边）
            _buildSettingItem(
              icon: Icons.face_retouching_natural,
              label: 'Beauty',
              isEnabled: true,
              onTap: _showBeautyPanel,
            ),
            // 摄像头开关
            Obx(() => _buildSettingItem(
              icon: controller.isCameraEnabled ? Icons.videocam : Icons.videocam_off,
              label: 'Camera',
              isEnabled: controller.isCameraEnabled,
              onTap: controller.toggleCamera,
            )),
            // 麦克风开关
            Obx(() => _buildSettingItem(
              icon: controller.isMicrophoneEnabled ? Icons.mic : Icons.mic_off,
              label: 'Mic',
              isEnabled: controller.isMicrophoneEnabled,
              onTap: controller.toggleMicrophone,
            )),
            // 切换摄像头
            _buildSettingItem(
              icon: Icons.cameraswitch,
              label: 'Switch',
              isEnabled: true,
              onTap: controller.switchCamera,
            ),
          ],
        ),
      ),
    ));
  }

  /// 弹出美颜设置面板
  void _showBeautyPanel() {
    final trtc = Get.find<TRTCService>();
    bool enabled = trtc.isBeautyEnabled;
    double beautyLevel = trtc.beautyLevel.toDouble();
    double whitenessLevel = trtc.whitenessLevel.toDouble();
    double ruddinessLevel = trtc.ruddinessLevel.toDouble();

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  top: 20,
                  bottom: MediaQuery.of(ctx).padding.bottom + 24,
                  left: 20,
                  right: 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Beauty',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Switch(
                          value: enabled,
                          onChanged: (v) {
                            setModalState(() => enabled = v);
                            trtc.setBeautyEnabled(v);
                          },
                          activeColor: const Color(0xFFFFDB0D),
                        ),
                      ],
                    ),
                    if (enabled) ...[
                      const SizedBox(height: 16),
                      _buildBeautySlider(
                        label: 'Smooth',
                        value: beautyLevel,
                        onChanged: (v) {
                          setModalState(() => beautyLevel = v);
                          trtc.setBeautyStyle(
                            TRTCBeautyStyle.smooth,
                            beautyLevel: v.toInt(),
                            whitenessLevel: whitenessLevel.toInt(),
                            ruddinessLevel: ruddinessLevel.toInt(),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildBeautySlider(
                        label: 'Whiten',
                        value: whitenessLevel,
                        onChanged: (v) {
                          setModalState(() => whitenessLevel = v);
                          trtc.setBeautyStyle(
                            TRTCBeautyStyle.smooth,
                            beautyLevel: beautyLevel.toInt(),
                            whitenessLevel: v.toInt(),
                            ruddinessLevel: ruddinessLevel.toInt(),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildBeautySlider(
                        label: 'Ruddy',
                        value: ruddinessLevel,
                        onChanged: (v) {
                          setModalState(() => ruddinessLevel = v);
                          trtc.setBeautyStyle(
                            TRTCBeautyStyle.smooth,
                            beautyLevel: beautyLevel.toInt(),
                            whitenessLevel: whitenessLevel.toInt(),
                            ruddinessLevel: v.toInt(),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBeautySlider({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 14,
              ),
            ),
            Text(
              value.toInt().toString(),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 13,
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: 0,
          max: 9,
          divisions: 9,
          activeColor: const Color(0xFFFFDB0D),
          onChanged: onChanged,
        ),
      ],
    );
  }

  /// 构建设置项
  Widget _buildSettingItem({
    required IconData icon,
    required String label,
    required bool isEnabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isEnabled ? Colors.white.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isEnabled ? Colors.white : Colors.white54,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// 闪烁背景动画
class _FlashingBackground extends StatefulWidget {
  @override
  State<_FlashingBackground> createState() => _FlashingBackgroundState();
}

class _FlashingBackgroundState extends State<_FlashingBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [
                Colors.red.withValues(alpha: 0.3 + 0.5 * _controller.value),
                Colors.transparent,
              ],
            ),
          ),
        );
      },
    );
  }
}
