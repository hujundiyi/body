import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:weeder/core/utils/toast_utils.dart';
import '../../data/models/anchor_model.dart';
import 'storage_service.dart';
import '../network/network.dart';
import '../network/anchor_api_service.dart';
import 'im_service.dart';

/// 认证服务
class AuthService extends GetxService {
  // 存储键
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_info';
  static const String _rtmTokenKey = 'rtm_token';
  static const String _tencentUserSigKey = 'tencent_user_sig';

  final StorageService _storage = Get.find<StorageService>();

  // 认证状态
  final RxBool _isAuthenticated = false.obs;
  bool get isAuthenticated => _isAuthenticated.value;

  // 用户信息
  final Rx<AnchorModel?> _userInfo = Rx<AnchorModel?>(null);
  AnchorModel? get userInfo => _userInfo.value;

  // Token
  String? _token;
  String? get token => _token;

  // RTM Token（声网）
  String? _rtmToken;
  String? get rtmToken => _rtmToken;

  // 腾讯 IM UserSig
  String? _tencentUserSig;
  String? get tencentUserSig => _tencentUserSig;

  @override
  void onInit() {
    super.onInit();
    _loadAuthData();
  }

  /// 加载认证数据
  Future<void> _loadAuthData() async {
    _token = _storage.getString(_tokenKey);
    _rtmToken = _storage.getString(_rtmTokenKey);
    _tencentUserSig = _storage.getString(_tencentUserSigKey);
    final userInfoString = _storage.getString(_userKey);

    if (_token != null && _token!.isNotEmpty) {
      try {
        // 解析用户信息
        if (userInfoString != null && userInfoString.isNotEmpty) {
          final Map<String, dynamic> userJson = jsonDecode(userInfoString);
          _userInfo.value = AnchorModel.fromJson(userJson);
        }

        _isAuthenticated.value = true;

        // 恢复 token 到 CommonFactory
        CommonFactory.shared.uToken = _token!;

        debugPrint('认证数据加载成功: userId=${_userInfo.value?.userId}');

        // 自动登录腾讯 IM
        _autoLoginIM();
      } catch (e) {
        debugPrint('加载认证数据失败: $e');
        _clearAuthData();
      }
    }
  }

  /// 自动登录腾讯 IM
  Future<void> _autoLoginIM() async {
    if (_userInfo.value != null && _tencentUserSig != null && _tencentUserSig!.isNotEmpty) {
      final userId = _userInfo.value!.userId.toString();
      debugPrint('自动登录腾讯 IM: userId=$userId');

      try {
        final imService = Get.find<IMService>();
        await imService.initAndAutoLogin(userID: userId, userSig: _tencentUserSig!);
      } catch (e) {
        debugPrint('自动登录腾讯 IM 失败: $e');
      }
    }
  }

  /// 用户登录
  Future<bool> login({required String username, required String password}) async {
    try {
      final anchor = await AnchorAPIService.shared.anchorLogin(
        email: username,
        password: password,
      );

      _userInfo.value = anchor;

      // 提取 Token
      _token = anchor.token;
      _rtmToken = anchor.rtmToken;
      _tencentUserSig = anchor.tencentUserSig;

      // 保存到本地存储
      await _saveAuthData(anchor);

      _isAuthenticated.value = true;

      // 登录腾讯 IM
      _autoLoginIM();

      return true;
    } on APIException catch (e) {
      // 延后到 loading 关闭后再弹 Toast，否则会被 executeWithLoading 的遮罩挡住或一起被关掉
      final msg = e.message;
      ToastUtils.showInfo(msg);
      return false;
    } catch (e) {
      debugPrint('登录失败: $e');
      ToastUtils.showError(e.toString());
      return false;
    }
  }

  /// 保存主播登录后的数据到本地
  Future<void> saveAnchorData(AnchorModel anchor) async {
    _userInfo.value = anchor;
    _token = anchor.token;
    _rtmToken = anchor.rtmToken;
    _tencentUserSig = anchor.tencentUserSig;

    await _saveAuthData(anchor);

    _isAuthenticated.value = true;

    // 登录腾讯 IM
    _autoLoginIM();
  }

  /// 保存认证数据到本地
  Future<void> _saveAuthData(AnchorModel user) async {
    // 保存 Token
    if (user.token != null && user.token!.isNotEmpty) {
      await _storage.setString(_tokenKey, user.token!);
      CommonFactory.shared.uToken = user.token!;
    }

    // 单独保存 rtmToken
    if (user.rtmToken != null && user.rtmToken!.isNotEmpty) {
      await _storage.setString(_rtmTokenKey, user.rtmToken!);
    }

    // 单独保存 tencentUserSig
    if (user.tencentUserSig != null && user.tencentUserSig!.isNotEmpty) {
      await _storage.setString(_tencentUserSigKey, user.tencentUserSig!);
    }

    // 保存用户信息 JSON
    await _storage.setString(_userKey, jsonEncode(user.toJson()));

    debugPrint('认证数据保存成功: userId=${user.userId}');
  }

