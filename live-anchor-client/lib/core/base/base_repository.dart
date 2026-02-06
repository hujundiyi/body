import 'package:get/get.dart';
import '../network/network.dart';

/// 基础仓库类
/// 提供通用的网络请求和数据处理方法
abstract class BaseRepository {
  /// API 客户端
  APIClient get apiClient => APIClient.shared;

  /// 用户 API 服务
  UserAPIService get userAPI => UserAPIService.shared;

  /// 首页 API 服务
  HomeAPIService get homeAPI => HomeAPIService.shared;

  /// 产品 API 服务
  ProductAPIService get productAPI => ProductAPIService.shared;

  /// 钱包 API 服务
  WalletAPIService get walletAPI => WalletAPIService.shared;

  /// 配置 API 服务
  ConfigAPIService get configAPI => ConfigAPIService.shared;

  /// 上传 API 服务
  UploadAPIService get uploadAPI => UploadAPIService.shared;

  /// 处理 API 异常
  String handleAPIException(dynamic error) {
    if (error is APIException) {
      return error.message;
    }
    return 'Unknown error: $error';
  }

  /// 安全执行 API 请求
  Future<T?> safeRequest<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on APIException catch (e) {
      print('API 请求失败: ${e.message}');
      return null;
    } catch (e) {
      print('请求异常: $e');
      return null;
    }
  }
}

/// 用户仓库
class UserRepository extends BaseRepository {
  static UserRepository get instance => Get.find<UserRepository>();

  /// 登录
  Future<Map<String, dynamic>?> login({
    required String username,
    required String password,
  }) async {
    return await safeRequest(() => userAPI.login({
          'username': username,
          'password': password,
        }));
  }

  /// 获取用户信息
  Future<Map<String, dynamic>?> getUserInfo() async {
    return await safeRequest(() => userAPI.getUserInfo({}));
  }

  /// 更新用户信息
  Future<Map<String, dynamic>?> updateUserInfo(
      Map<String, dynamic> info) async {
    return await safeRequest(() => userAPI.updateInfo(info));
  }

  /// 删除账户
  Future<bool> deleteAccount() async {
    final result = await safeRequest(() => userAPI.deleteAccount());
    return result != null;
  }
}

/// 首页仓库
class HomeRepository extends BaseRepository {
  static HomeRepository get instance => Get.find<HomeRepository>();

  /// 获取首页列表
  Future<Map<String, dynamic>?> getHomeList({
    int page = 1,
    int pageSize = 20,
  }) async {
    return await safeRequest(() => homeAPI.getHomeList({
          'page': page,
          'pageSize': pageSize,
        }));
  }
}

/// 产品仓库
class ProductRepository extends BaseRepository {
  static ProductRepository get instance => Get.find<ProductRepository>();

  /// 获取产品列表
  Future<Map<String, dynamic>?> getProducts() async {
    return await safeRequest(() => productAPI.getProducts({}));
  }
}

/// 钱包仓库
class WalletRepository extends BaseRepository {
  static WalletRepository get instance => Get.find<WalletRepository>();

  /// 获取钱包余额
  Future<Map<String, dynamic>?> getWalletBalance() async {
    return await safeRequest(() => walletAPI.getWalletBalance());
  }

  /// 充值
  Future<Map<String, dynamic>?> recharge(Map<String, dynamic> params) async {
    return await safeRequest(() => walletAPI.recharge(params));
  }

  /// 验证订单
  Future<Map<String, dynamic>?> verifyOrder(Map<String, dynamic> params) async {
    return await safeRequest(() => walletAPI.verifyOrder(params));
  }

  /// 扣款
  Future<Map<String, dynamic>?> deduction(Map<String, dynamic> params) async {
    return await safeRequest(() => walletAPI.deduction(params));
  }
}

/// 配置仓库
class ConfigRepository extends BaseRepository {
  static ConfigRepository get instance => Get.find<ConfigRepository>();

  /// 获取配置
  Future<Map<String, dynamic>?> getConfiguration() async {
    return await safeRequest(() => configAPI.getConfiguration({}));
  }
}
