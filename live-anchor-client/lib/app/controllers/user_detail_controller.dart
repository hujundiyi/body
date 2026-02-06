import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:weeder/core/utils/toast_utils.dart';
import 'package:weeder/data/models/user_model_entity.dart';
import 'package:weeder/data/models/call_history_model.dart';
import 'package:weeder/data/models/dict_model.dart';
import '../../core/network/api_services.dart';
import '../../core/network/anchor_api_service.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/blocked_user_service.dart';
import '../../core/services/country_dict_service.dart';
import '../../core/services/call_service.dart';
import '../../routes/app_routes.dart';

/// 用户详情页控制器
/// 进入页面调用 user/getInfo，展示详情与通话历史
class UserDetailController extends GetxController {
  final Rx<UserModelEntity?> user = Rx<UserModelEntity?>(null);
  final RxBool isLoading = true.obs;

  /// 通话记录来自详情接口 user/getInfo 的 callList，不再调用 call/getCallHistory
  List<CallHistory> get callHistoryList => user.value?.callList ?? [];

  /// 国家字典：value -> label
  final RxMap<int, String> countryDict = <int, String>{}.obs;

  int get userId => _userId;
  int _userId = 0;

  /// 是否从 Follow 列表页（Followers/Following）进入，返回时需带上关注状态供列表页同步
  bool get fromFollowList => (Get.arguments is Map) && ((Get.arguments as Map)['fromFollowList'] == true);

  /// 拉黑成功后设为被拉黑用户 id，详情页监听到后执行 Get.back(result: ...)
  final RxInt blockSuccessUserId = 0.obs;

  /// 当前登录用户（主播）ID，用于通话记录区分拨出/接听（createUserId 与自己相同为拨出）
  int? get selfUserId {
    try {
      return Get.find<AuthService>().userInfo?.userId;
    } catch (_) {
      return null;
    }
  }

