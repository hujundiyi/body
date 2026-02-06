import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../constants/app_constants.dart';
import '../network/api_client.dart';
import '../../data/models/app_config_model.dart';
import 'storage_service.dart';

/// 应用配置服务
/// 启动时先加载本地配置，然后网络更新
class AppConfigService extends GetxService {
  static AppConfigService get shared => Get.find<AppConfigService>();

  late StorageService _storage;

  // 配置数据
  final Rx<AppConfigModel?> _config = Rx<AppConfigModel?>(null);

  // 是否已加载
  final RxBool isLoaded = false.obs;

  /// 获取配置
  AppConfigModel? get config => _config.value;

  /// 初始化服务
  Future<AppConfigService> init() async {
    _storage = Get.find<StorageService>();

    // 1. 先加载本地缓存配置
    await _loadLocalConfig();

    // 2. 网络获取最新配置（不阻塞启动）
    _fetchRemoteConfig();

    return this;
  }

  /// 从本地加载配置
  Future<void> _loadLocalConfig() async {
    try {
      final configJson = _storage.getString(StorageKeys.appConfig);
      if (configJson != null && configJson.isNotEmpty) {
        final Map<String, dynamic> data = json.decode(configJson);
        _config.value = AppConfigModel.fromJson(data);
        debugPrint('本地配置加载成功: ${_config.value}');
      }
      isLoaded.value = true;
    } catch (e) {
      debugPrint('加载本地配置失败: $e');
    }
  }

  /// 从网络获取配置
  Future<void> _fetchRemoteConfig() async {
    try {
      await fetchConfig();
    } catch (e) {
      debugPrint('网络获取配置失败: $e');
    }
  }

  /// 获取配置（网络请求）
  Future<void> fetchConfig() async {
    try {
      final response = await APIClient.shared.request<Map<String, dynamic>>(
        APIPaths.getConfig,
        params: {
          'configs': ["ANCHOR_OPERATE_CONTACTS", "ANCHOR_WITHDRAWAL_MIN_MONEY", "ANCHOR_WITHDRAWAL_COMMISSION"],
          'dictTypes': <String>[],
        },
        fromJsonT: (json) => json as Map<String, dynamic>,
      );

      // 解析配置
      // 返回格式: { "configs": { "KEY": "value", ... }, "dict": [...] }
      if (response['configs'] != null) {
        final configData = response['configs'] as Map<String, dynamic>;
        _config.value = AppConfigModel.fromJson(configData);

        // 保存到本地
        await _storage.setString(StorageKeys.appConfig, json.encode(configData));
        debugPrint('配置更新成功: ${_config.value}');
      }

      isLoaded.value = true;
    } catch (e) {
      debugPrint('获取配置失败: $e');
      rethrow;
    }
  }

  /// 刷新配置（手动调用）
  Future<void> refresh() async {
    await fetchConfig();
  }

  /// 清除本地缓存
  Future<void> clearCache() async {
    await _storage.remove(StorageKeys.appConfig);
    _config.value = null;
    isLoaded.value = false;
  }

  // ========== 便捷属性（代理到 config）==========

  /// 声网 AppId
  String get agoraAppId => _config.value?.agoraAppId ?? '';

  /// 腾讯云 IM AppId
  int get tencentChatAppId => _config.value?.tencentChatAppId ?? 0;

  int get tencentRtcAppId => _config.value?.tencentRtcAppId ?? 0;

  /// 腾讯云推送 ID
  String get tencentChatPushId => _config.value?.tencentChatPushId ?? '';

  /// 用户协议 URL
  String get userAgreementUrl => _config.value?.userAgreementUrl ?? '';

  /// 隐私协议 URL
  String get privacyAgreementUrl => _config.value?.privacyAgreementUrl ?? '';

  /// EULA URL
  String get eulaUrl => _config.value?.eulaUrl ?? '';

  /// H5 基础地址
  String get springLiveUrl => _config.value?.springLiveUrl ?? '';

  /// 客服邮箱
  String? get customerEmail => _config.value?.customerEmail;

  /// 是否正常运营
  bool get isOperational => _config.value?.isOperational ?? true;

  /// 提现最低金额（配置 key ANCHOR_WITHDRAWAL_MIN_MONEY）
  String get anchorWithdrawalMinMoney => _config.value?.anchorWithdrawalMinMoney ?? '20';

  /// 提现手续费比例（配置 key ANCHOR_WITHDRAWAL_COMMISSION，后台为小数如 "0.04" 表示 4%，展示时 ×100 为百分比）
  String get anchorWithdrawalCommission => _config.value?.anchorWithdrawalCommission ?? '0.05';
}

/// 存储键常量
class StorageKeys {
  static const String appConfig = 'app_config';
}
