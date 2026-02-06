import 'package:get/get.dart';
import '../network/anchor_api_service.dart';

/// 拉黑用户 ID 列表服务：首页、聊天列表过滤拉黑用户
class BlockedUserService extends GetxService {
  static BlockedUserService get shared => Get.find<BlockedUserService>();

  AnchorAPIService get _api => AnchorAPIService.shared;

  final RxList<int> blockedUserIds = <int>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadBlockedList();
  }

  /// 从接口加载拉黑列表
  Future<void> loadBlockedList() async {
    try {
      final list = await _api.getBlackList(page: 1, size: 500);
      final ids = <int>[];
      for (final item in list) {
        final id = item['userId'] as int? ?? item['blackUserId'] as int? ?? item['id'] as int?;
        if (id != null && id > 0) ids.add(id);
      }
      blockedUserIds.assignAll(ids);
    } catch (_) {
      blockedUserIds.clear();
    }
  }

  bool contains(int userId) => blockedUserIds.contains(userId);

  /// 拉黑成功后本地追加，并刷新列表
  void addBlocked(int userId) {
    if (userId > 0 && !blockedUserIds.contains(userId)) {
      blockedUserIds.add(userId);
    }
  }

  /// 取消拉黑后本地移除
  void removeBlocked(int userId) {
    if (userId > 0) {
      blockedUserIds.remove(userId);
    }
  }
}
