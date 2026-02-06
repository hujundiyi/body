import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../core/base/base_controller.dart';
import '../../core/network/anchor_api_service.dart';

/// Work Rules 规则页控制器
class WorkRulesController extends BaseController {
  /// H5 地址，null 表示未加载或加载失败
  final Rx<String?> h5Url = Rx<String?>(null);

  @override
  void onControllerInit() {
    super.onControllerInit();
    loadH5Url();
  }

  /// 从接口获取 H5 URL
  Future<void> loadH5Url() async {
    setLoading(true);
    try {
      final url = await AnchorAPIService.shared.getTaskH5Url();
      h5Url.value = url;
      if (url == null || url.isEmpty) {
        showError('Failed to load rules');
      }
    } catch (e) {
      debugPrint('Failed to load H5 URL: $e');
      showErrorUnlessAuth(e, 'Failed to load rules');
    } finally {
      setLoading(false);
    }
  }

  /// 同意并继续：关闭当前页
  void agreeAndContinue() {
    Get.back();
  }
}
