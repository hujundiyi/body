import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response, FormData, MultipartFile;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:uuid/uuid.dart';
import 'package:image/image.dart' as img;

import '../constants/app_constants.dart';
import '../services/storage_service.dart';
import '../../routes/app_routes.dart';
import '../services/auth_service.dart';
import 'aes_encrypt.dart';
import 'api_response.dart';
import 'api_exception.dart';
import 'api_interceptor.dart';

/// 公共工厂类（用于存储用户token等）
class CommonFactory {
  static final CommonFactory shared = CommonFactory._();
  CommonFactory._();

  String _uToken = '';
  String get uToken => _uToken;
  set uToken(String value) => _uToken = value;

  Map<String, dynamic> _userInfo = {};
  Map<String, dynamic> get userInfo => _userInfo;
  set userInfo(Map<String, dynamic> value) => _userInfo = value;

  /// 清除用户数据
  void clear() {
    _uToken = '';
    _userInfo = {};
  }
}

/// API 客户端
/// 对应 Swift 版本的 BHIAPIClient
class APIClient extends GetxService {
  static APIClient get shared => Get.find<APIClient>();

  late final Dio _dio;
  Dio get dio => _dio;

  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  String? _deviceId;
  PackageInfo? _packageInfo;

  /// 待上传任务
  final List<PendingUpload> _pendingUploads = [];

  @override
  void onInit() {
    super.onInit();
    _initDio();
    _initDeviceInfo();
  }

  /// 初始化 Dio
  void _initDio() {
    _dio = Dio(
      BaseOptions(
        baseUrl: EnvironmentConfig.baseURL,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
      ),
    );

    // 添加拦截器
    _dio.interceptors.add(APILoggingInterceptor());
  }

