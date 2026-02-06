import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:weeder/core/utils/toast_utils.dart';
import 'package:weeder/data/models/user_model_entity.dart';
import '../../core/network/network.dart';
import '../../core/services/blocked_user_service.dart';
import '../../core/services/call_service.dart';
import '../../routes/app_routes.dart';
import 'user_detail_controller.dart';
import '../pages/Discover/user_detail_page.dart';

/// 用户列表控制器
class UserListController extends GetxController with GetSingleTickerProviderStateMixin {
  // TabController
  late TabController tabController;

  // 三个 Tab 的用户列表
  final RxList<UserModelEntity> allUserList = <UserModelEntity>[].obs;
  final RxList<UserModelEntity> intimateUserList = <UserModelEntity>[].obs;
  final RxList<UserModelEntity> followerUserList = <UserModelEntity>[].obs;

  // 三个 Tab 的加载状态
  final RxBool isLoadingAll = false.obs;
  final RxBool isLoadingIntimate = false.obs;
  final RxBool isLoadingFollower = false.obs;

  // 三个 Tab 是否还有更多数据
  final RxBool hasMoreAll = true.obs;
  final RxBool hasMoreIntimate = true.obs;
  final RxBool hasMoreFollower = true.obs;

  // 三个 Tab 的当前页码（后端从 1 开始，第一页为 1）
  int _currentPageAll = 1;
  int _currentPageIntimate = 1;
  int _currentPageFollower = 1;

  static const int _pageSize = 20;

  /// 上拉加载阈值（距离底部多少像素时触发）
  static const double _loadMoreThreshold = 200;

  // 三个 Tab 的 ScrollController（用于上拉加载更多）
  late ScrollController scrollControllerAll;
  late ScrollController scrollControllerIntimate;
  late ScrollController scrollControllerFollower;

  // Tab 类型映射
  static const List<String> _tabTypes = ['ALL', 'INTIMATE', 'FOLLOW'];

  // 当前选中的 Tab 索引（兼容旧代码）
  final RxInt selectedTabIndex = 0.obs;

