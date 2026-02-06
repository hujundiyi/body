import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:weeder/core/utils/toast_utils.dart';
import 'package:weeder/data/models/user_model_entity.dart';
import '../../core/network/anchor_api_service.dart';
import '../../core/services/call_service.dart';
import '../../routes/app_routes.dart';
import 'user_detail_controller.dart';
import '../pages/Discover/user_detail_page.dart';

/// Followers/Following 列表控制器（Me 页点击 Followers/Following 进入）
class FollowListController extends GetxController with GetSingleTickerProviderStateMixin {
  final AnchorAPIService _api = AnchorAPIService.shared;

  late TabController tabController;

  /// 初始选中的 Tab：0=Followers(follow=false)，1=Following(follow=true)
  int get initialTabIndex => (Get.arguments is Map && (Get.arguments as Map)['initialTab'] != null)
      ? (Get.arguments as Map)['initialTab'] as int
      : 0;

  final RxList<UserModelEntity> followerList = <UserModelEntity>[].obs;
  final RxList<UserModelEntity> followingList = <UserModelEntity>[].obs;

  final RxBool isLoadingFollowers = false.obs;
  final RxBool isLoadingFollowing = false.obs;

  int _pageFollowers = 1;
  int _pageFollowing = 1;
  static const int _pageSize = 20;

  /// 从详情返回时用于同步列表：进入详情前所在的 Tab（0=Followers 1=Following）及点击的用户
  int? _lastOpenedFromTab;
  UserModelEntity? _lastOpenedUser;

  @override
  void onInit() {
    super.onInit();
    final initialIndex = initialTabIndex.clamp(0, 1);
    tabController = TabController(length: 2, vsync: this, initialIndex: initialIndex);
    tabController.addListener(_onTabChanged);
    loadList(follow: initialIndex == 1);
  }

  @override
  void onClose() {
    tabController.removeListener(_onTabChanged);
    tabController.dispose();
    super.onClose();
  }

  void _onTabChanged() {
    if (!tabController.indexIsChanging) {
      final list = tabController.index == 0 ? followerList : followingList;
      if (list.isEmpty) loadList(follow: tabController.index == 1);
    }
  }

  List<UserModelEntity> getListByTab(int tabIndex) {
    return tabIndex == 0 ? followerList : followingList;
  }

  bool getLoadingByTab(int tabIndex) {
    return tabIndex == 0 ? isLoadingFollowers.value : isLoadingFollowing.value;
  }

  /// [follow] false=Followers(关注我的)，true=Following(我关注的)
  Future<void> loadList({required bool follow, bool refresh = false}) async {
    final isFollowing = follow;
    final loading = isFollowing ? isLoadingFollowing : isLoadingFollowers;
    final list = isFollowing ? followingList : followerList;
    if (loading.value) return;

    if (refresh) {
      if (isFollowing)
        _pageFollowing = 1;
      else
        _pageFollowers = 1;
    }

    final page = isFollowing ? _pageFollowing : _pageFollowers;
    loading.value = true;
    try {
      final maps = await _api.getFollowList(page: page, size: _pageSize, follow: follow);
      final users = maps.map((e) => UserModelEntity.fromJson(_normalizeFollowUserMap(e))).toList();

      if (refresh) {
        list.assignAll(users);
      } else {
        list.addAll(users);
      }
      if (isFollowing)
        _pageFollowing = users.length >= _pageSize ? page + 1 : page;
      else
        _pageFollowers = users.length >= _pageSize ? page + 1 : page;
    } catch (e) {
      if (refresh) list.clear();
    } finally {
      loading.value = false;
    }
  }

  /// 将接口单条数据规范为 UserModelEntity 可解析的 Map（支持嵌套 user/userInfo、user_id/id 等）
  static Map<String, dynamic> _normalizeFollowUserMap(Map<String, dynamic> raw) {
    Map<String, dynamic> map = raw;
    if (raw['user'] is Map) {
      map = Map<String, dynamic>.from(raw['user'] as Map);
    } else if (raw['userInfo'] is Map) {
      map = Map<String, dynamic>.from(raw['userInfo'] as Map);
    } else {
      map = Map<String, dynamic>.from(raw);
    }
    if (map['userId'] == null && map['user_id'] != null) {
      map['userId'] = map['user_id'];
    }
    if (map['userId'] == null && map['id'] != null) {
      map['userId'] = map['id'];
    }
    if (map['coinBalance'] == null && map['coin_balance'] != null) {
      map['coinBalance'] = map['coin_balance'];
    }
    if (map['onlineStatus'] == null && map['online_status'] != null) {
      map['onlineStatus'] = map['online_status'];
    }
    return map;
  }

  Future<void> refreshListByTab(int tabIndex) async {
    await loadList(follow: tabIndex == 1, refresh: true);
  }

  Future<void> startVideoCall(UserModelEntity user) async {
    if (user.userId <= 0) {
      ToastUtils.showInfo('Unable to start call, user info incomplete');
      return;
    }
    if (Get.isRegistered<CallService>()) {
      final callService = Get.find<CallService>();
      await callService.createCall(toUserId: user.userId, userInfo: user);
    } else {
      ToastUtils.showInfo('Call service not initialized');
    }
  }

  void openUserDetail(UserModelEntity user) {
    _lastOpenedFromTab = tabController.index;
    _lastOpenedUser = user;
    Get.to(
      () => const UserDetailPage(),
      arguments: {'userId': user.userId, 'fromFollowList': true},
      binding: BindingsBuilder(() {
        Get.lazyPut<UserDetailController>(() => UserDetailController());
      }),
      transition: Transition.rightToLeft,
      duration: const Duration(milliseconds: 300),
    )?.then((result) {
      if (result is! Map) return;
      if (result['blockedUserId'] != null) {
        refreshListByTab(tabController.index);
        _lastOpenedFromTab = null;
        _lastOpenedUser = null;
        return;
      }
      final userId = result['userId'] as int?;
      final isNowFollowing = result['isNowFollowing'] == true;
      if (userId == null || _lastOpenedFromTab == null) {
        _lastOpenedFromTab = null;
        _lastOpenedUser = null;
        return;
      }
      if (_lastOpenedFromTab == 1 && !isNowFollowing) {
        followingList.removeWhere((e) => e.userId == userId);
      } else if (_lastOpenedFromTab == 0 && isNowFollowing && _lastOpenedUser != null) {
        followingList.insert(0, _lastOpenedUser!);
      }
      _lastOpenedFromTab = null;
      _lastOpenedUser = null;
    });
  }

  void startChat(UserModelEntity user) {
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
