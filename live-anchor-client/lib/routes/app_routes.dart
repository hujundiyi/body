import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import '../app/pages/home_page.dart';
import '../app/pages/initial_redirect_page.dart';
import '../app/pages/Login/anchor_login_page.dart';
import '../app/pages/Login/register_page.dart';
import '../app/pages/chat_page.dart';
import '../app/pages/emoji_chat_page.dart';
import '../app/pages/emoji_picker_chat_page.dart';
import '../app/pages/extended_chat_page.dart';
import '../app/pages/main_tab_page.dart';
import '../app/controllers/main_tab_controller.dart';
import '../app/controllers/user_list_controller.dart';
import '../app/pages/Discover/user_detail_page.dart';
import '../app/controllers/user_detail_controller.dart';
import '../app/pages/Me/follow_list_page.dart';
import '../app/controllers/follow_list_controller.dart';
// 消息聊天页面
import '../app/pages/Message/message_chat_page.dart';
import '../app/controllers/message_chat_controller.dart';
// 主播端页面
import '../app/pages/Login/anchor_apply_page.dart';
import '../app/pages/audit_status_page.dart';
import '../app/controllers/anchor_login_controller.dart';
import '../app/controllers/anchor_apply_controller.dart';
import '../app/controllers/audit_status_controller.dart';
// 账单页面
import '../app/pages/Bill/bill_page.dart';
import '../app/controllers/bill_controller.dart';
import '../app/pages/Bill/bill_detail_page.dart';
import '../app/controllers/bill_detail_controller.dart';
// 提现页面
import '../app/pages/Withdraw/withdraw_page.dart';
import '../app/controllers/withdraw_controller.dart';
// 数据详情页面
import '../app/pages/Data/data_detail_page.dart';
import '../app/controllers/data_detail_controller.dart';
// Say Hi页面
import '../app/pages/SayHi/say_hi_page.dart';
import '../app/controllers/say_hi_controller.dart';
import '../app/pages/SayHi/add_say_hi_page.dart';
import '../app/controllers/add_say_hi_controller.dart';
// 权限页面
import '../app/pages/Permission/permission_page.dart';
import '../app/controllers/permission_controller.dart';
// 通话页面
import '../app/pages/Call/calling_page.dart';
import '../app/pages/Call/incoming_call_page.dart';
import '../app/pages/Call/call_end_page.dart';
import '../app/controllers/call_controller.dart';

class AppRoutes {
  // 路由名称常量
  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String mainTab = '/main_tab';
  static const String chat = '/chat';
  static const String emojiChat = '/emoji_chat';
  static const String emojiPickerChat = '/emoji_picker_chat';
  static const String extendedChat = '/extended_chat';

  // 消息聊天路由
  static const String messageChat = '/message_chat';

  // 主播端路由
  static const String anchorLogin = '/anchor_login';
  static const String anchorApply = '/anchor_apply';

