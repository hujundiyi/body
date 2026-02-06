import 'dart:io';
import 'package:weeder/data/models/user_model_entity.dart';

import '../constants/app_constants.dart';
import 'api_client.dart';
import 'api_response.dart';

/// 用户 API 服务
class UserAPIService {
  static final UserAPIService shared = UserAPIService._();
  UserAPIService._();

  APIClient get _client => APIClient.shared;

  /// 登录
  Future<Map<String, dynamic>> login(Map<String, dynamic> params) async {
    return await _client.request<Map<String, dynamic>>(
      APIPaths.anchorLogin,
      params: params,
      fromJsonT: (json) => json as Map<String, dynamic>,
    );
  }

  /// 获取用户信息
  Future<Map<String, dynamic>> getUserInfo(Map<String, dynamic> params) async {
    return await _client.request<Map<String, dynamic>>(
      APIPaths.getUserInfo,
      params: params,
      fromJsonT: (json) => json as Map<String, dynamic>,
    );
  }

  /// 根据 ID 列表获取用户信息
  Future<List<dynamic>> getUserInfoByIds(List<String> accountIds) async {
    return await _client.request<List<dynamic>>(
      APIPaths.getUserInfoByIds,
      params: {'accountIds': accountIds},
      fromJsonT: (json) => json as List<dynamic>,
    );
  }

  /// 编辑用户信息
  Future<Map<String, dynamic>> editInfo(Map<String, dynamic> params) async {
    return await _client.request<Map<String, dynamic>>(
      APIPaths.editInfo,
      params: params,
      fromJsonT: (json) => json as Map<String, dynamic>,
    );
  }

  /// 更新用户信息
  Future<Map<String, dynamic>> updateInfo(Map<String, dynamic> params) async {
    return await _client.request<Map<String, dynamic>>(
      APIPaths.updateInfo,
      params: params,
      fromJsonT: (json) => json as Map<String, dynamic>,
    );
  }

  /// 删除账户
  Future<Map<String, dynamic>> deleteAccount() async {
    return await _client.request<Map<String, dynamic>>(
      APIPaths.deleteAccount,
      params: {},
      fromJsonT: (json) => json as Map<String, dynamic>,
    );
  }

  /// 获取会员信息
  Future<Map<String, dynamic>> getPremiumInfo(
      Map<String, dynamic> params) async {
    return await _client.request<Map<String, dynamic>>(
      APIPaths.premiumInfo,
      params: params,
      fromJsonT: (json) => json as Map<String, dynamic>,
    );
  }

  /// 获取用户列表
  Future<List<UserModelEntity>> getUserList(Map<String, dynamic> params) async {
    return await _client.request<List<UserModelEntity>>(
      APIPaths.getUserList,
      params: params,
      fromJsonT: (json) => (json as List)
          .map((e) => UserModelEntity.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// 用户详情（user/getInfo，Swagger）
  /// [userId] 用户 ID
  Future<UserModelEntity> getUserDetail(int userId) async {
    final response = await _client.request<Map<String, dynamic>>(
      APIPaths.userGetInfo,
      params: {'userId': userId},
      fromJsonT: (json) => json as Map<String, dynamic>,
    );
    return UserModelEntity.fromJson(response);
  }
}

/// 首页 API 服务
class HomeAPIService {
  static final HomeAPIService shared = HomeAPIService._();
  HomeAPIService._();

  APIClient get _client => APIClient.shared;

  /// 获取首页列表
  Future<Map<String, dynamic>> getHomeList(Map<String, dynamic> params) async {
    return await _client.request<Map<String, dynamic>>(
      APIPaths.getHomeList,
      params: params,
      fromJsonT: (json) => json as Map<String, dynamic>,
    );
  }
}

/// 产品 API 服务
class ProductAPIService {
  static final ProductAPIService shared = ProductAPIService._();
  ProductAPIService._();

  APIClient get _client => APIClient.shared;

  /// 获取产品列表
  Future<Map<String, dynamic>> getProducts(Map<String, dynamic> params) async {
    return await _client.request<Map<String, dynamic>>(
      APIPaths.product,
      params: params,
      fromJsonT: (json) => json as Map<String, dynamic>,
    );
  }
}

/// 钱包 API 服务
class WalletAPIService {
  static final WalletAPIService shared = WalletAPIService._();
  WalletAPIService._();

  APIClient get _client => APIClient.shared;

  /// 充值
  Future<Map<String, dynamic>> recharge(Map<String, dynamic> params) async {
    return await _client.request<Map<String, dynamic>>(
      APIPaths.recharge,
      params: params,
      fromJsonT: (json) => json as Map<String, dynamic>,
    );
  }

  /// 验证订单
  Future<Map<String, dynamic>> verifyOrder(Map<String, dynamic> params) async {
    return await _client.request<Map<String, dynamic>>(
      APIPaths.verifyOrder,
      params: params,
      fromJsonT: (json) => json as Map<String, dynamic>,
    );
  }

  /// 获取钱包余额
  Future<Map<String, dynamic>> getWalletBalance() async {
    return await _client.request<Map<String, dynamic>>(
      APIPaths.walletBalance,
      params: {},
      fromJsonT: (json) => json as Map<String, dynamic>,
    );
  }

  /// 扣款
  Future<Map<String, dynamic>> deduction(Map<String, dynamic> params) async {
    return await _client.request<Map<String, dynamic>>(
      APIPaths.deduction,
      params: params,
      fromJsonT: (json) => json as Map<String, dynamic>,
    );
  }
}

/// 配置 API 服务
class ConfigAPIService {
  static final ConfigAPIService shared = ConfigAPIService._();
  ConfigAPIService._();

  APIClient get _client => APIClient.shared;

  /// 获取配置
  Future<Map<String, dynamic>> getConfiguration(
      Map<String, dynamic> params) async {
    return await _client.request<Map<String, dynamic>>(
      APIPaths.configuration,
      params: params,
      fromJsonT: (json) => json as Map<String, dynamic>,
    );
  }
}

/// 上传 API 服务
class UploadAPIService {
  static final UploadAPIService shared = UploadAPIService._();
  UploadAPIService._();

  APIClient get _client => APIClient.shared;

  /// 获取上传链接
  Future<UploadResponse> getUploadUrl(Map<String, dynamic> params) async {
    return await _client.request<UploadResponse>(
      APIPaths.getUploadUrl,
      params: params,
      fromJsonT: (json) => UploadResponse.fromJson(json),
    );
  }

  /// 上传图片
  Future<String> uploadImage(File imageFile) async {
    return await _client.uploadImage(imageFile);
  }
}

/// 消息 API 服务
class MessageAPIService {
  static final MessageAPIService shared = MessageAPIService._();
  MessageAPIService._();

  APIClient get _client => APIClient.shared;

  /// 发送消息（通用）
  Future<Map<String, dynamic>> sendMessage(Map<String, dynamic> params) async {
    return await _client.request<Map<String, dynamic>>(
      APIPaths.messageSend,
      params: params,
      fromJsonT: (json) => json as Map<String, dynamic>,
    );
  }

  /// 翻译消息
  Future<Map<String, dynamic>> translateMessage(Map<String, dynamic> params) async {
    return await _client.request<Map<String, dynamic>>(
      APIPaths.messageTranslation,
      params: params,
      fromJsonT: (json) => json as Map<String, dynamic>,
    );
  }
}
