import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/initial_redirect_controller.dart';

/// 启动入口页：无 UI，直接根据认证状态跳转到登录/首页/资料申请
class InitialRedirectPage extends StatelessWidget {
  const InitialRedirectPage({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(InitialRedirectController());
    return const Scaffold(
      body: Center(
        child: SizedBox.shrink(),
      ),
    );
  }
}
