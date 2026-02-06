import 'dart:io';

import 'package:get/get.dart';
import '../../core/network/anchor_api_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/utils/toast_utils.dart';
import '../../data/models/picture_list_model.dart';
import '../../data/models/video_list_model.dart';

/// 待新增照片项（上传得到 url 后加入，Save 时调用 picture/batchAddUpdate）
/// 与 swagger 中 pics 单项一致：url, cover, type, id, coin, isPay
class PendingAddPhoto {
  final String url;
  final bool cover;
  final int type; // 0: Daily, 1: Sexy
  final int id;
  final int coin;
  final bool isPay;

  PendingAddPhoto({
    required this.url,
    this.cover = false,
    required this.type,
    this.id = 0,
    this.coin = 0,
    this.isPay = false,
  });

  Map<String, dynamic> toJson() => {'url': url, 'cover': cover, 'type': type, 'id': id, 'coin': coin, 'isPay': isPay};
}

/// 资产页（照片/视频）控制器
class AssetsController extends GetxController {
  final AnchorAPIService _api = AnchorAPIService.shared;
  AuthService get _auth => Get.find<AuthService>();

  /// 当前用户 ID（必传接口参数）
  int get userId => _auth.userInfo?.userId ?? 0;

  /// 照片列表（Photos 页，按 type 区分 Daily/Sexy）
  final RxList<PictureListItem> photoList = <PictureListItem>[].obs;

  /// 待删除的照片 id（点击关闭后暂存，点击 Save 时调用 picture/remove）
  final RxList<int> pendingRemovePhotoIds = <int>[].obs;

  /// 待新增的照片（选择并上传得到 url 后加入，Save 时调用 picture/batchAddUpdate）
  final RxList<PendingAddPhoto> pendingAddPhotos = <PendingAddPhoto>[].obs;

  /// 当前选中的照片 type，由页面在加载/切换时设置，用于上传后归属
  int currentPhotoType = 0;

  final RxBool isUploadingPhoto = false.obs;

  /// 点击 Save 提交照片变更时的加载状态（Save 按钮显示转圈）
  final RxBool isSavingPhotoChanges = false.obs;

  /// 视频列表（Videos 页 Daily/Sexy，按 type 区分）
  final RxList<VideoListItem> videoList = <VideoListItem>[].obs;

  /// 当前类型视频的总收益（接口 totalIncome，Daily/Sexy 切换时随 loadVideos 更新）
  final RxDouble videoTotalIncome = 0.0.obs;

  /// 正在发布中的视频（预览页上传成功后填入，在列表中显示并转圈请求 video/publish）
  final Rx<VideoListItem?> pendingPublishVideo = Rx<VideoListItem?>(null);
  final RxBool isPublishingVideo = false.obs;

  final RxBool isLoadingPhotos = false.obs;
  final RxBool isLoadingVideos = false.obs;

  static const int _pageSize = 20;

  /// 加载照片列表
  /// [type] 0: Daily Photos, 1: Sexy Photos
  /// [silent] true 时不显示整页 loading，用于保存后静默刷新
  Future<void> loadPhotos({required int type, bool silent = false}) async {
    if (userId <= 0) {
      photoList.clear();
      return;
    }
    if (!silent) isLoadingPhotos.value = true;
    try {
      final list = await _api.getPictureList(userId: userId, page: 0, size: _pageSize, type: type);
      photoList.assignAll(list);
    } catch (e) {
      photoList.clear();
    } finally {
      if (!silent) isLoadingPhotos.value = false;
    }
  }

  /// 加载视频列表（进入 Videos 选项卡时调用 video/myVideos）
  /// [type] 0: Daily Videos, 1: Sexy Videos
  /// 切换 Daily/Sexy 时先清空列表并转圈，加载完成后再显示新数据（与 Photos 行为一致）
  Future<void> loadVideos({required int type}) async {
    _currentVideoType = type;
    if (userId <= 0) {
      videoList.clear();
      videoTotalIncome.value = 0.0;
      return;
    }
    videoList.clear();
    videoTotalIncome.value = 0.0;
    isLoadingVideos.value = true;
    try {
      final result = await _api.getMyVideos(type: type);
      videoList.assignAll(result.list);
      videoTotalIncome.value = result.totalIncome;
    } catch (e) {
      videoList.clear();
      videoTotalIncome.value = 0.0;
    } finally {
      isLoadingVideos.value = false;
    }
  }