  /// 初始化设备信息
  Future<void> _initDeviceInfo() async {
    try {
      _packageInfo = await PackageInfo.fromPlatform();

      if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        _deviceId = iosInfo.identifierForVendor;
      } else if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        _deviceId = androidInfo.id;
      }
    } catch (e) {
      print('获取设备信息失败: $e');
    }
  }

  /// 获取设备 ID
  String getDeviceId() {
    return _deviceId ?? const Uuid().v4().replaceAll('-', '');
  }

  /// 获取应用版本
  String getAppVersion() {
    return _packageInfo?.version ?? AppConstants.appVersion;
  }

  /// 构建请求头
  /// 对应 Swift 版本的 headers
  Map<String, String> _buildHeaders() {
    // X-Request-ID: requestId (UUID去掉-)
    final requestId = const Uuid().v4().replaceAll('-', '');

    // X-Request-Timestamp: 时间戳（秒）
    final timestamp = (DateTime.now().millisecondsSinceEpoch / 1000).floor().toString();

    // X-App-Info: Base64编码的 "包名;版本"
    final appInfo = '${EnvironmentConfig.packageName};${getAppVersion()}';
    final appInfoBase64 = base64Encode(utf8.encode(appInfo));

    // X-Language: 语言信息
    final languageStr = Platform.localeName;

    // X-Region: 国家地区
    final region = Platform.localeName.split('_').last;

    final headers = <String, String>{
      APIHeaderKeys.requestId: requestId,
      APIHeaderKeys.requestTimestamp: timestamp,
      APIHeaderKeys.appInfo: appInfoBase64,
      APIHeaderKeys.language: languageStr,
      APIHeaderKeys.region: region,
      APIHeaderKeys.deviceId: getDeviceId(),
      APIHeaderKeys.appChannel: 'AppStore',
      APIHeaderKeys.contentType: 'application/json;charset=utf-8',
    };

    // Authorization: token (如果有登录用户)
    if (CommonFactory.shared.uToken.isNotEmpty) {
      headers[APIHeaderKeys.authorization] = CommonFactory.shared.uToken;
    }

    return headers;
  }

  /// 加密请求参数
  /// 对应 Swift 版本的 jm 方法
  String _encryptParams(Map<String, dynamic> params) {
    try {
      final jsonString = jsonEncode(params);
      return AESEncrypt.encrypt(jsonString) ?? '';
    } catch (e) {
      print('加密参数失败: $e');
      return '';
    }
  }

  /// 加密数组参数
  String _encryptArrayParams(List<dynamic> params) {
    try {
      final jsonString = jsonEncode(params);
      return AESEncrypt.encrypt(jsonString) ?? '';
    } catch (e) {
      print('加密数组参数失败: $e');
      return '';
    }
  }

  /// 解密响应数据
  /// 对应 Swift 版本的 getOldResponseWithData
  Map<String, dynamic>? decryptResponse(dynamic responseData) {
    if (responseData == null) return null;

    String dataStr;
    if (responseData is String) {
      dataStr = responseData;
    } else if (responseData is List<int>) {
      dataStr = utf8.decode(responseData);
    } else {
      return null;
    }

    // 尝试解密
    final decryptedStr = AESEncrypt.decrypt(dataStr);
    if (decryptedStr != null) {
      try {
        return jsonDecode(decryptedStr) as Map<String, dynamic>;
      } catch (e) {
        print('解析解密后的JSON失败: $e');
      }
    }

    // 解密失败，尝试直接解析
    try {
      return jsonDecode(dataStr) as Map<String, dynamic>;
    } catch (e) {
      print('直接解析JSON失败: $e');
    }

    return null;
  }

  /// 发起请求
  Future<T> request<T>(
    String path, {
    Map<String, dynamic>? params,
    List<dynamic>? arrayParams,
    T Function(dynamic json)? fromJsonT,
  }) async {
    try {
      // 构建请求头
      final headers = _buildHeaders();

      // 加密参数
      String encryptedParams;
      if (arrayParams != null && arrayParams.isNotEmpty) {
        encryptedParams = _encryptArrayParams(arrayParams);
      } else {
        encryptedParams = _encryptParams(params ?? {});
      }

      // 计算签名
      // X-Signature: MD5(data + requestId) 的大写形式
      final requestId = headers[APIHeaderKeys.requestId] ?? '';
      final decryptedData = arrayParams != null && arrayParams.isNotEmpty
          ? jsonEncode(arrayParams)
          : (params != null ? jsonEncode(params) : '');
      final signString = '$decryptedData$requestId';
      final signature = AESEncrypt.md5HashUppercase(signString);
      headers[APIHeaderKeys.signature] = signature;

      // 发起请求
      final response = await _dio.post(
        path,
        data: encryptedParams,
        options: Options(headers: headers),
      );

      // 解密响应
      Map<String, dynamic>? responseData;
      if (response.data is String) {
        responseData = decryptResponse(response.data);
      } else if (response.data is Map<String, dynamic>) {
        responseData = response.data;
      }

      if (responseData == null) {
        throw Exception('Failed to parse response data');
      }

      // 解析响应
      final apiResponse = ApiResponse<T>.fromJson(responseData, fromJsonT);

      if (apiResponse.isSuccess) {
        return apiResponse.data as T;
      } else {
        // code=401 或 403 表示需要重新登录，清除登录态并跳转登录页
        if (apiResponse.code == 401 || apiResponse.code == 403) {
          _handleUnauthorized();
        }
        throw APIException(apiResponse.code, apiResponse.msg);
      }
    } on DioException catch (e) {
      throw APIException.fromDioError(e);
    }
  }

  /// 401/403 时清除登录态并跳转登录页
  void _handleUnauthorized() {
    Future.microtask(() async {
      try {
        final auth = Get.find<AuthService>();
        await auth.logout();
      } catch (_) {}
      if (Get.currentRoute != AppRoutes.anchorLogin) {
        AppRoutes.goToAnchorLogin();
      }
    });
  }

  /// 上传图片
  /// 对应 Swift 版本的 uploadImage
  Future<String> uploadImage(File imageFile) async {
    try {
      // 压缩图片
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) {
        throw Exception('Image decode failed');
      }

      final compressedBytes = img.encodeJpg(image, quality: 80);

      // 生成文件名
      final fileName = '${const Uuid().v4()}${DateTime.now().millisecondsSinceEpoch}.jpg';

      // 1. 获取上传链接
      final uploadResponse = await request<UploadResponse>(
        APIPaths.getUploadUrl,
        params: {'fileName': fileName},
        fromJsonT: (json) => UploadResponse.fromJson(json),
      );

      if (uploadResponse.uploadUrl.isEmpty) {
        throw Exception('Failed to get upload URL');
      }

      // 2. 上传图片
      await _dio.put(
        uploadResponse.uploadUrl,
        data: Stream.fromIterable([compressedBytes]),
        options: Options(headers: {'Content-Type': 'image/jpeg', 'Content-Length': compressedBytes.length}),
      );

      // 3. 返回最终访问链接
      return uploadResponse.url;
    } catch (e) {
      throw Exception('Image upload failed: $e');
    }
  }

  // ============ 重试上传逻辑 ============

  /// 保存待上传任务
  void _savePendingUpload(PendingUpload upload) {
    _pendingUploads.add(upload);
    _persistPendingUploads();
  }

  /// 移除待上传任务
  void _removePendingUpload(PendingUpload upload) {
    _pendingUploads.removeWhere((u) => u.imagePath == upload.imagePath && u.uploadUrl == upload.uploadUrl);
    _persistPendingUploads();

    // 删除本地文件
    try {
      File(upload.imagePath).deleteSync();
    } catch (e) {
      print('删除本地文件失败: $e');
    }
  }

  /// 持久化待上传任务
  void _persistPendingUploads() {
    try {
      final storage = Get.find<StorageService>();
      final json = _pendingUploads.map((u) => u.toJson()).toList();
      storage.setString(AppConstants.keyPendingUploads, jsonEncode(json));
    } catch (e) {
      print('持久化待上传任务失败: $e');
    }
  }

  /// 加载待上传任务
  void loadPendingUploads() {
    try {
      final storage = Get.find<StorageService>();
      final jsonStr = storage.getString(AppConstants.keyPendingUploads);
      if (jsonStr != null) {
        final list = jsonDecode(jsonStr) as List;
        _pendingUploads.clear();
        _pendingUploads.addAll(list.map((e) => PendingUpload.fromJson(e)).toList());
      }
    } catch (e) {
      print('加载待上传任务失败: $e');
    }
  }

  /// 重试待上传任务
  Future<void> retryPendingUploads() async {
    final uploads = List<PendingUpload>.from(_pendingUploads);
    for (final upload in uploads) {
      try {
        final file = File(upload.imagePath);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          await _dio.put(
            upload.uploadUrl,
            data: Stream.fromIterable([bytes]),
            options: Options(headers: {'Content-Type': 'image/jpeg', 'Content-Length': bytes.length}),
          );
          _removePendingUpload(upload);
        } else {
          _removePendingUpload(upload);
        }
      } catch (e) {
        print('重试上传失败: $e');
      }
    }
  }
}
