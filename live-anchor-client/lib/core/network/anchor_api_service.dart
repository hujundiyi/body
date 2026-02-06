import 'dart:io';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import '../constants/app_constants.dart';
import 'api_client.dart';
import '../services/auth_service.dart';
import '../../data/models/anchor_model.dart';
import '../../data/models/commission_model.dart';
import '../../data/models/say_hi_model.dart';
import '../../data/models/call_history_model.dart';
import '../../data/models/ranking_model.dart';
import '../../data/models/file_upload_model.dart';
import '../../data/models/dict_model.dart';
import '../../data/models/picture_list_model.dart';
import '../../data/models/video_list_model.dart';
import '../../data/models/app_update_model.dart';

/// 主播 API 服务
class AnchorAPIService {
  static final AnchorAPIService shared = AnchorAPIService._();
  AnchorAPIService._();

  APIClient get _client => APIClient.shared;

  // ==================== 登录注册 ====================

  /// 主播登录
  Future<AnchorModel> anchorLogin({required String email, required String password, String? invitationCode}) async {
    final request = AnchorLoginRequest(
      // type: Platform.isIOS ? 'IOS' : 'ANDROID',
      type: 'EMAIL_LOGIN',
      loginNo: email,
      password: password,
      invitationCode: invitationCode,
    );

    final response = await _client.request<Map<String, dynamic>>(
      APIPaths.anchorLogin,
      params: request.toJson(),
      fromJsonT: (json) => json as Map<String, dynamic>,
    );

    final anchor = AnchorModel.fromJson(response);

    // 保存 token
    if (anchor.token != null && anchor.token!.isNotEmpty) {
      CommonFactory.shared.uToken = anchor.token!;
    }

    return anchor;
  }

  /// 获取主播资料（拉取后会自动保存到 AuthService 本地）
  Future<AnchorModel> getAnchorInfo() async {
    final response = await _client.request<Map<String, dynamic>>(
      APIPaths.getAnchorInfo,
      params: {},
      fromJsonT: (json) => json as Map<String, dynamic>,
    );
    final anchor = AnchorModel.fromJson(response);
    if (Get.isRegistered<AuthService>()) {
      await Get.find<AuthService>().saveAnchorInfo(anchor);
    }
    return anchor;
  }

  /// 退出登录
  Future<void> loginOut() async {
    await _client.request<Map<String, dynamic>>(
      APIPaths.loginOut,
      params: {},
      fromJsonT: (json) => json as Map<String, dynamic>,
    );
    CommonFactory.shared.clear();
  }

  /// 进入首页时上报 authorize/toHome，不传参
  Future<void> toHome() async {
    await _client.request<dynamic>(APIPaths.toHome, params: {}, fromJsonT: (json) => json);
  }

  /// 修改密码（成功时 data 可能为 null，不强制解析为 Map）
  Future<void> changePassword({required String oldPassword, required String newPassword}) async {
    final request = ChangePasswordRequest(oldPassword: oldPassword, password: newPassword);
    await _client.request<dynamic>(APIPaths.changePassword, params: request.toJson(), fromJsonT: (json) => json);
  }

  // ==================== 主播资料 ====================

  /// 提交或修改主播资料
  Future<void> setAnchorInfo(AnchorSetInfoRequest request) async {
    // 即使 data 为 null，只要接口请求成功（code == 200），就认为成功
    await _client.request<dynamic>(
      APIPaths.anchorSetInfo,
      params: request.toJson(),
      fromJsonT: (json) => json, // 允许 data 为 null
    );
  }

  /// 获取主播详情（通过userId）
  Future<AnchorModel> getAnchorDetailInfo(int userId) async {
    final response = await _client.request<Map<String, dynamic>>(
      APIPaths.anchorGetInfo,
      params: {'userId': userId},
      fromJsonT: (json) => json as Map<String, dynamic>,
    );
    return AnchorModel.fromJson(response);
  }