  UserAPIService get _userApi => UserAPIService.shared;
  AnchorAPIService get _anchorApi => AnchorAPIService.shared;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>?;
    _userId = args?['userId'] as int? ?? 0;
    if (_userId > 0) {
      loadDict();
      loadUser();
    } else {
      isLoading.value = false;
    }
  }

  /// 加载国家字典（优先本地缓存，无则请求字典接口）
  Future<void> loadDict() async {
    try {
      final countryService = Get.find<CountryDictService>();
      await countryService.loadCountryDict();
      countryDict.assignAll(countryService.countryMap);
    } catch (_) {}
  }

  /// 国家名称（来自 loadDict 加载的国家字典，含本地缓存）
  String countryLabel(int value) {
    if (value <= 0) return '--';
    return countryDict[value] ?? '--';
  }

  /// 加载用户详情（user/getInfo）
  Future<void> loadUser() async {
    if (_userId <= 0) return;
    isLoading.value = true;
    try {
      final u = await _userApi.getUserDetail(_userId);
      user.value = u;
    } catch (e) {
      ToastUtils.showError('Load failed');
    } finally {
      isLoading.value = false;
    }
  }

  /// 平均通话时长：取 user/getInfo 的 callAvgTimes（秒），格式化为 00:00:00
  String get averageCallTimeFormatted {
    final sec = user.value?.callAvgTimes ?? 0;
    if (sec <= 0) return '--';
    final h = sec ~/ 3600;
    final m = (sec % 3600) ~/ 60;
    final s = sec % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  /// 注册时间：秒级字符串转 yyyy-MM-dd
  String registrationTimeFormatted(String createTime) {
    if (createTime.isEmpty) return '--';
    final sec = int.tryParse(createTime.trim());
    if (sec == null || sec <= 0) return '--';
    final dt = DateTime.fromMillisecondsSinceEpoch(sec * 1000);
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  /// 复制用户 ID
  void copyId() {
    final id = user.value?.userId.toString() ?? '';
    if (id.isEmpty) return;
    Clipboard.setData(ClipboardData(text: id));
    ToastUtils.showSuccess('ID copied');
  }

  /// 发消息
  void sendMessage() {
    final u = user.value;
    if (u == null) return;
    Get.toNamed(
      AppRoutes.messageChat,
      arguments: {
        'conversationID': 'c2c_${u.userId}',
        'userID': '${u.userId}',
        'groupID': null,
        'name': u.nickname,
        'avatar': u.avatar,
      },
    );
  }

  /// 关注状态（接口返回 followStatus）：0=互不关注 1=对方关注我 2=我关注对方 3=互相关注；详情与喜欢按钮均据此控制
  int get followStatus => user.value?.following ?? 0;

  /// 喜欢按钮“已喜欢”状态：followStatus 为 2 或 3
  bool get isFollowing => followStatus == 2 || followStatus == 3;

  /// 喜欢：调用 userStatus/followStatus，接口返回 followStatus 0/1/2/3，用返回值更新后按钮按 followStatus 显示
  Future<void> like() async {
    if (_userId <= 0) return;
    final follow = !isFollowing; // 当前 0/1 则传 true 关注，当前 2/3 则传 false 取消
    try {
      final newState = await _anchorApi.followStatus(followUserId: _userId, follow: follow);
      if (user.value != null) {
        final status = (newState != null && newState >= 0 && newState <= 3) ? newState : (follow ? 2 : 0);
        user.value = user.value!.copyWith(following: status);
      } else {
        await loadUser();
      }
      ToastUtils.showSuccess(isFollowing ? 'Following' : 'Unfollowed');
    } catch (e) {
      ToastUtils.showError('Operation failed');
    }
  }

  /// 视频通话
  Future<void> videoCall() async {
    final u = user.value;
    if (u == null) return;

    // 发起通话
    if (Get.isRegistered<CallService>()) {
      final callService = Get.find<CallService>();
      await callService.createCall(toUserId: u.userId!, userInfo: u);
    } else {
      ToastUtils.showInfo('Call service not initialized');
    }
  }

  /// 举报入口（保留以供反射/绑定查找；实际由页面 _showReportDialog 调 loadReportTypes + 弹窗）
  void onReport() {}

  /// 加载举报类型字典（report_type），用于举报弹窗
  Future<List<DictItem>> loadReportTypes() async {
    try {
      final list = await _anchorApi.getDict(['report_type']);
      for (final res in list) {
        if (res.dictType == 'report_type' && res.dictItems.isNotEmpty) {
          return res.dictItems;
        }
      }
    } catch (_) {}
    return [];
  }

  /// 提交举报（user/reportUser）
  Future<void> submitReport(int reportType) async {
    try {
      await _anchorApi.reportUser(reportType: reportType, reportedType: 'USER_INFO', reportedId: _userId);
      Get.back(); // 关闭举报弹窗
      ToastUtils.showSuccess('Report submitted');
    } catch (e) {
      ToastUtils.showError('Submit failed');
    }
  }

  /// 解析 blackStatus 返回的 data，支持 int、num、String "3"
  static int? _blackStatusCode(dynamic result) {
    if (result == null) return null;
    if (result is int) return result;
    if (result is num) return result.toInt();
    if (result is String) return int.tryParse(result.trim());
    return null;
  }

  /// 拉黑用户（blackUserId 为对方 id，black: true），成功则提示、返回上级并带 result 供首页刷新
  /// 接口未抛异常即视为成功（data 为 1/3 或其它格式都执行提示+返回）
  Future<void> onBlock() async {
    if (_userId <= 0) return;
    try {
      final result = await _anchorApi.blackStatus(blackUserId: _userId, black: true);
      final code = _blackStatusCode(result);
      // 明确返回 0 或 2 等表示失败时才提示失败，否则一律视为成功
      final explicitFail = code != null && code != 1 && code != 3;
      if (explicitFail) {
        ToastUtils.showError('Operation failed');
        return;
      }
      // 成功：更新本地拉黑列表 → 通知页面返回
      try {
        BlockedUserService.shared.addBlocked(_userId);
      } catch (_) {}
      blockSuccessUserId.value = _userId;
    } catch (e) {
      ToastUtils.showError('Operation failed');
    }
  }
}
