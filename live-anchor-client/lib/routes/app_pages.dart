import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app_routes.dart';

class AppPages {
  static const String initial = AppRoutes.splash;
  
  static final List<GetPage> routes = AppRoutes.routes;
  
  // 获取路由配置
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    return null; // 使用GetX的路由管理
  }
  
  // 获取未知路由
  static Route<dynamic>? onUnknownRoute(RouteSettings settings) {
    return GetPageRoute(
      settings: settings,
      page: () => const Scaffold(
        body: Center(
          child: Text('Page not found'),
        ),
      ),
    );
  }
}