  // ==================== 主播工作台 ====================

  /// 获取工作统计报表
  Future<WorkReport> getWorkReport({DateTime? filterTime}) async {
    final params = <String, dynamic>{};
    if (filterTime != null) {
      // 转换为秒级时间戳
      params['filterTime'] = filterTime.millisecondsSinceEpoch ~/ 1000;
    }

    final response = await _client.request<Map<String, dynamic>>(
      APIPaths.getWorkReport,
      params: params,
      fromJsonT: (json) => json as Map<String, dynamic>,
    );
    return WorkReport.fromJson(response);
  }

  /// 获取佣金记录
  /// [page] 从 1 开始；[filterTimeStamp] 传 bill_page 请求下来的 month 字段值（秒级时间戳）
  Future<List<CommissionRecord>> getCommissionList({
    required int page,
    required int size,
    DateTime? filterTime,
    int? filterTimeStamp,
    List<int>? coinChangeType,
  }) async {
    final request = GetCommissionListRequest(
      page: page,
      size: size,
      filterTime: filterTime,
      filterTimeStamp: filterTimeStamp,
      coinChangeType: coinChangeType,
    );

    final response = await _client.request<List<dynamic>>(
      APIPaths.getCommissionList,
      params: request.toJson(),
      fromJsonT: (json) => json as List<dynamic>,
    );

    return response.map((e) => CommissionRecord.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// 获取月度账单
  Future<List<MonthCommission>> getMonthCommissionList({required int page, required int size}) async {
    final response = await _client.request<List<dynamic>>(
      APIPaths.getMonthCommissionList,
      params: {'page': page, 'size': size},
      fromJsonT: (json) => json as List<dynamic>,
    );

    return response.map((e) => MonthCommission.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// 获取实际到账金额
  Future<ActualAmountReceived> getActualAmountReceived({required int payType, required double money}) async {
    final response = await _client.request<Map<String, dynamic>>(
      APIPaths.getActualAmountReceived,
      params: {'payType': payType, 'money': money},
      fromJsonT: (json) => json as Map<String, dynamic>,
    );
    return ActualAmountReceived.fromJson(response);
  }

  /// 提现申请
  Future<void> withdrawal(WithdrawalRequest request) async {
    await _client.request<Map<String, dynamic>>(
      APIPaths.withdrawal,
      params: request.toJson(),
      fromJsonT: (json) => json as Map<String, dynamic>,
    );
  }

  // ==================== 通话记录 ====================

  /// 获取通话历史
  Future<List<CallHistory>> getCallHistory({required int page, required int size, int? callType}) async {
    final request = GetCallHistoryRequest(page: page, size: size, callType: callType);

    final response = await _client.request<List<dynamic>>(
      APIPaths.getCallHistory,
      params: request.toJson(),
      fromJsonT: (json) => json as List<dynamic>,
    );

    return response.map((e) => CallHistory.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ==================== 排行榜 ====================

  /// 获取用户排行榜（财富榜）
  Future<List<RankingUser>> getUserRankingList({
    required int page,
    required int size,
    required String timeType,
    required int type,
    int? isSelfRanking,
  }) async {
    final request = UserRankingRequest(
      page: page,
      size: size,
      timeType: timeType,
      type: type,
      isSelfRanking: isSelfRanking,
    );

    final response = await _client.request<List<dynamic>>(
      APIPaths.userRankingList,
      params: request.toJson(),
      fromJsonT: (json) => json as List<dynamic>,
    );

    return response.map((e) => RankingUser.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// 获取主播排行榜
  Future<List<RankingUser>> getAnchorRankingList({
    required int page,
    required int size,
    required String timeType,
    required int type,
  }) async {
    final request = AnchorRankingRequest(page: page, size: size, timeType: timeType, type: type);

    final response = await _client.request<List<dynamic>>(
      APIPaths.anchorRankingList,
      params: request.toJson(),
      fromJsonT: (json) => json as List<dynamic>,
    );

    return response.map((e) => RankingUser.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ==================== 文件上传 ====================

  /// 获取单文件上传地址 system/getPutFileUrl
  /// 请求参数：type（如 "video"、"picture"）、fileName、contentLength（文件大小字节）
  /// 返回 preUrl 用于 PUT 上传，url 为上传后的访问地址
  Future<FileUploadResponse> getPutFileUrl({
    required String type,
    required String fileName,
    required int contentLength,
  }) async {
    final request = FileUploadRequest(type: type, fileName: fileName, contentLength: contentLength);
    final response = await _client.request<Map<String, dynamic>>(
      APIPaths.getPutFileUrl,
      params: request.toJson(),
      fromJsonT: (json) => json as Map<String, dynamic>,
    );
    return FileUploadResponse.fromJson(response);
  }

  /// 获取多文件上传地址
  /// [files] 文件列表，每个文件需要提供文件名和大小
  /// [type] 业务类型，默认为 "picture"
  Future<List<FileUploadResponse>> getPutFileUrls({required List<File> files, String type = 'picture'}) async {
    // 构建请求参数数组，每个元素包含 type、fileName、contentLength
    final items = await Future.wait(
      files.map((file) async {
        // 生成文件名（如果路径中没有合适的文件名，使用时间戳）
        String fileName = file.path.split('/').last;
        if (fileName.isEmpty || !fileName.contains('.')) {
          fileName = 'anchor_${DateTime.now().millisecondsSinceEpoch}_${files.indexOf(file)}.jpg';
        }
        final contentLength = await file.length();
        return BatchFileUploadItem(type: type, fileName: fileName, contentLength: contentLength);
      }),
    );

    final request = BatchFileUploadRequest(files: items);

    // 使用 arrayParams 传递数组参数
    final response = await _client.request<List<dynamic>>(
      APIPaths.getPutFileUrls,
      arrayParams: request.toJson(),
      fromJsonT: (json) => json as List<dynamic>,
    );

    return response.map((e) => FileUploadResponse.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// 上传文件到指定URL
  Future<String> uploadFileToUrl(File file, String putUrl) async {
    final bytes = await file.readAsBytes();

    await _client.dio.put(
      putUrl,
      data: Stream.fromIterable([bytes]),
      options: Options(headers: {'Content-Type': _getContentType(file.path), 'Content-Length': bytes.length}),
    );

    // 返回访问URL（去掉查询参数）
    final uri = Uri.parse(putUrl);
    return '${uri.scheme}://${uri.host}${uri.path}';
  }

  String _getContentType(String path) {
    final ext = path.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'mp4':
        return 'video/mp4';
      case 'mp3':
        return 'audio/mpeg';
      default:
        return 'application/octet-stream';
    }
  }

  // ==================== 用户状态 ====================

  /// 获取关注列表 userStatus/getFollowList
  /// [follow] true=我关注的(Following)，false=关注我的(Followers)
  Future<List<Map<String, dynamic>>> getFollowList({required int page, required int size, required bool follow}) async {
    final raw = await _client.request<dynamic>(
      APIPaths.getFollowList,
      params: {'page': page, 'size': size, 'follow': follow},
      fromJsonT: (json) => json,
    );
    if (raw == null) return [];
    final list = raw is List
        ? raw
        : (raw is Map && raw['records'] != null)
        ? (raw['records'] as List)
        : (raw is Map && raw['list'] != null)
        ? (raw['list'] as List)
        : (raw is Map && raw['data'] != null)
        ? (raw['data'] is List
              ? (raw['data'] as List)
              : (raw['data'] is Map && (raw['data'] as Map)['records'] != null)
              ? ((raw['data'] as Map)['records'] as List)
              : (raw['data'] is Map && (raw['data'] as Map)['list'] != null)
              ? ((raw['data'] as Map)['list'] as List)
              : <dynamic>[])
        : <dynamic>[];
    return list.map((e) => e as Map<String, dynamic>).toList();
  }

  /// 关注/取消关注 userStatus/followStatus
  /// 参数参照 Swagger：followUserId 被关注用户 id，follow true=关注 false=取消关注
  /// 返回 data：2 或 3=已关注，否则=未关注
  Future<int?> followStatus({required int followUserId, required bool follow}) async {
    final raw = await _client.request<dynamic>(
      APIPaths.followStatus,
      params: {'followUserId': followUserId, 'follow': follow},
      fromJsonT: (json) => json,
    );
    if (raw == null) return null;
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return null;
  }

  /// 获取拉黑列表
  Future<List<Map<String, dynamic>>> getBlackList({required int page, required int size}) async {
    final response = await _client.request<List<dynamic>>(
      APIPaths.getBlackList,
      params: {'page': page, 'size': size},
      fromJsonT: (json) => json as List<dynamic>,
    );
    return response.cast<Map<String, dynamic>>();
  }

  /// 拉黑/取消拉黑 userStatus/blackStatus
  /// 参数：blackUserId 对方用户 id，black true=拉黑 false=取消拉黑
  /// 返回 data：1 或 3 表示拉黑对方成功（支持 data 为数字、字符串 "3" 或对象）
  Future<int?> blackStatus({required int blackUserId, required bool black}) async {
    final raw = await _client.request<dynamic>(
      APIPaths.blackStatus,
      params: {'blackUserId': blackUserId, 'black': black},
      fromJsonT: (json) => json,
    );
    if (raw == null) return null;
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is String) {
      final n = int.tryParse(raw.trim());
      if (n != null) return n;
    }
    if (raw is Map) {
      final v = raw['status'] ?? raw['value'] ?? raw['data'];
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) {
        final n = int.tryParse(v.trim());
        if (n != null) return n;
      }
    }
    return null;
  }

  /// 举报用户 user/reportUser
  /// 成功以 code==200 为准，data 可能为 null，不解析 data 避免强转异常
  /// [reportType] 举报类型（字典 report_type 的 value）
  /// [reportedType] 固定 "USER_INFO"
  /// [reportedId] 被举报人用户 id
  Future<void> reportUser({required int reportType, required String reportedType, required int reportedId}) async {
    await _client.request<dynamic>(
      APIPaths.userReport,
      params: {'reportType': reportType, 'reportedType': reportedType, 'reportedId': reportedId},
      fromJsonT: (json) => json,
    );
  }

  // ==================== 初始化配置 ====================

  /// 获取字典
  /// [dictTypes] 字典类型列表，如 ["country", "gender", "anchor_self_tags"]
  /// 返回字典数据列表
  Future<List<DictResponse>> getDict(List<String> dictTypes) async {
    final response = await _client.request<List<dynamic>>(
      APIPaths.getDict,
      params: {'dictTypes': dictTypes},
      fromJsonT: (json) => json as List<dynamic>,
    );

    return response.map((e) => DictResponse.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// 获取配置
  Future<Map<String, dynamic>> getConfig() async {
    final response = await _client.request<Map<String, dynamic>>(
      APIPaths.getConfig,
      params: {},
      fromJsonT: (json) => json as Map<String, dynamic>,
    );
    return response;
  }

  /// 获取应用更新信息 init/getAppUpdate，不传参；code=200 且 data 有内容时返回模型，否则返回 null
  Future<AppUpdateModel?> getAppUpdate() async {
    try {
      final response = await _client.request<AppUpdateModel?>(
        APIPaths.getAppUpdate,
        params: {},
        fromJsonT: (json) {
          if (json == null) return null;
          if (json is Map<String, dynamic>) return AppUpdateModel.fromJson(json);
          return null;
        },
      );
      return response;
    } catch (_) {
      return null;
    }
  }

  // ==================== Say Hi 消息 ====================

  /// 获取Say Hi消息列表
  Future<List<SayHiMessage>> getSayHiMessage() async {
    final response = await _client.request<List<dynamic>>(
      APIPaths.getSayHiMessage,
      params: {},
      fromJsonT: (json) => json as List<dynamic>,
    );
    return response.map((e) => SayHiMessage.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// 添加Say Hi消息
  /// 注意：此接口成功时返回 code == 200，但 data 可能为 null
  Future<void> addSayHiMessage(AddSayHiMessageRequest request) async {
    await _client.request<dynamic>(
      APIPaths.addSayHiMessage,
      params: request.toJson(),
      fromJsonT: (json) => json, // 允许 data 为 null
    );
  }

  /// 删除Say Hi消息
  /// 注意：此接口成功时返回 code == 200，但 data 可能为 null
  Future<void> delSayHiMessage(int id) async {
    final request = DelSayHiMessageRequest(id: id);
    await _client.request<dynamic>(
      APIPaths.delSayHiMessage,
      params: request.toJson(),
      fromJsonT: (json) => json, // 允许 data 为 null
    );
  }

  /// 设置 Say Hi 消息为默认
  Future<void> setSayHiMessageDefault(int id) async {
    final request = SetSayHiMessageDefaultRequest(id: id);
    await _client.request<dynamic>(
      APIPaths.setSayHiMessageDefault,
      params: request.toJson(),
      fromJsonT: (json) => json,
    );
  }

  // ==================== 主播任务 ====================

  /// 用户反馈（user/feedback）
  /// 参数按 Swagger FeedbackReq：feedbackType(字典feedback_type)、reason(反馈文案,最大200)、contactEmail(联系邮箱)、imgUrl(可选,多图逗号分割)
  /// 成功：code=200 即视为成功
  Future<void> userFeedback({
    required int feedbackType,
    required String reason,
    String? contactEmail,
    String? imgUrl,
  }) async {
    final params = <String, dynamic>{'feedbackType': feedbackType, 'reason': reason};
    if (contactEmail != null && contactEmail.isNotEmpty) {
      params['contactEmail'] = contactEmail;
    }
    if (imgUrl != null && imgUrl.isNotEmpty) {
      params['imgUrl'] = imgUrl;
    }
    await _client.request<dynamic>(APIPaths.userFeedback, params: params, fromJsonT: (json) => json);
  }

  /// 获取任务 H5 页面 URL（如 Work Rules 等）
  /// 返回 data 为字符串 URL，或 data.url
  Future<String?> getTaskH5Url() async {
    final data = await _client.request<dynamic>(APIPaths.anchorTaskH5Url, params: {}, fromJsonT: (json) => json);
    if (data == null) return null;
    if (data is String) return data.isNotEmpty ? data : null;
    if (data is Map<String, dynamic>) {
      final url = data['url'] ?? data['h5Url'];
      return url is String && url.isNotEmpty ? url : null;
    }
    return null;
  }

  // ==================== 图集 / 视频列表 ====================

  /// 获取照片列表 picture/getList
  /// [userId] 必传，当前用户 userId
  /// [type] 0: Daily Photos, 1: Sexy Photos
  Future<List<PictureListItem>> getPictureList({
    required int userId,
    int page = 0,
    int size = 20,
    required int type,
  }) async {
    final raw = await _client.request<dynamic>(
      APIPaths.pictureGetList,
      params: {'page': page, 'size': size, 'userId': userId, 'type': type},
      fromJsonT: (json) => json,
    );
    if (raw == null) return [];
    final list = raw is List
        ? raw
        : (raw is Map && raw['records'] != null)
        ? (raw['records'] as List)
        : (raw is Map && raw['list'] != null)
        ? (raw['list'] as List)
        : [];
    return list.map((e) => PictureListItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// 我的视频列表 video/myVideos（进入 Videos 选项卡时调用）
  /// [type] 0: Daily Videos, 1: Sexy Videos
  /// 返回列表及 totalIncome（接口返回的 totalIncome 字段，用于 Videos 页 income 条展示）
  Future<({List<VideoListItem> list, double totalIncome})> getMyVideos({required int type}) async {
    final raw = await _client.request<dynamic>(
      APIPaths.videoMyVideos,
      params: {'type': type},
      fromJsonT: (json) => json,
    );
    double totalIncome = 0.0;
    if (raw is Map && raw['totalIncome'] != null) {
      final v = raw['totalIncome'];
      totalIncome = (v is num) ? v.toDouble() : (double.tryParse(v.toString()) ?? 0.0);
    }
    if (raw == null) return (list: <VideoListItem>[], totalIncome: totalIncome);
    final list = raw is List
        ? raw
        : (raw is Map && raw['records'] != null)
        ? (raw['records'] as List)
        : (raw is Map && raw['list'] != null)
        ? (raw['list'] as List)
        : [];
    final items = list.map((e) => VideoListItem.fromJson(e as Map<String, dynamic>)).toList();
    return (list: items, totalIncome: totalIncome);
  }

  /// 获取视频列表 video/getVideoList（备用，按需使用）
  /// [userId] 必传，当前用户 userId
  /// [type] 0: Daily Videos, 1: Sexy Videos（Say Hi 已隐藏）
  /// [page] 从 1 开始
  Future<List<VideoListItem>> getVideoList({
    required int userId,
    int page = 1,
    int size = 20,
    required int type,
  }) async {
    final raw = await _client.request<dynamic>(
      APIPaths.videoGetList,
      params: {'page': page, 'size': size, 'userId': userId, 'type': type},
      fromJsonT: (json) => json,
    );
    if (raw == null) return [];
    final list = raw is List
        ? raw
        : (raw is Map && raw['records'] != null)
        ? (raw['records'] as List)
        : (raw is Map && raw['list'] != null)
        ? (raw['list'] as List)
        : [];
    return list.map((e) => VideoListItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// 删除照片 picture/remove
  /// 参数样式: { "userId": 当前用户id, "ids": [] }
  Future<void> removePictures({required int userId, required List<int> ids}) async {
    if (ids.isEmpty) return;
    await _client.request<dynamic>(
      APIPaths.pictureRemove,
      params: {'userId': userId, 'ids': ids},
      fromJsonT: (json) => json,
    );
  }

  /// 批量新增/更新照片 picture/batchAddUpdate
  /// 参数样式: { "userId": 0, "pics": [ { "url": "", "cover": true, "type": 0, "id": 0, "coin": 0, "isPay": true } ] }
  Future<void> pictureBatchAddUpdate({required int userId, required List<Map<String, dynamic>> pics}) async {
    if (pics.isEmpty) return;
    await _client.request<dynamic>(
      APIPaths.pictureBatchAddUpdate,
      params: {'userId': userId, 'pics': pics},
      fromJsonT: (json) => json,
    );
  }

  /// 移除视频 video/remove，参数：videoId
  Future<void> videoRemove({required int videoId}) async {
    await _client.request<dynamic>(APIPaths.videoRemove, params: {'videoId': videoId}, fromJsonT: (json) => json);
  }

  /// 视频发布 video/publish
  /// 参数参照 Swagger：videoUrl 视频地址, cover 封面图地址, duration 时长(秒), type 类型(0 Daily, 1 Sexy), coin 价格
  Future<void> videoPublish({
    required String videoUrl,
    required String cover,
    required int duration,
    required int type,
    required int coin,
    String? introduction,
  }) async {
    await _client.request<dynamic>(
      APIPaths.videoPublish,
      params: {
        'videoUrl': videoUrl,
        'cover': cover,
        'duration': duration,
        'type': type,
        'coin': coin,
        if (introduction != null && introduction.isNotEmpty) 'introduction': introduction,
      },
      fromJsonT: (json) => json,
    );
  }
}