  /// 用户注册
  Future<AnchorModel?> register({required String email, required String password, String? invitationCode}) async {
    try {
      final params = {
        'loginNo': email,
        'password': password,
        'type': 'EMAIL_REGISTER',
      };
      if (invitationCode != null && invitationCode.isNotEmpty) {
        params['invitationCode'] = invitationCode;
      }
      final response = await UserAPIService.shared.login(params);
      
      // 将返回的数据转换为 AnchorModel
      final anchor = AnchorModel.fromJson(response);
      
      _userInfo.value = anchor;
      
      // 提取 Token
      _token = anchor.token;
      _rtmToken = anchor.rtmToken;
      _tencentUserSig = anchor.tencentUserSig;
      
      // 保存到本地存储
      await _saveAuthData(anchor);
      
      _isAuthenticated.value = true;
      
      // 登录腾讯 IM
      _autoLoginIM();
      
      return anchor;
    } on APIException catch (e) {
      debugPrint('注册失败: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('注册失败: $e');
      return null;
    }
  }

  /// 用户登出
  Future<void> logout() async {
    debugPrint('登出中...');
    try {
      // 登出腾讯 IM
      final imService = Get.find<IMService>();
      await imService.logout();
    } catch (e) {
      debugPrint('IM 登出失败: $e');
    }

    // 清理数据
    await _clearAuthData();
    debugPrint('登出完成');
  }

  /// 清除认证数据
  Future<void> _clearAuthData() async {
    _token = null;
    _rtmToken = null;
    _tencentUserSig = null;
    _userInfo.value = null;
    _isAuthenticated.value = false;

    // 清除 CommonFactory 中的 token
    CommonFactory.shared.clear();

    // 清除本地存储
    await _storage.remove(_tokenKey);
    await _storage.remove(_userKey);
    await _storage.remove(_rtmTokenKey);
    await _storage.remove(_tencentUserSigKey);
  }

  /// 检查Token是否有效
  Future<bool> checkTokenValidity() async {
    if (_token == null || _token!.isEmpty) return false;

    try {
      await UserAPIService.shared.getUserInfo({});
      return true;
    } on APIException {
      await _clearAuthData();
      return false;
    } catch (e) {
      await _clearAuthData();
      return false;
    }
  }

  /// 更新用户信息
  Future<bool> updateUserInfo(AnchorModel updatedUser) async {
    try {
      _userInfo.value = updatedUser;
      await _storage.setString(_userKey, jsonEncode(updatedUser.toJson()));
      return true;
    } on APIException catch (e) {
      debugPrint('更新用户信息失败: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('更新用户信息失败: $e');
      return false;
    }
  }

  /// 将拉取到的主播信息保存到本地（保留当前 token/rtmToken/tencentUserSig，供 getAnchorInfo 拉取后调用）
  Future<void> saveAnchorInfo(AnchorModel anchor) async {
    final current = _userInfo.value;
    final AnchorModel toSave = (current != null &&
            (anchor.token == null || anchor.token!.isEmpty))
        ? anchor.copyWith(
            token: current.token,
            rtmToken: current.rtmToken,
            tencentUserSig: current.tencentUserSig,
          )
        : anchor;
    _userInfo.value = toSave;
    await _saveAuthData(toSave);
  }

  /// 从接口拉取用户资料详情并更新本地（含 following、follower 等），保留 token 等鉴权信息
  Future<void> refreshUserProfile() async {
    try {
      final anchor = await AnchorAPIService.shared.getAnchorInfo();
      final current = _userInfo.value;
      final AnchorModel toSave = (current != null &&
              (anchor.token == null || anchor.token!.isEmpty))
          ? anchor.copyWith(
              token: current.token,
              rtmToken: current.rtmToken,
              tencentUserSig: current.tencentUserSig,
            )
          : anchor;
      await updateUserInfo(toSave);
    } catch (e) {
      debugPrint('刷新用户资料失败: $e');
    }
  }

  /// 更新 RTM Token
  Future<void> updateRtmToken(String rtmToken) async {
    _rtmToken = rtmToken;
    await _storage.setString(_rtmTokenKey, rtmToken);
  }

  /// 更新腾讯 UserSig
  Future<void> updateTencentUserSig(String userSig) async {
    _tencentUserSig = userSig;
    await _storage.setString(_tencentUserSigKey, userSig);

    // 重新登录腾讯 IM
    _autoLoginIM();
  }

  /// 获取用户 ID
  int get userId => _userInfo.value?.userId ?? 0;

  /// 获取用户昵称
  String get nickname => _userInfo.value?.nickname ?? '';

  /// 获取用户头像
  String get avatar => _userInfo.value?.avatar ?? '';

}
