import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';

import '../../app/widgets/avatar_network_image.dart';

/// 统一的提示工具类
/// 使用 Fluttertoast 管理所有 Toast 提示
class ToastUtils {
  ToastUtils._();

  static String _messageWithTitle(String title, String message) {
    if (title.isEmpty) return message;
    return '$title: $message';
  }

  /// 显示成功提示
  static void showSuccess(String message, {String title = 'Success'}) {
    Fluttertoast.showToast(
      msg: _messageWithTitle(title, message),
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.TOP,
      backgroundColor: const Color(0xFF4CAF50),
      textColor: Colors.white,
      fontSize: 14.0,
      timeInSecForIosWeb: 2,
    );
  }

  /// 显示错误提示
  static void showError(String message, {String title = 'Error'}) {
    Fluttertoast.showToast(
      msg: _messageWithTitle(title, message),
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.TOP,
      backgroundColor: const Color(0xFFE53935),
      textColor: Colors.white,
      fontSize: 14.0,
      timeInSecForIosWeb: 3,
    );
  }

  /// 显示警告提示
  static void showWarning(String message, {String title = 'Warning'}) {
    Fluttertoast.showToast(
      msg: _messageWithTitle(title, message),
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.TOP,
      backgroundColor: const Color(0xFFFF9800),
      textColor: Colors.white,
      fontSize: 14.0,
      timeInSecForIosWeb: 2,
    );
  }

  /// 显示信息提示
  static void showInfo(String message, {String title = 'Tips'}) {
    Fluttertoast.showToast(
      msg: _messageWithTitle(title, message),
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.TOP,
      backgroundColor: const Color(0xFF2196F3),
      textColor: Colors.white,
      fontSize: 14.0,
      timeInSecForIosWeb: 2,
    );
  }

  /// 显示普通提示（深色背景）
  static void showToast(String message, {String? title}) {
    Fluttertoast.showToast(
      msg: title != null && title.isNotEmpty ? '$title: $message' : message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.TOP,
      backgroundColor: const Color(0xFF333333),
      textColor: Colors.white,
      fontSize: 14.0,
      timeInSecForIosWeb: 2,
    );
  }

  /// 显示通知提示（粉色主题）
  static void showNotice(String message, {String title = 'Notice'}) {
    Fluttertoast.showToast(
      msg: _messageWithTitle(title, message),
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.TOP,
      backgroundColor: const Color(0xFFFF1493),
      textColor: Colors.white,
      fontSize: 14.0,
      timeInSecForIosWeb: 2,
    );
  }

  /// 由 main 在首帧后用 Navigator 的 overlay 注入，保证应用内弹窗能插入到正确层级
  static OverlayState? _overlayState;

  /// 通过 BuildContext 注入（需在已有 Overlay 的子树下调用）
  static void attachOverlay(BuildContext context) {
    try {
      _overlayState = Overlay.of(context);
    } catch (_) {}
  }

  /// 直接注入 OverlayState（用于 main 首帧后从 Get.key.currentState?.overlay 注入）
  static void attachOverlayState(OverlayState? state) {
    if (state != null) _overlayState = state;
  }

  static OverlayEntry? _inAppMessageOverlay;

  /// 显示应用内自定义弹窗：头像、昵称、内容，顶部悬浮，约 2 秒后自动消失，可点击。
  /// 若有 avatarUrl 使用 Image.network（AvatarNetworkImage）展示，依赖 Flutter 网络图缓存，已缓存的不重复下载。
  static void showInAppMessage({
    required String title,
    required String message,
    String? avatarUrl,
    VoidCallback? onTap,
  }) {
    final overlay = _overlayState ?? Get.key.currentState?.overlay;
    if (overlay == null) {
      Fluttertoast.showToast(
        msg: '$title: $message',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.TOP,
        backgroundColor: const Color(0xFFF5F6FA),
        textColor: const Color(0xFF111827),
        fontSize: 14.0,
        timeInSecForIosWeb: 2,
      );
      return;
    }

    _removeInAppMessageOverlay();
    _inAppMessageOverlay = OverlayEntry(
      builder: (ctx) => _InAppMessageOverlay(
        title: title,
        message: message,
        avatarUrl: avatarUrl,
        onTap: () {
          onTap?.call();
          _removeInAppMessageOverlay();
        },
      ),
    );
    overlay.insert(_inAppMessageOverlay!);
    Future.delayed(const Duration(seconds: 2), _removeInAppMessageOverlay);
  }

  static void _removeInAppMessageOverlay() {
    final entry = _inAppMessageOverlay;
    _inAppMessageOverlay = null;
    if (entry != null) {
      try {
        entry.remove();
      } catch (_) {}
    }
  }

  /// 显示自定义提示
  static void showCustom({
    required String message,
    String? title,
    Color backgroundColor = const Color(0xFF333333),
    Color textColor = Colors.white,
    AlignmentGeometry align = Alignment.topCenter,
    Duration duration = const Duration(seconds: 2),
  }) {
    Fluttertoast.showToast(
      msg: title != null && title.isNotEmpty ? '$title: $message' : message,
      toastLength: duration.inSeconds >= 3 ? Toast.LENGTH_LONG : Toast.LENGTH_SHORT,
      gravity: ToastGravity.TOP,
      backgroundColor: backgroundColor,
      textColor: textColor,
      fontSize: 14.0,
      timeInSecForIosWeb: duration.inSeconds,
    );
  }

  /// 关闭当前显示的 Toast 和应用内消息弹窗
  static void dismiss() {
    Fluttertoast.cancel();
    _removeInAppMessageOverlay();
  }
}

/// 应用内消息自定义弹窗：头像、昵称、内容
class _InAppMessageOverlay extends StatelessWidget {
  final String title;
  final String message;
  final String? avatarUrl;
  final VoidCallback onTap;

  const _InAppMessageOverlay({
    required this.title,
    required this.message,
    this.avatarUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: 12,
      right: 12,
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F6FA),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                _buildAvatar(context),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF111827),
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        message,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF4B5563),
                          fontSize: 13,
                          height: 1.3,
                        ),
                      ),
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

  Widget _buildAvatar(BuildContext context) {
    const size = 40.0;
    const placeholderColor = Color(0xFFE5E7EB);
    const placeholderIconColor = Color(0xFF9CA3AF);
    return AvatarNetworkImage(
      imageUrl: avatarUrl,
      size: size,
      placeholderColor: placeholderColor,
      placeholderIconColor: placeholderIconColor,
    );
  }
}
