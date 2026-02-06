import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/services.dart';
import 'package:weeder/core/utils/toast_utils.dart';
import '../../controllers/assets_controller.dart';
import '../../../core/network/anchor_api_service.dart';
import '../../../data/models/dict_model.dart';

/// 选择照片/视频后的预览页：上半部分展示所选媒体，下半部分 Rate（字典 video_price）+ Add
class AddMediaPreviewPage extends StatefulWidget {
  const AddMediaPreviewPage({super.key, this.path, this.isVideo = false, this.videoType = 0});

  /// 媒体文件路径（优先使用；若为空则从 Get.arguments 读取）
  final String? path;

  /// 是否为视频（与 path 对应）
  final bool isVideo;

  /// 视频类型：1 Daily Videos, 2 Sexy Videos（仅视频时有效）
  final int videoType;

  @override
  State<AddMediaPreviewPage> createState() => _AddMediaPreviewPageState();
}

class _AddMediaPreviewPageState extends State<AddMediaPreviewPage> {
  DictItem? _selectedRate;
  bool _loadingRate = false;
  bool _isUploading = false;

  /// 视频时长（由 _VideoPreviewPlayer 初始化完成后回调）
  Duration? _videoDuration;

  @override
  void initState() {
    super.initState();
    _loadDefaultRate();
  }

  Future<void> _loadDefaultRate() async {
    try {
      final list = await AnchorAPIService.shared.getDict(['video_price']);
      for (final res in list) {
        if (res.dictType == 'video_price' && res.dictItems.isNotEmpty) {
          if (mounted) setState(() => _selectedRate = res.dictItems.first);
          break;
        }
      }
    } catch (_) {}
  }

  /// 规范化路径：去掉 file:// 前缀，便于 File() 使用（iOS 相册等可能带前缀）
  static String _normalizePath(String? p) {
    if (p == null || p.isEmpty) return '';
    final s = p.trim();
    if (s.toLowerCase().startsWith('file://')) return s.substring(7);
    return s;
  }

  static const MethodChannel _thumbnailChannel = MethodChannel('com.huankecontact.live/video_thumbnail');

