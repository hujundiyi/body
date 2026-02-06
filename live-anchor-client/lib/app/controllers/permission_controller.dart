import 'package:get/get.dart';
import '../../core/base/base_controller.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/im_service.dart';
import '../../core/services/storage_service.dart';

/// 权限设置控制器
class PermissionController extends BaseController {
  final StorageService _storage = Get.find<StorageService>();
  final IMService _imService = Get.find<IMService>();

  // 通知权限开关（远程推送），默认开启
  final RxBool notificationEnabled = true.obs;

  // 应用内通知权限开关
  final RxBool inAppNotificationEnabled = true.obs;

  // 声音权限开关
  final RxBool soundingEnabled = true.obs;

  @override
  void onControllerInit() {
    super.onControllerInit();
    loadPermissionSettings();
  }

  /// 加载权限设置（从本地存储加载，未存则默认 true）
  void loadPermissionSettings() {
    notificationEnabled.value =
        _storage.getBool(AppConstants.keyRemoteNotificationEnabled) ?? true;
    inAppNotificationEnabled.value =
        _storage.getBool(AppConstants.keyInAppNotificationEnabled) ?? true;
    soundingEnabled.value =
        _storage.getBool(AppConstants.keySoundingEnabled) ?? true;
  }

  /// 切换远程通知权限：保存到本地并同步到 IM 离线推送
  void toggleNotification(bool value) {
    notificationEnabled.value = value;
    _storage.setBool(AppConstants.keyRemoteNotificationEnabled, value);
    _imService.updateRemoteNotificationEnabled(value);
  }

  /// 切换应用内通知权限：保存到本地，IM 展示横幅时会读取该配置
  void toggleInAppNotification(bool value) {
    inAppNotificationEnabled.value = value;
    _storage.setBool(AppConstants.keyInAppNotificationEnabled, value);
  }

  /// 切换来消息/来电铃声：保存到本地，IM/来电展示时会读取该配置并播放提示音
  void toggleSounding(bool value) {
    soundingEnabled.value = value;
    _storage.setBool(AppConstants.keySoundingEnabled, value);
  }
}