  /// 跳转到主播登录页。不在此处 delete controller，由登录页 build 时 Get.put 自动替换旧实例，避免“TextEditingController used after disposed”。
  /// 若 GetMaterialApp 尚未 build（如 401 在首帧前触发），则推迟到下一帧再导航。
  static void goToAnchorLogin() {
    if (Get.currentRoute == anchorLogin) return;
    void doNavigate() {
      if (Get.key.currentState != null) {
        Get.offAllNamed(anchorLogin);
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) => doNavigate());
      }
    }

    doNavigate();
  }

  static const String auditStatus = '/audit_status';

  // 工作台相关路由
  static const String bill = '/bill';
  static const String billDetail = '/bill_detail';
  static const String withdraw = '/withdraw';
  static const String dataDetail = '/data_detail';
  static const String sayHi = '/say_hi';
  static const String addSayHi = '/add_say_hi';
  static const String permission = '/permission';

  // 通话相关路由
  static const String calling = '/calling';
  static const String incomingCall = '/incoming_call';
  static const String callEnd = '/call_end';

  // 用户详情
  static const String userDetail = '/user_detail';

  // Followers/Following 列表（Me 页）
  static const String followList = '/follow_list';

  // 保持向后兼容的常量（使用大写）
  static const String CALLING = calling;
  static const String INCOMING_CALL = incomingCall;
  static const String CALL_END = callEnd;

  // 路由列表
  static final List<GetPage> routes = [
    GetPage(
      name: splash,
      page: () => const InitialRedirectPage(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: login,
      page: () => const AnchorLoginPage(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: register,
      page: () => const RegisterPage(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: home,
      page: () => const HomePage(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    // 主 Tab 页面
    GetPage(
      name: mainTab,
      page: () => const MainTabPage(),
      binding: BindingsBuilder(() {
        Get.lazyPut<MainTabController>(() => MainTabController());
        Get.lazyPut<UserListController>(() => UserListController());
      }),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    // 用户详情（进入时调用 user/getInfo）
    GetPage(
      name: userDetail,
      page: () => const UserDetailPage(),
      binding: BindingsBuilder(() {
        Get.lazyPut<UserDetailController>(() => UserDetailController());
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    // Followers/Following 列表（Me 页点击进入）
    GetPage(
      name: followList,
      page: () => const FollowListPage(),
      binding: BindingsBuilder(() {
        Get.lazyPut<FollowListController>(() => FollowListController());
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: chat,
      page: () => const ChatPage(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: emojiChat,
      page: () => EmojiChatPage(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: emojiPickerChat,
      page: () => const EmojiPickerChatPage(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: extendedChat,
      page: () => const ExtendedChatPage(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    // ==================== 消息聊天页面 ====================

    // 聊天详情页面
    GetPage(
      name: messageChat,
      page: () => MessageChatPage(),
      binding: BindingsBuilder(() {
        Get.lazyPut<MessageChatController>(() => MessageChatController());
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    // ==================== 主播端页面 ====================

    // 主播登录
    GetPage(
      name: anchorLogin,
      page: () => const AnchorLoginPage(),
      binding: BindingsBuilder(() {
        Get.lazyPut<AnchorLoginController>(() => AnchorLoginController());
      }),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    // 主播申请/入驻
    GetPage(
      name: anchorApply,
      page: () => const AnchorApplyPage(),
      binding: BindingsBuilder(() {
        Get.lazyPut<AnchorApplyController>(() => AnchorApplyController());
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    // 审核状态
    GetPage(
      name: auditStatus,
      page: () => const AuditStatusPage(),
      binding: BindingsBuilder(() {
        Get.lazyPut<AuditStatusController>(() => AuditStatusController());
      }),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    // ==================== 工作台相关页面 ====================

    // 账单页面
    GetPage(
      name: bill,
      page: () => const BillPage(),
      binding: BindingsBuilder(() {
        Get.lazyPut<BillController>(() => BillController());
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    // 账单详情页面
    GetPage(
      name: billDetail,
      page: () => const BillDetailPage(),
      binding: BindingsBuilder(() {
        Get.lazyPut<BillDetailController>(() => BillDetailController());
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    // 提现页面
    GetPage(
      name: withdraw,
      page: () => const WithdrawPage(),
      binding: BindingsBuilder(() {
        Get.lazyPut<WithdrawController>(() => WithdrawController());
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    // 数据详情页面
    GetPage(
      name: dataDetail,
      page: () => const DataDetailPage(),
      binding: BindingsBuilder(() {
        Get.lazyPut<DataDetailController>(() => DataDetailController());
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    // Say Hi页面
    GetPage(
      name: sayHi,
      page: () => const SayHiPage(),
      binding: BindingsBuilder(() {
        Get.put<SayHiController>(SayHiController());
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    // 添加Say Hi页面
    GetPage(
      name: addSayHi,
      page: () => const AddSayHiPage(),
      binding: BindingsBuilder(() {
        Get.put<AddSayHiController>(AddSayHiController());
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    // 权限设置页面
    GetPage(
      name: permission,
      page: () => const PermissionPage(),
      binding: BindingsBuilder(() {
        Get.put<PermissionController>(PermissionController());
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    // ==================== 通话相关页面 ====================

    // 通话中页面（controller 由页面自行管理）
    GetPage(
      name: CALLING,
      page: () => const CallingPage(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    // 来电页面（controller 由页面自行管理）
    GetPage(
      name: INCOMING_CALL,
      page: () => const IncomingCallPage(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    // 通话结束页面（controller 由页面自行管理）
    GetPage(
      name: CALL_END,
      page: () => const CallEndPage(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
    ),
  ];

  // 路由跳转方法
  static Future<T?>? toNamed<T>(String routeName, {dynamic arguments}) {
    return Get.toNamed<T>(routeName, arguments: arguments);
  }

  static Future<T?>? offNamed<T>(String routeName, {dynamic arguments}) {
    return Get.offNamed<T>(routeName, arguments: arguments);
  }

  static Future<T?>? offAllNamed<T>(String routeName, {dynamic arguments}) {
    return Get.offAllNamed<T>(routeName, arguments: arguments);
  }

  static void back<T>([T? result]) {
    Get.back<T>(result: result);
  }
}
