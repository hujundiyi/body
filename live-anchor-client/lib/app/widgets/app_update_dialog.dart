import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import '../../../data/models/app_update_model.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/storage_service.dart';

/// 应用更新弹窗：标题 updateTitle，内容 content，图片，Sure/Cancel（isForce 时仅 Sure）
void showAppUpdateDialog(AppUpdateModel update) {
  final isForce = update.isForce ?? true;
  Get.dialog(
    PopScope(
      canPop: !isForce,
      child: Dialog(
        backgroundColor: const Color(0xFF2A2A4A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('asset/images/common/live_update.png', width: 64, height: 64),
              const SizedBox(height: 16),
              Text(
                update.updateTitle ?? 'New Version',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
                child: SingleChildScrollView(
                  child: Text(
                    update.content ?? '',
                    style: TextStyle(color: Colors.grey[300], fontSize: 14, height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  if (!isForce)
                    Expanded(
                      child: TextButton(
                        onPressed: () => Get.back(),
                        child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                      ),
                    ),
                  if (!isForce) const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back();
                        _showDownloadOverlay(update);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF1493),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Sure'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
    barrierDismissible: !isForce,
  );
}

/// 进入主 Tab 时调用：若有未完成下载或已下载未安装，则弹出下载/安装浮层并返回 true；否则清理“已点安装”的临时文件并返回 false
Future<bool> checkPendingUpdateAndShowOverlayIfNeeded() async {
  final storage = Get.find<StorageService>();
  final installStarted = storage.getBool(AppConstants.keyPendingUpdateInstallStarted) ?? false;
  if (installStarted) {
    final jsonStr = storage.getString(AppConstants.keyPendingUpdateJson);
    if (jsonStr != null) {
      try {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>?;
        final fileUrl = map?['fileUrl'] as String?;
        if (fileUrl != null && fileUrl.isNotEmpty) {
          final dir = await getTemporaryDirectory();
          final fileName = fileUrl.split('/').last.isNotEmpty ? fileUrl.split('/').last : 'app_update.apk';
          final name = fileName.endsWith('.apk') ? fileName : 'app_update.apk';
          final path = '${dir.path}/$name';
          final file = File(path);
          if (file.existsSync()) file.deleteSync();
        }
      } catch (_) {}
    }
    await storage.remove(AppConstants.keyPendingUpdateJson);
    await storage.remove(AppConstants.keyPendingUpdateCompleted);
    await storage.remove(AppConstants.keyPendingUpdateInstallStarted);
    await storage.remove(AppConstants.keyPendingUpdateProgress);
    return false;
  }
  final jsonStr = storage.getString(AppConstants.keyPendingUpdateJson);
  if (jsonStr == null) return false;
  AppUpdateModel update;
  try {
    update = AppUpdateModel.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
  } catch (_) {
    await storage.remove(AppConstants.keyPendingUpdateJson);
    await storage.remove(AppConstants.keyPendingUpdateCompleted);
    await storage.remove(AppConstants.keyPendingUpdateProgress);
    return false;
  }
  final fileUrl = update.fileUrl ?? '';
  final fileName = fileUrl.split('/').last.isNotEmpty ? fileUrl.split('/').last : 'app_update.apk';
  final name = fileName.endsWith('.apk') ? fileName : 'app_update.apk';
  final dir = await getTemporaryDirectory();
  final path = '${dir.path}/$name';
  final file = File(path);
  if (!file.existsSync()) {
    await storage.remove(AppConstants.keyPendingUpdateJson);
    await storage.remove(AppConstants.keyPendingUpdateCompleted);
    await storage.remove(AppConstants.keyPendingUpdateProgress);
    return false;
  }
  final completed = storage.getBool(AppConstants.keyPendingUpdateCompleted) ?? false;
  final progressStr = storage.getString(AppConstants.keyPendingUpdateProgress);
  final double? initialProgress = progressStr != null ? double.tryParse(progressStr) : null;
  Get.dialog(
    _AppUpdateDownloadOverlay(
      update: update,
      pendingInstallPath: completed ? path : null,
      initialProgress: initialProgress,
    ),
    barrierDismissible: false,
  );
  return true;
}

void _showDownloadOverlay(AppUpdateModel update) {
  _savePendingUpdate(update, completed: false, installStarted: false);
  Get.dialog(_AppUpdateDownloadOverlay(update: update, pendingInstallPath: null), barrierDismissible: false);
}

Future<void> _savePendingUpdate(AppUpdateModel update, {required bool completed, required bool installStarted}) async {
  final storage = Get.find<StorageService>();
  await storage.setString(AppConstants.keyPendingUpdateJson, jsonEncode(update.toJson()));
  await storage.setBool(AppConstants.keyPendingUpdateCompleted, completed);
  await storage.setBool(AppConstants.keyPendingUpdateInstallStarted, installStarted);
}

class _AppUpdateDownloadOverlay extends StatefulWidget {
  final AppUpdateModel update;

  /// 非空表示“仅安装”模式：已有完整 APK，只显示安装按钮，不发起下载
  final String? pendingInstallPath;

  /// 杀进程后恢复时传入上次保存的进度 0.0~1.0，界面从该进度显示并继续下载
  final double? initialProgress;

  const _AppUpdateDownloadOverlay({required this.update, this.pendingInstallPath, this.initialProgress});

  @override
  State<_AppUpdateDownloadOverlay> createState() => _AppUpdateDownloadOverlayState();
}

class _AppUpdateDownloadOverlayState extends State<_AppUpdateDownloadOverlay> {
  double _progress = 0;
  String _status = 'Preparing...';
  String? _localPath;
  bool _downloading = true;
  String _fileName = 'app_update.apk';
  bool _downloadFailed = false;

  @override
  void initState() {
    super.initState();
    final url = widget.update.fileUrl ?? '';
    _fileName = url.split('/').last.isNotEmpty ? url.split('/').last : 'app_update.apk';
    if (!_fileName.endsWith('.apk')) _fileName = 'app_update.apk';
    if (widget.pendingInstallPath != null) {
      _localPath = widget.pendingInstallPath;
      _downloading = false;
      _progress = 1;
      _status = 'Download complete';
    } else {
      if (widget.initialProgress != null) {
        _progress = widget.initialProgress!.clamp(0.0, 1.0);
        _status = 'Resuming... ${(_progress * 100).toStringAsFixed(0)}%';
      }
      _startDownload();
    }
  }

  Future<void> _persistProgress(double value) async {
    try {
      final storage = Get.find<StorageService>();
      await storage.setString(AppConstants.keyPendingUpdateProgress, value.toString());
    } catch (_) {}
  }

  Future<void> _clearProgress() async {
    try {
      final storage = Get.find<StorageService>();
      await storage.remove(AppConstants.keyPendingUpdateProgress);
    } catch (_) {}
  }

  /// 重试：从断点续传或从头下载
  void _retry() {
    setState(() {
      _downloadFailed = false;
      _downloading = true;
      _status = 'Preparing...';
    });
    _startDownload();
  }

  Future<void> _startDownload() async {
    final url = widget.update.fileUrl;
    if (url == null || url.isEmpty) {
      setState(() {
        _status = 'Invalid download link';
        _downloading = false;
        _downloadFailed = true;
      });
      return;
    }
    try {
      final dir = await getTemporaryDirectory();
      final savePath = '${dir.path}/$_fileName';
      final file = File(savePath);
      int existingLength = 0;
      if (file.existsSync()) existingLength = file.lengthSync();
      final dio = Dio();

      // 若已有部分文件，先尝试断点续传（HEAD 获取总大小，部分服务器仅在 GET 返回 Accept-Ranges）
      int totalSize = 0;
      bool rangeSupported = false;
      if (existingLength > 0) {
        try {
          final headResponse = await dio.head(url, options: Options(responseType: ResponseType.plain));
          final contentLength = headResponse.headers.value(Headers.contentLengthHeader);
          final acceptRanges = headResponse.headers.value('accept-ranges')?.toLowerCase();
          totalSize = contentLength != null ? int.tryParse(contentLength) ?? 0 : 0;
          rangeSupported = acceptRanges == 'bytes' && totalSize > 0 && existingLength < totalSize;
        } catch (_) {
          // HEAD 失败也尝试 Range GET，206 时从 Content-Range 取总大小
        }
      }

      void onProgress(int received, int total) {
        if (mounted && total > 0) {
          final p = received / total;
          _persistProgress(p);
          setState(() {
            _progress = p;
            _status = 'Downloading... ${(_progress * 100).toStringAsFixed(0)}%';
          });
        }
      }

      if (rangeSupported && existingLength > 0) {
        setState(() => _status = 'Resuming... ${(existingLength / 1024).toStringAsFixed(0)} KB');
        await _downloadWithRange(dio, url, savePath, existingLength, totalSize);
      } else if (existingLength > 0) {
        // HEAD 未返回 Range 支持时仍尝试断点续传；206 时在 _downloadWithRange 内从 Content-Range 取总大小
        try {
          setState(() => _status = 'Resuming... ${(existingLength / 1024).toStringAsFixed(0)} KB');
          await _downloadWithRange(dio, url, savePath, existingLength, totalSize);
        } catch (_) {
          file.deleteSync();
          await _clearProgress();
          setState(() => _status = 'Downloading...');
          await dio.download(url, savePath, onReceiveProgress: onProgress);
        }
      } else {
        await _clearProgress();
        setState(() => _status = 'Downloading...');
        await dio.download(url, savePath, onReceiveProgress: onProgress);
      }

      if (mounted) {
        setState(() {
          _localPath = savePath;
          _progress = 1;
          _downloading = false;
          _status = 'Download complete';
        });
        await _clearProgress();
        await _savePendingUpdate(widget.update, completed: true, installStarted: false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _status = 'Download failed';
          _downloading = false;
          _downloadFailed = true;
        });
      }
    }
  }

  /// 使用 Range 头从 [startByte] 起流式下载剩余内容并追加到 [savePath]；支持 206 断点续传，避免整包进内存
  Future<void> _downloadWithRange(Dio dio, String url, String savePath, int startByte, int totalSize) async {
    final file = File(savePath);
    final raf = await file.open(mode: FileMode.writeOnlyAppend);
    try {
      final response = await dio.get<dynamic>(
        url,
        options: Options(
          responseType: ResponseType.stream,
          headers: <String, dynamic>{'Range': 'bytes=$startByte-'},
          followRedirects: true,
          receiveDataWhenStatusError: false,
          validateStatus: (status) => status != null && (status == 200 || status == 206),
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(minutes: 10),
        ),
      );
      if (response.statusCode == 200) {
        await raf.close();
        throw Exception('Range not supported');
      }
      final body = response.data;
      final stream = body?.stream;
      if (stream == null) {
        if (mounted) {
          setState(() {
            _downloadFailed = true;
            _downloading = false;
            _status = 'Download failed';
          });
        }
        return;
      }
      int total = totalSize;
      final contentRange = response.headers.value('content-range');
      if (contentRange != null) {
        final match = RegExp(r'bytes \d+-\d+/(\d+)').firstMatch(contentRange);
        if (match != null) total = int.tryParse(match.group(1)!) ?? totalSize;
      }
      if (total <= 0) {
        final cl = response.headers.value(Headers.contentLengthHeader);
        if (cl != null) total = startByte + (int.tryParse(cl) ?? 0);
      }
      if (total <= 0) total = startByte + 1;

      int received = 0;
      await for (final chunk in stream) {
        if (chunk.isNotEmpty) {
          await raf.writeFrom(chunk);
          received += chunk.length as int;
          if (mounted) {
            final p = ((startByte + received) / total).clamp(0.0, 1.0);
            _persistProgress(p);
            setState(() {
              _progress = p;
              _status = 'Downloading... ${(_progress * 100).toStringAsFixed(0)}%';
            });
          }
        }
      }
      await raf.flush();
      if (mounted && total > 0) {
        final p = ((startByte + received) / total).clamp(0.0, 1.0);
        _persistProgress(p);
        setState(() {
          _progress = p;
          _status = 'Downloading... ${(_progress * 100).toStringAsFixed(0)}%';
        });
      }
    } finally {
      await raf.close();
    }
  }

  Future<void> _installApk() async {
    if (_localPath == null) return;
    final path = _localPath!;
    if (!Platform.isAndroid) return;
    await _savePendingUpdate(widget.update, completed: true, installStarted: true);
    try {
      const channel = MethodChannel('com.huankecontact.live/app_install');
      await channel.invokeMethod<void>('installApk', <String, dynamic>{'path': path});
    } on PlatformException catch (e) {
      if (mounted) {
        setState(() {
          _status = e.message ?? 'Install failed';
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.black87,
        body: SafeArea(
          child: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: const Color(0xFF2A2A4A), borderRadius: BorderRadius.circular(16)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('asset/images/common/launch.png', width: 72, height: 72),
                  const SizedBox(height: 16),
                  Text(
                    _fileName,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Text(_status, style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: _progress,
                    backgroundColor: Colors.grey[700],
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF1493)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(_progress * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  if (!_downloading && _localPath != null) ...[
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _installApk,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF1493),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Install'),
                      ),
                    ),
                  ],
                  if (_downloadFailed) ...[
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _retry,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF1493),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Retry'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