  /// 通过平台通道获取视频首帧封面路径（仅 Android 实现；iOS 返回 null）
  Future<String?> _getVideoThumbnailPath(String videoPath, String outputDir) async {
    try {
      final result = await _thumbnailChannel.invokeMethod<String>('getThumbnail', {
        'videoPath': videoPath,
        'outputDir': outputDir,
      });
      return result;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, dynamic>?;
    final path = _normalizePath(widget.path ?? args?['path'] as String?);
    final isVideo = widget.path != null ? widget.isVideo : (args?['isVideo'] as bool? ?? false);
    if (path.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: _buildAppBar(isVideo: isVideo),
        body: const Center(
          child: Text('No file selected', style: TextStyle(color: Colors.white)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _buildAppBar(isVideo: isVideo),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Expanded(child: isVideo ? _buildVideoPreview(path) : _buildImagePreview(path)),
                Container(
                  color: Colors.black,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [_buildRateSection(), const SizedBox(height: 20), _buildAddButton(path, isVideo)],
                  ),
                ),
              ],
            ),
          ),
          if (_isUploading)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator(color: Color(0xFFFF1493))),
            ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar({required bool isVideo}) {
    return AppBar(
      backgroundColor: Colors.black,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Get.back(),
      ),
      title: Text(
        isVideo ? 'Add Video' : 'Add Photo',
        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
      ),
      centerTitle: true,
    );
  }

  Widget _buildImagePreview(String path) {
    final file = File(path);
    if (!file.existsSync()) {
      return const Center(child: Icon(Icons.broken_image_outlined, color: Colors.grey, size: 64));
    }
    return Container(
      width: double.infinity,
      color: Colors.black,
      child: InteractiveViewer(
        minScale: 0.5,
        maxScale: 4,
        child: Center(child: Image.file(file, fit: BoxFit.contain)),
      ),
    );
  }

  Widget _buildVideoPreview(String path) {
    return _VideoPreviewPlayer(
      key: ValueKey(path),
      path: path,
      onDurationReady: (d) {
        if (mounted) setState(() => _videoDuration = d);
      },
    );
  }

  Widget _buildRateSection() {
    final label = _selectedRate?.label ?? 'Please select';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Rate',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Material(
          color: const Color(0xFF2A2A4A),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: _loadingRate ? null : _onTapRate,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  if (_loadingRate)
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(color: Color(0xFFFF1493), strokeWidth: 2),
                    )
                  else
                    Image.asset('asset/images/common/coin.png', width: 22, height: 22, fit: BoxFit.contain),
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _onTapRate() async {
    setState(() => _loadingRate = true);
    try {
      final list = await AnchorAPIService.shared.getDict(['video_price']);
      List<DictItem> items = [];
      for (final res in list) {
        if (res.dictType == 'video_price' && res.dictItems.isNotEmpty) {
          items = res.dictItems;
          break;
        }
      }
      if (!mounted) return;
      if (_selectedRate == null && items.isNotEmpty) {
        setState(() {
          _loadingRate = false;
          _selectedRate = items.first;
        });
      } else {
        setState(() => _loadingRate = false);
      }
      if (items.isEmpty) {
        Get.snackbar('Notice', 'No price options available');
        return;
      }
      await _showRateSheet(items);
    } catch (e) {
      if (mounted) setState(() => _loadingRate = false);
      Get.snackbar('Notice', 'Failed to load price options');
    }
  }

  Future<void> _showRateSheet(List<DictItem> items) async {
    await Get.bottomSheet(
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Select Price',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              ...items.map(
                (item) => ListTile(
                  leading: Image.asset('asset/images/common/coin.png', width: 20, height: 20, fit: BoxFit.contain),
                  title: Text(item.label, style: const TextStyle(color: Colors.white, fontSize: 16)),
                  trailing: _selectedRate?.value == item.value
                      ? const Icon(Icons.check, color: Color(0xFFFF1493), size: 22)
                      : null,
                  onTap: () {
                    setState(() => _selectedRate = item);
                    Get.back();
                  },
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Get.back(),
                child: Text('Cancel', style: TextStyle(color: Colors.grey[400], fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildAddButton(String path, bool isVideo) {
    return Material(
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: _isUploading ? null : () => _onAdd(path, isVideo),
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              colors: [Color(0xFFFF69B4), Color(0xFFFF1493), Color(0xFFC71585), Color(0xFF8B008B)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          child: Center(
            child: _isUploading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Text(
                    'Add',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _onAdd(String path, bool isVideo) async {
    if (isVideo) {
      if (_videoDuration == null) {
        Get.snackbar('Notice', 'Please wait for the video to load');
        return;
      }
      if (!mounted) return;
      setState(() => _isUploading = true);
      try {
        final normalizedPath = _normalizePath(path);
        final videoFile = File(normalizedPath.isEmpty ? path : normalizedPath);
        if (!videoFile.existsSync()) {
          Get.snackbar('Notice', 'Video file not found');
          if (mounted) setState(() => _isUploading = false);
          return;
        }
        // 生成封面图（首帧），通过平台通道调用 Android MediaMetadataRetriever
        final dir = await getTemporaryDirectory();
        final coverPath = await _getVideoThumbnailPath(videoFile.path, dir.path);
        if (coverPath == null || coverPath.isEmpty) {
          Get.snackbar('Notice', 'Unable to generate video thumbnail');
          if (mounted) setState(() => _isUploading = false);
          return;
        }
        final coverFile = File(coverPath);
        if (!coverFile.existsSync()) {
          Get.snackbar('Notice', 'Failed to generate thumbnail');
          if (mounted) setState(() => _isUploading = false);
          return;
        }
        // 上传视频：type=video, fileName=视频名, contentLength=文件大小
        final videoName = videoFile.path.split('/').last;
        final videoFileName = videoName.isEmpty ? 'video_${DateTime.now().millisecondsSinceEpoch}.mp4' : videoName;
        final videoInfo = await AnchorAPIService.shared.getPutFileUrl(
          type: 'video',
          fileName: videoFileName,
          contentLength: await videoFile.length(),
        );
        if (videoInfo.putUrl == null || videoInfo.getUrl == null) {
          Get.snackbar('Notice', 'Failed to get video upload URL');
          if (mounted) setState(() => _isUploading = false);
          return;
        }
        await AnchorAPIService.shared.uploadFileToUrl(videoFile, videoInfo.putUrl!);
        final videoUrl = videoInfo.getUrl ?? videoInfo.putUrl ?? '';
        if (videoUrl.isEmpty) {
          Get.snackbar('Notice', 'Video upload failed');
          if (mounted) setState(() => _isUploading = false);
          return;
        }
        // 上传封面：type=picture, fileName=封面名, contentLength=文件大小
        final coverName = 'cover_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final coverInfo = await AnchorAPIService.shared.getPutFileUrl(
          type: 'picture',
          fileName: coverName,
          contentLength: await coverFile.length(),
        );
        if (coverInfo.putUrl == null || coverInfo.getUrl == null) {
          Get.snackbar('Notice', 'Failed to get thumbnail upload URL');
          if (mounted) setState(() => _isUploading = false);
          return;
        }
        await AnchorAPIService.shared.uploadFileToUrl(coverFile, coverInfo.putUrl!);
        final coverUrl = coverInfo.getUrl ?? coverInfo.putUrl ?? '';
        if (coverUrl.isEmpty) {
          Get.snackbar('Notice', 'Thumbnail upload failed');
          if (mounted) setState(() => _isUploading = false);
          return;
        }
        if (!mounted) return;
        setState(() => _isUploading = false);
        final coin = _selectedRate?.value ?? 0;
        Get.back(
          result: {
            'videoUrl': videoUrl,
            'cover': coverUrl,
            'duration': _videoDuration!.inSeconds,
            'type': widget.videoType,
            'coin': coin,
          },
        );
      } catch (e) {
        if (mounted) setState(() => _isUploading = false);
        Get.snackbar('Notice', 'Upload failed');
      }
      return;
    }
    if (!mounted) return;
    setState(() => _isUploading = true);
    try {
      final coin = _selectedRate?.value ?? 0;
      final controller = Get.find<AssetsController>();
      final url = await controller.uploadPhotoAndAddPending(File(path), coin: coin);
      if (!mounted) return;
      setState(() => _isUploading = false);
      Get.back();
      if (url != null) {
        ToastUtils.showInfo("Added to pending. Tap Save to save");
      }
    } catch (_) {
      if (mounted) setState(() => _isUploading = false);
    }
  }
}

/// 视频预览播放器：展示本地视频文件
class _VideoPreviewPlayer extends StatefulWidget {
  const _VideoPreviewPlayer({super.key, required this.path, this.onDurationReady});

  final String path;
  final void Function(Duration?)? onDurationReady;

  @override
  State<_VideoPreviewPlayer> createState() => _VideoPreviewPlayerState();
}

class _VideoPreviewPlayerState extends State<_VideoPreviewPlayer> {
  VideoPlayerController? _controller;
  String? _error;

  /// Android 备用：复制到临时目录后播放时保留引用，dispose 时删除
  File? _tempCopy;

  @override
  void initState() {
    super.initState();
    // 延迟一帧再初始化，避免 Android 上 Pigeon 通道尚未就绪导致 channel-error
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  @override
  void dispose() {
    _controller?.removeListener(_onPlayerUpdate);
    _controller?.dispose();
    try {
      _tempCopy?.deleteSync();
    } catch (_) {}
    super.dispose();
  }

  void _onPlayerUpdate() {
    if (mounted) setState(() {});
  }

  /// 规范化路径：去掉 file: / file:// 前缀（Android/iOS 可能返回）
  static String _normalizePath(String p) {
    final s = p.trim();
    final lower = s.toLowerCase();
    if (lower.startsWith('file://')) return s.substring(7);
    if (lower.startsWith('file:')) return s.substring(5);
    return s;
  }

  Future<void> _init({bool isRetry = false}) async {
    final normalizedPath = _normalizePath(widget.path);
    final isContentUri = normalizedPath.toLowerCase().startsWith('content://');

    // Android 上若为 channel-error，可延迟后重试一次（Pigeon 通道可能尚未就绪）
    if (Platform.isAndroid && !isRetry) {
      await Future.delayed(const Duration(milliseconds: 200));
      if (!mounted) return;
    }

    try {
      if (Platform.isAndroid && isContentUri) {
        _controller = VideoPlayerController.contentUri(Uri.parse(normalizedPath));
      } else {
        File file = File(normalizedPath);
        if (!file.existsSync()) {
          final rawFile = File(widget.path);
          if (rawFile.existsSync()) {
            file = rawFile;
          } else {
            if (mounted) setState(() => _error = 'Video file not found');
            return;
          }
        }
        final pathToUse = file.absolute.path;
        _controller = VideoPlayerController.file(File(pathToUse));
      }
      await _controller!.initialize();
      if (!mounted) return;
      _controller!.addListener(_onPlayerUpdate);
      widget.onDurationReady?.call(_controller!.value.duration);
      // 预览初始为暂停，不自动播放、不循环
      if (mounted) setState(() {});
    } catch (e) {
      final isChannelError =
          e.toString().toLowerCase().contains('channel-error') ||
          e.toString().toLowerCase().contains('unable to establish connection');
      // Android Pigeon channel-error 时重试一次（延迟 500ms）
      if (Platform.isAndroid && isChannelError && !isRetry) {
        _controller?.dispose();
        _controller = null;
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) await _init(isRetry: true);
        return;
      }
      // Android 拍摄文件有时在原生层无法直接访问，复制到临时目录再播放（非 channel 错误时）
      if (Platform.isAndroid && !isContentUri && !isChannelError) {
        try {
          final file = File(_normalizePath(widget.path));
          if (!file.existsSync()) {
            final rawFile = File(widget.path);
            if (!rawFile.existsSync()) {
              if (mounted) setState(() => _error = 'Video file not found');
              return;
            }
          }
          final src = file.existsSync() ? file : File(widget.path);
          final dir = await getTemporaryDirectory();
          final ext = widget.path.toLowerCase().endsWith('.mp4')
              ? '.mp4'
              : widget.path.contains('.')
              ? widget.path.substring(widget.path.lastIndexOf('.'))
              : '.mp4';
          final tempFile = File('${dir.path}/video_preview_${DateTime.now().millisecondsSinceEpoch}$ext');
          await src.copy(tempFile.path);
          _tempCopy = tempFile;
          _controller?.dispose();
          _controller = VideoPlayerController.file(tempFile);
          await _controller!.initialize();
          if (!mounted) return;
          _controller!.addListener(_onPlayerUpdate);
          widget.onDurationReady?.call(_controller!.value.duration);
          if (mounted) setState(() {});
          return;
        } catch (_) {}
      }
      if (mounted) {
        final msg = e.toString();
        final short = msg.length > 100 ? '${msg.substring(0, 100)}…' : msg;
        setState(() => _error = 'Video load failed: $short');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Container(
        width: double.infinity,
        color: const Color(0xFF1A1A2E),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.videocam_off, color: Colors.grey, size: 64),
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: Colors.grey[400], fontSize: 14)),
            ],
          ),
        ),
      );
    }
    if (_controller == null || !_controller!.value.isInitialized) {
      return Container(
        width: double.infinity,
        color: Colors.black,
        child: const Center(child: CircularProgressIndicator(color: Color(0xFFFF1493))),
      );
    }
    final ctrl = _controller!;
    final isPlaying = ctrl.value.isPlaying;

    return GestureDetector(
      onTap: () {
        if (isPlaying) {
          ctrl.pause();
        } else {
          ctrl.play();
        }
        setState(() {});
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          Center(
            child: AspectRatio(aspectRatio: ctrl.value.aspectRatio, child: VideoPlayer(ctrl)),
          ),
          if (!isPlaying)
            Container(
              color: Colors.black26,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                  child: const Icon(Icons.play_arrow, color: Colors.white, size: 56),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
