import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:weeder/app/controllers/call_controller.dart';
import 'package:weeder/data/models/call_data_model.dart';
import 'package:weeder/data/models/user_model_entity.dart';

/// 来电页面
/// 参照 H5 SDK incoming.vue 实现
class IncomingCallPage extends StatefulWidget {
  const IncomingCallPage({super.key});

  @override
  State<IncomingCallPage> createState() => _IncomingCallPageState();
}

class _IncomingCallPageState extends State<IncomingCallPage> {
  late IncomingCallController controller;

  @override
  void initState() {
    super.initState();
    // 在页面内部初始化 controller
    controller = Get.put(IncomingCallController());
  }

  @override
  void dispose() {
    // 页面销毁时删除 controller
    Get.delete<IncomingCallController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 模糊背景
          _buildBackground(),
          // 内容
          _buildContent(),
        ],
      ),
    );
  }

  /// 构建模糊背景
  Widget _buildBackground() {
    final avatar = controller.remoteUserInfo?.avatar;
    
    return Stack(
      fit: StackFit.expand,
      children: [
        // 背景图片
        if (avatar != null && avatar.isNotEmpty)
          Image.network(
            avatar,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: Colors.black),
          )
        else
          Container(color: Colors.black),
        // 模糊效果
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
          child: Container(
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
        ),
      ],
    );
  }

  /// 构建内容
  Widget _buildContent() {
    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 70),
          // 头像
          _buildAvatar(),
          const Spacer(),
          // 用户信息
          _buildUserInfo(),
          const SizedBox(height: 35),
          // 操作按钮
          _buildActionButtons(),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  /// 构建头像（带水波纹效果）
  Widget _buildAvatar() {
    final avatar = controller.remoteUserInfo?.avatar;
    
    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 水波纹动画
          _RippleAnimation(),
          // 头像
          Container(
            width: 145,
            height: 145,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.92),
                width: 4,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.28),
                  blurRadius: 40,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: ClipOval(
              child: avatar != null && avatar.isNotEmpty
                  ? Image.network(
                      avatar,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey,
                        child: const Icon(Icons.person, size: 60, color: Colors.white),
                      ),
                    )
                  : Container(
                      color: Colors.grey,
                      child: const Icon(Icons.person, size: 60, color: Colors.white),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建用户信息
  Widget _buildUserInfo() {
    final userInfo = controller.remoteUserInfo;
    
    return Column(
      children: [
        // 昵称
        Text(
          userInfo?.nickname ?? 'Unknown',
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 12),
        // 标签
        _buildTags(userInfo),
      ],
    );
  }

  /// 年龄标签：优先 age，否则由 birthday 时间戳计算
  Widget _buildAgeTag(UserModelEntity userInfo) {
    final age = userInfo.age > 0 ? userInfo.age : userInfo.ageFromBirthday;
    if (age == null || age <= 0) return const SizedBox.shrink();
    return _buildTag(
      '$age',
      backgroundColor: userInfo.gender == 1 ? const Color(0xFFFF40A7) : const Color(0xFF4A90D9),
    );
  }

  /// 构建标签
  Widget _buildTags(UserModelEntity? userInfo) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 国旗
        if (userInfo?.country != null && userInfo!.country != 0)
          Padding(
            padding: const EdgeInsets.only(right: 5),
            child: Text(
              _getCountryFlag(userInfo.country.toString()),
              style: const TextStyle(fontSize: 35),
            ),
          ),
        // 年龄标签：优先用 age，否则用 birthday 时间戳计算
        if (userInfo != null)
          _buildAgeTag(userInfo),
      ],
    );
  }

  /// 构建标签组件
  Widget _buildTag(String text, {Color? backgroundColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  /// 构建操作按钮
  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 26),
      child: Row(
        mainAxisAlignment: controller.isIncomingCall
            ? MainAxisAlignment.spaceBetween
            : MainAxisAlignment.center,
        children: [
          // 拒绝/取消按钮
          _buildActionButton(
            onTap: controller.rejectCall,
            backgroundColor: const Color(0xFFFF3B30),
            icon: Icons.call_end,
          ),
          // 接听按钮（仅来电时显示）
          if (controller.isIncomingCall)
            Obx(() => _buildAnswerButton()),
        ],
      ),
    );
  }

  /// 构建接听按钮（带加载状态）
  Widget _buildAnswerButton() {
    final isAnswering = controller.isAnswering.value;
    
    Widget button = GestureDetector(
      onTap: isAnswering ? null : controller.answerCall,
      child: Container(
        width: 77,
        height: 77,
        decoration: BoxDecoration(
          color: isAnswering 
              ? const Color(0xFF34C759).withValues(alpha: 0.6)
              : const Color(0xFF34C759),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF34C759).withValues(alpha: 0.4),
              blurRadius: 46,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: isAnswering
            ? const Center(
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                ),
              )
            : const Icon(
                Icons.call,
                color: Colors.white,
                size: 36,
              ),
      ),
    );

    // 非接听中时添加脉冲动画
    if (!isAnswering) {
      return _PulseAnimation(child: button);
    }
    return button;
  }

  /// 构建操作按钮
  Widget _buildActionButton({
    required VoidCallback onTap,
    required Color backgroundColor,
    required IconData icon,
    bool animate = false,
  }) {
    Widget button = GestureDetector(
      onTap: onTap,
      child: Container(
        width: 77,
        height: 77,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: backgroundColor.withValues(alpha: 0.4),
              blurRadius: 46,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 36,
        ),
      ),
    );

    if (animate) {
      return _PulseAnimation(child: button);
    }
    return button;
  }

  /// 获取国旗 emoji
  String _getCountryFlag(String countryCode) {
    // if (countryCode.length != 2) return '🏳️';
    // 国家代码映射表
    const countryMap = {
      // 主要国家
      840: 'US', // United States
      826: 'GB', // United Kingdom
      124: 'CA', // Canada
      156: 'CN', // China
      356: 'IN', // India
      276: 'DE', // Germany
      250: 'FR', // France
      392: 'JP', // Japan
      410: 'KR', // South Korea
      36: 'AU', // Australia (ISO 3166-1 numeric: 036)
      554: 'NZ', // New Zealand
      // 欧洲国家
      724: 'ES', // Spain
      380: 'IT', // Italy
      643: 'RU', // Russia
      528: 'NL', // Netherlands
      56: 'BE', // Belgium
      756: 'CH', // Switzerland
      40: 'AT', // Austria
      752: 'SE', // Sweden
      578: 'NO', // Norway
      208: 'DK', // Denmark
      246: 'FI', // Finland
      616: 'PL', // Poland
      620: 'PT', // Portugal
      300: 'GR', // Greece
      372: 'IE', // Ireland
      642: 'RO', // Romania
      203: 'CZ', // Czech Republic
      348: 'HU', // Hungary
      100: 'BG', // Bulgaria
      191: 'HR', // Croatia
      688: 'RS', // Serbia
      703: 'SK', // Slovakia
      705: 'SI', // Slovenia
      440: 'LT', // Lithuania
      428: 'LV', // Latvia
      233: 'EE', // Estonia
      112: 'BY', // Belarus
      398: 'KZ', // Kazakhstan
      804: 'UA', // Ukraine
      // 亚洲国家
      608: 'PH', // Philippines
      764: 'TH', // Thailand
      704: 'VN', // Vietnam
      360: 'ID', // Indonesia
      458: 'MY', // Malaysia
      702: 'SG', // Singapore
      784: 'AE', // United Arab Emirates
      682: 'SA', // Saudi Arabia
      376: 'IL', // Israel
      792: 'TR', // Turkey
      586: 'PK', // Pakistan
      50: 'BD', // Bangladesh
      144: 'LK', // Sri Lanka
      104: 'MM', // Myanmar
      116: 'KH', // Cambodia
      418: 'LA', // Laos
      496: 'MN', // Mongolia
      524: 'NP', // Nepal
      4: 'AF', // Afghanistan
      368: 'IQ', // Iraq
      364: 'IR', // Iran
      400: 'JO', // Jordan
      422: 'LB', // Lebanon
      760: 'SY', // Syria
      887: 'YE', // Yemen
      512: 'OM', // Oman
      414: 'KW', // Kuwait
      634: 'QA', // Qatar
      48: 'BH', // Bahrain
      // 美洲国家
      76: 'BR', // Brazil
      484: 'MX', // Mexico
      32: 'AR', // Argentina
      152: 'CL', // Chile
      170: 'CO', // Colombia
      604: 'PE', // Peru
      862: 'VE', // Venezuela
      // 非洲国家
      710: 'ZA', // South Africa
      566: 'NG', // Nigeria
      450: 'MG', // Madagascar
      120: 'CM', // Cameroon
      384: 'CI', // Côte d'Ivoire
      686: 'SN', // Senegal
      466: 'ML', // Mali
      854: 'BF', // Burkina Faso
      562: 'NE', // Niger
      404: 'KE', // Kenya
      834: 'TZ', // Tanzania
      800: 'UG', // Uganda
      894: 'ZM', // Zambia
      716: 'ZW', // Zimbabwe
      24: 'AO', // Angola
      508: 'MZ', // Mozambique
      504: 'MA', // Morocco
      12: 'DZ', // Algeria
      788: 'TN', // Tunisia
      434: 'LY', // Libya
      729: 'SD', // Sudan
      231: 'ET', // Ethiopia
      288: 'GH', // Ghana
      // 其他
      818: 'EG', // Egypt
    };
    int coders = int.parse(countryCode);
    final code = countryMap[coders];
    if (code == null || code.length != 2) {
      return '🌍';
    }

    // 将国家代码转换为 emoji 国旗
    final int firstLetter = code.codeUnitAt(0) - 0x41 + 0x1F1E6;
    final int secondLetter = code.codeUnitAt(1) - 0x41 + 0x1F1E6;
    return String.fromCharCode(firstLetter) + String.fromCharCode(secondLetter);
  }
}

/// 水波纹动画
class _RippleAnimation extends StatefulWidget {
  @override
  State<_RippleAnimation> createState() => _RippleAnimationState();
}

class _RippleAnimationState extends State<_RippleAnimation>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (index) {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 2500),
        vsync: this,
      );
      Future.delayed(Duration(milliseconds: index * 830), () {
        if (mounted) {
          controller.repeat();
        }
      });
      return controller;
    });
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: _controllers.map((controller) {
        return AnimatedBuilder(
          animation: controller,
          builder: (context, child) {
            final value = controller.value;
            return Container(
              width: 145 + (145 * 1.25 * value),
              height: 145 + (145 * 1.25 * value),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.35 * (1 - value)),
                  width: 2,
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }
}

/// 脉冲动画
class _PulseAnimation extends StatefulWidget {
  final Widget child;

  const _PulseAnimation({required this.child});

  @override
  State<_PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<_PulseAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
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
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: widget.child,
        );
      },
    );
  }
}