  // 兼容旧代码的 userList
  RxList<UserModelEntity> get userList => allUserList;
  RxBool get isLoading => isLoadingAll;
  RxBool get hasMore => hasMoreAll;

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: 3, vsync: this);
    tabController.addListener(_onTabChanged);
    scrollControllerAll = ScrollController()..addListener(() => _onScroll(0));
    scrollControllerIntimate = ScrollController()..addListener(() => _onScroll(1));
    scrollControllerFollower = ScrollController()..addListener(() => _onScroll(2));
    // 初始加载第一个 Tab 的数据
    loadUserListByTab(0);
  }

  @override
  void onClose() {
    tabController.removeListener(_onTabChanged);
    tabController.dispose();
    scrollControllerAll.dispose();
    scrollControllerIntimate.dispose();
    scrollControllerFollower.dispose();
    super.onClose();
  }

  /// 滚动监听：接近底部时加载更多
  void _onScroll(int tabIndex) {
    final ScrollController sc = getScrollControllerByTab(tabIndex);
    if (!sc.hasClients) return;
    final position = sc.position;
    if (position.pixels >= position.maxScrollExtent - _loadMoreThreshold) {
      loadUserListByTab(tabIndex);
    }
  }

  /// 根据 Tab 索引获取 ScrollController
  ScrollController getScrollControllerByTab(int tabIndex) {
    switch (tabIndex) {
      case 0:
        return scrollControllerAll;
      case 1:
        return scrollControllerIntimate;
      case 2:
        return scrollControllerFollower;
      default:
        return scrollControllerAll;
    }
  }

  /// 根据 Tab 索引获取是否还有更多
  bool getHasMoreByTab(int tabIndex) {
    switch (tabIndex) {
      case 0:
        return hasMoreAll.value;
      case 1:
        return hasMoreIntimate.value;
      case 2:
        return hasMoreFollower.value;
      default:
        return false;
    }
  }

  /// Tab 切换监听
  void _onTabChanged() {
    if (!tabController.indexIsChanging) {
      final index = tabController.index;
      selectedTabIndex.value = index;
      // 如果该 Tab 还没有数据，则加载
      final userList = getUserListByTab(index);
      if (userList.isEmpty) {
        loadUserListByTab(index);
      }
    }
  }

  /// 根据 Tab 索引获取用户列表
  List<UserModelEntity> getUserListByTab(int tabIndex) {
    switch (tabIndex) {
      case 0:
        return allUserList;
      case 1:
        return intimateUserList;
      case 2:
        return followerUserList;
      default:
        return allUserList;
    }
  }

  /// 根据 Tab 索引获取加载状态
  bool getLoadingByTab(int tabIndex) {
    switch (tabIndex) {
      case 0:
        return isLoadingAll.value;
      case 1:
        return isLoadingIntimate.value;
      case 2:
        return isLoadingFollower.value;
      default:
        return false;
    }
  }

  /// 根据 Tab 索引加载用户列表
  Future<void> loadUserListByTab(int tabIndex, {bool refresh = false}) async {
    final RxBool loading;
    final RxBool hasMore;
    final RxList<UserModelEntity> userList;
    int currentPage;

    switch (tabIndex) {
      case 0:
        loading = isLoadingAll;
        hasMore = hasMoreAll;
        userList = allUserList;
        currentPage = _currentPageAll;
        break;
      case 1:
        loading = isLoadingIntimate;
        hasMore = hasMoreIntimate;
        userList = intimateUserList;
        currentPage = _currentPageIntimate;
        break;
      case 2:
        loading = isLoadingFollower;
        hasMore = hasMoreFollower;
        userList = followerUserList;
        currentPage = _currentPageFollower;
        break;
      default:
        return;
    }

    if (loading.value) return;

    if (refresh) {
      currentPage = 1;
      hasMore.value = true;
    }

    if (!hasMore.value && !refresh) return;

    loading.value = true;

    try {
      final users = await UserAPIService.shared.getUserList({
        'page': currentPage,
        'size': _pageSize,
        'type': _tabTypes[tabIndex],
      });
      final blocked = Get.find<BlockedUserService>().blockedUserIds;
      final filtered = users.where((u) => !blocked.contains(u.userId)).toList();

      if (refresh) {
        userList.value = filtered;
      } else {
        userList.addAll(filtered);
      }

      // 判断是否还有更多；下一页为 currentPage + 1（后端页码从 1 开始）
      hasMore.value = users.length >= _pageSize;
      if (users.isNotEmpty) {
        currentPage++;
      }

      // 更新页码
      switch (tabIndex) {
        case 0:
          _currentPageAll = currentPage;
          break;
        case 1:
          _currentPageIntimate = currentPage;
          break;
        case 2:
          _currentPageFollower = currentPage;
          break;
      }
    } on APIException catch (e) {
      print('Failed to get user list: ${e.message}');
    } catch (e) {
      print('Failed to get user list: $e');
    } finally {
      loading.value = false;
    }
  }

  /// 刷新指定 Tab 的列表
  Future<void> refreshListByTab(int tabIndex) async {
    await loadUserListByTab(tabIndex, refresh: true);
  }

  /// 刷新当前 Tab 的列表（兼容旧代码）
  Future<void> refreshList() async {
    await loadUserListByTab(tabController.index, refresh: true);
  }

  /// 加载更多（兼容旧代码）
  Future<void> loadMore() async {
    await loadUserListByTab(tabController.index);
  }

  /// 切换 Tab（兼容旧代码）
  void changeTab(int index) {
    tabController.animateTo(index);
  }

  /// Start video call
  Future<void> startVideoCall(UserModelEntity user) async {
    if (user.userId == null) {
      ToastUtils.showInfo('Unable to start call, user info incomplete');
      return;
    }

    // 发起通话
    if (Get.isRegistered<CallService>()) {
      final callService = Get.find<CallService>();
      await callService.createCall(toUserId: user.userId!, userInfo: user);
    } else {
      ToastUtils.showInfo('Call service not initialized');
    }
  }

  /// 进入用户详情（调用 user/getInfo），返回时若带 blockedUserId 则刷新列表以过滤拉黑用户
  void openUserDetail(UserModelEntity user) {
    Get.to(
      () => const UserDetailPage(),
      arguments: {'userId': user.userId},
      binding: BindingsBuilder(() {
        Get.lazyPut<UserDetailController>(() => UserDetailController());
      }),
      transition: Transition.rightToLeft,
      duration: const Duration(milliseconds: 300),
    )?.then((result) {
      if (result is Map && result['blockedUserId'] != null) {
        refreshList(); // 拉黑成功后刷新当前 Tab 列表，过滤掉该用户
      }
    });
  }

  /// Start chat
  void startChat(UserModelEntity user) {
    print('Starting chat: ${user.nickname}');
    // Navigate to chat detail page
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
}