  /// 从列表中移除照片（视觉移除），并将 id 加入待删除列表
  void removePhotoFromList(int id) {
    pendingRemovePhotoIds.add(id);
    photoList.removeWhere((e) => e.id == id);
  }

  /// 从待保存列表中移除（上传后未点 Save 的项）
  void removePendingAddPhoto(String url) {
    pendingAddPhotos.removeWhere((p) => p.url == url);
  }

  /// 调用 video/remove 移除视频，成功后从展示列表中移除
  Future<void> removeVideoFromList(int videoId) async {
    try {
      await _api.videoRemove(videoId: videoId);
      videoList.removeWhere((e) => e.videoId == videoId);
    } catch (e) {
      ToastUtils.showError('Failed to remove video');
    }
  }

  /// 上传照片并加入待新增列表（得到 url 后 pendingAddPhotos）
  /// [coin] 价格（来自字典 video_price 的 value），0 表示免费
  Future<String?> uploadPhotoAndAddPending(File file, {int coin = 0}) async {
    if (userId <= 0) return null;
    isUploadingPhoto.value = true;
    try {
      final list = await _api.getPutFileUrls(files: [file], type: 'picture');
      if (list.isEmpty || list.first.putUrl == null || list.first.getUrl == null) {
        ToastUtils.showError('Failed to get upload URL');
        return null;
      }
      final info = list.first;
      await _api.uploadFileToUrl(file, info.putUrl!);
      final url = info.getUrl ?? info.putUrl ?? '';
      if (url.isEmpty) return null;
      pendingAddPhotos.add(PendingAddPhoto(url: url, type: currentPhotoType, coin: coin, isPay: coin != 0));
      return url;
    } catch (e) {
      ToastUtils.showError('Upload failed');
      return null;
    } finally {
      isUploadingPhoto.value = false;
    }
  }

  /// 预览页上传视频成功后调用：填入待发布项并请求 video/publish，成功后刷新视频列表
  Future<void> addPendingVideoAndPublish({
    required String videoUrl,
    required String cover,
    required int duration,
    required int type,
    required int coin,
  }) async {
    if (userId <= 0) return;
    final item = VideoListItem(
      videoId: null,
      videoUrl: videoUrl,
      cover: cover,
      duration: duration,
      type: type,
      coin: coin,
    );
    pendingPublishVideo.value = item;
    isPublishingVideo.value = true;
    try {
      await _api.videoPublish(videoUrl: videoUrl, cover: cover, duration: duration, type: type, coin: coin);
      await loadVideos(type: currentVideoType);
      ToastUtils.showSuccess('Video published successfully');
    } catch (e) {
      ToastUtils.showError('Failed to publish video');
    } finally {
      pendingPublishVideo.value = null;
      isPublishingVideo.value = false;
    }
  }

  /// 当前选中的视频 type（0 Daily, 1 Sexy），用于发布时归属
  int get currentVideoType => _currentVideoType;
  int _currentVideoType = 0;

  set currentVideoType(int v) {
    _currentVideoType = v;
  }

  /// Save：先提交删除 picture/remove，再提交新增 picture/batchAddUpdate，成功后刷新并提示
  Future<void> savePhotoChanges() async {
    if (pendingRemovePhotoIds.isEmpty && pendingAddPhotos.isEmpty) {
      ToastUtils.showInfo('Please select an image to remove or add a new one');
      return;
    }
    isSavingPhotoChanges.value = true;
    try {
      if (pendingRemovePhotoIds.isNotEmpty) {
        final ids = List<int>.from(pendingRemovePhotoIds);
        await _api.removePictures(userId: userId, ids: ids);
        pendingRemovePhotoIds.clear();
      }
      if (pendingAddPhotos.isNotEmpty) {
        final pics = pendingAddPhotos.map((e) => e.toJson()).toList();
        await _api.pictureBatchAddUpdate(userId: userId, pics: pics);
        pendingAddPhotos.clear();
      }
      await loadPhotos(type: currentPhotoType, silent: true);
      ToastUtils.showSuccess('Saved successfully');
    } catch (e) {
      ToastUtils.showError('Failed to save');
    } finally {
      isSavingPhotoChanges.value = false;
    }
  }
}
