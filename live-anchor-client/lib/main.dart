import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:weeder/core/network/api_client.dart';
import 'package:weeder/core/services/fcm_service.dart';
import 'package:weeder/core/services/im_service.dart';
import 'package:weeder/core/services/trtc_service.dart';
import 'package:weeder/core/services/call_service.dart';
import 'package:weeder/core/services/translation_service.dart';
import 'package:weeder/routes/app_routes.dart';
import 'core/network/anchor_api_service.dart';
import 'core/utils/toast_utils.dart';
import 'core/services/storage_service.dart';
import 'core/services/auth_service.dart';
import 'core/services/app_config_service.dart';
import 'core/services/blocked_user_service.dart';
import 'core/services/country_dict_service.dart';
import 'routes/app_pages.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // FCM 后台消息必须在 runApp 前注册
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // release 下捕获未处理错误，避免直接崩溃
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    if (kReleaseMode) {
      debugPrint('FlutterError: ${details.exception}\n${details.stack}');
    }
  };
  runZonedGuarded(
    () async {
      // 设置屏幕方向为仅竖屏
      await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

      // 初始化服务
      await _initServices();

      // 根据认证与审核状态决定初始路由
      final initialRoute = await _getInitialRoute();
      runApp(MyApp(initialRoute: initialRoute));
    },
    (error, stack) {
      if (kReleaseMode) {
        debugPrint('runZonedGuarded: $error\n$stack');
      }
      Error.throwWithStackTrace(error, stack);
    },
  );
}

/// 获取启动初始路由：未登录→登录页；本地 auditStatus 2/3→登录页；0→首页；1→资料申请
Future<String> _getInitialRoute() async {
  final authService = Get.find<AuthService>();
  if (!authService.isAuthenticated) {
    return AppRoutes.anchorLogin;
  }

  try {
    final anchor = await AnchorAPIService.shared.getAnchorInfo();
    if (anchor.auditStatus == 2 || anchor.auditStatus == 3) {
      return AppRoutes.anchorLogin;
    }
    if (anchor.auditStatus == 0) return AppRoutes.mainTab;
    if (anchor.auditStatus == 1) return AppRoutes.anchorApply;
    return AppRoutes.mainTab;
  } catch (_) {
    return AppRoutes.anchorLogin;
  }
}

/// 初始化服务（Firebase/FCM 不阻塞，后台异步初始化）
Future<void> _initServices() async {
  // 0. Firebase（FCM 依赖）
  Firebase.initializeApp();

  // 1. 初始化存储服务（必须最先初始化）
  await Get.putAsync(() => StorageService().init());

  // 2. 初始化API客户端
  Get.put(APIClient());

  // 3. 初始化应用配置服务（先加载本地，后台更新网络）
  await Get.putAsync(() => AppConfigService().init());

  // 5. 初始化IM服务
  Get.put(IMService());

  // 4. 初始化认证服务
  Get.put(AuthService());

  // 4.1 拉黑用户列表服务（首页、聊天过滤）
  Get.put(BlockedUserService());

  // 4.2 国家字典服务（本地缓存，无则请求字典接口）
  Get.put(CountryDictService());

  // 6. 初始化 TRTC 服务（腾讯云实时音视频）
  Get.put(TRTCService());

  // 7. 初始化通话服务
  Get.put(CallService());

  // 8. 初始化翻译服务
  Get.put(TranslationService());

  // 9. Firebase + FCM 推送服务（后台异步，不阻塞进入首页）
  // unawaited(_initFirebaseAndFCM());
}

/// Firebase 与 FCM 后台初始化，完成后注册到 Get
// Future<void> _initFirebaseAndFCM() async {
//   try {
//     await Firebase.initializeApp();
//     final fcm = await FCMService().init();
//     Get.put(fcm);
//   } catch (e, st) {
//     if (kDebugMode) debugPrint('Firebase/FCM init error: $e\n$st');
//   }
// }

class MyApp extends StatefulWidget {
  const MyApp({super.key, required this.initialRoute});
  final String initialRoute;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // 确保应用启动后保持竖屏
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (Get.isRegistered<IMService>()) {
      Get.find<IMService>().updateAppLifecycle(state);
    }
  }

  @override
  void dispose() {
    // 应用退出时恢复所有方向（可选）
    WidgetsBinding.instance.removeObserver(this);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Weeder',
      debugShowCheckedModeBanner: false,
      // 在所有页面中添加点击空白处隐藏键盘的功能，并注入 Overlay 供应用内消息弹窗使用
      builder: (context, child) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final overlay = Get.key.currentState?.overlay;
          ToastUtils.attachOverlayState(overlay);
        });
        return GestureDetector(
          onTap: () {
            // 点击空白处时，取消当前焦点，从而隐藏键盘
            // 只有当没有子组件处理点击事件时才会触发
            final currentFocus = FocusScope.of(context);
            if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
              currentFocus.unfocus();
            }
          },
          // 使用 translucent 确保不阻止子组件接收事件
          behavior: HitTestBehavior.translucent,
          child: child,
        );
      },
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green, brightness: Brightness.light),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
        cardTheme: CardThemeData(elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green, brightness: Brightness.dark),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
        cardTheme: CardThemeData(elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ),
      themeMode: ThemeMode.system,
      initialRoute: widget.initialRoute,
      getPages: AppPages.routes,
      defaultTransition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
      onGenerateRoute: AppPages.onGenerateRoute,
      onUnknownRoute: AppPages.onUnknownRoute,
    );
  }
}
