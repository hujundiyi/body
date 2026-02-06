import 'package:flutter/material.dart';

/// 点击空白处隐藏键盘的包装器
/// 包裹在 Scaffold 的 body 外层，自动处理点击空白处隐藏键盘
class DismissKeyboard extends StatelessWidget {
  final Widget child;

  const DismissKeyboard({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // 点击空白处时，取消当前焦点，从而隐藏键盘
        FocusScope.of(context).unfocus();
      },
      // 不拦截子组件的点击事件
      behavior: HitTestBehavior.opaque,
      child: child,
    );
  }
}
