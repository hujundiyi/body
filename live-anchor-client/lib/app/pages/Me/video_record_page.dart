import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

/// 录制时长限制
const Duration _kMinRecordDuration = Duration(seconds: 1);
const Duration _kMaxRecordDuration = Duration(seconds: 60);

/// 自定义视频录制页：带返回按钮可取消，支持翻转摄像头、显示录制时长，1–60 秒限制，录制完成后返回视频路径
class VideoRecordPage extends StatefulWidget {
  const VideoRecordPage({super.key});

  @override
  State<VideoRecordPage> createState() => _VideoRecordPageState();
}

class _VideoRecordPageState extends State<VideoRecordPage> {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _currentCameraIndex = 0;
  bool _initializing = true;
  bool _recording = false;
  String? _errorMessage;
  Duration _recordDuration = Duration.zero;
  Timer? _recordTimer;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initCamera() async {
    final cameraOk = await Permission.camera.request();
    if (!cameraOk.isGranted) {
      setState(() {
        _initializing = false;
        _errorMessage = 'Camera permission is required to record video';
      });
      return;
    }
    await Permission.microphone.request();
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted)
          setState(() {
            _initializing = false;
            _errorMessage = 'No camera detected';
          });
        return;
      }
      _cameras = cameras;
      _currentCameraIndex = cameras.indexWhere((c) => c.lensDirection == CameraLensDirection.back);
      if (_currentCameraIndex < 0) _currentCameraIndex = 0;
      await _createController(_cameras[_currentCameraIndex]);
      if (!mounted) return;
      setState(() {
        _initializing = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _initializing = false;
        _errorMessage = 'Failed to initialize camera';
      });
    }
  }

  Future<void> _createController(CameraDescription camera) async {
    await _controller?.dispose();
    _controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: true,
      imageFormatGroup: Platform.isIOS ? ImageFormatGroup.bgra8888 : ImageFormatGroup.nv21,
    );
    await _controller!.initialize();
  }

  /// 翻转摄像头（录制中不可用）
  Future<void> _switchCamera() async {
    if (_recording || _initializing || _cameras.length < 2) return;
    setState(() => _initializing = true);
    try {
      _currentCameraIndex = (_currentCameraIndex + 1) % _cameras.length;
      await _createController(_cameras[_currentCameraIndex]);
      if (!mounted) return;
      setState(() => _initializing = false);
    } catch (e) {
      if (mounted) {
        setState(() => _initializing = false);
        Get.snackbar('Notice', 'Failed to switch camera');
      }
    }
  }

  void _startRecordTimer() {
    _recordTimer?.cancel();
    _recordDuration = Duration.zero;
    _recordTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted) return;
      setState(() => _recordDuration += const Duration(milliseconds: 100));
      // 达到 60s 自动结束录制并提示
      if (_recordDuration >= _kMaxRecordDuration) {
        _recordTimer?.cancel();
        _recordTimer = null;
        setState(() => _recording = false);
        _stopRecordingAndReturn(showMaxHint: true);
      }
    });
  }

  void _stopRecordTimer() {
    _recordTimer?.cancel();
    _recordTimer = null;
  }

  static String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  /// 停止录制并视情况返回路径（用户点击停止或达到 60s 时调用）
  Future<void> _stopRecordingAndReturn({bool showMaxHint = false}) async {
    try {
      final file = await _controller!.stopVideoRecording();
      if (!mounted) return;
      if (file.path.isEmpty) return;
      if (showMaxHint) Get.snackbar('Notice', 'Maximum duration is 60s');
      Get.back(result: file.path);
    } catch (e) {
      if (mounted) Get.snackbar('Notice', 'Failed to stop recording');
    }
  }

  Future<void> _toggleRecord() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_recording) {
      _stopRecordTimer();
      setState(() => _recording = false);
      try {
        final file = await _controller!.stopVideoRecording();
        if (!mounted) return;
        if (file.path.isEmpty) return;
        if (_recordDuration < _kMinRecordDuration) {
          Get.snackbar('Notice', 'Recording too short');
          return;
        }
        Get.back(result: file.path);
      } catch (e) {
        if (mounted) Get.snackbar('Notice', 'Failed to stop recording');
      }
    } else {
      try {
        await _controller!.startVideoRecording();
        if (mounted) {
          setState(() => _recording = true);
          _startRecordTimer();
        }
      } catch (e) {
        if (mounted) Get.snackbar('Notice', 'Failed to start recording');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Get.back(result: null),
        ),
        title: const Text(
          'Record Video',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: _initializing
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF1493)))
          : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_errorMessage!, style: const TextStyle(color: Colors.white)),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Get.back(result: null),
                    child: const Text('Back', style: TextStyle(color: Color(0xFFFF1493))),
                  ),
                ],
              ),
            )
          : Stack(
              fit: StackFit.expand,
              children: [
                CameraPreview(_controller!),
                // 顶部中央：录制中 + 时长
                if (_recording)
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 16,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.fiber_manual_record, color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              _formatDuration(_recordDuration),
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                // 底部：拍摄钮固定水平居中，翻转在拍摄右侧
                Positioned(
                  left: 24,
                  right: 24,
                  bottom: 24 + MediaQuery.of(context).padding.bottom + 56,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(child: const SizedBox()),
                      // 拍摄钮始终在水平中心
                      GestureDetector(
                        onTap: _toggleRecord,
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _recording ? Colors.red : Colors.white,
                            border: Border.all(color: const Color(0xFFFF1493), width: 4),
                          ),
                          child: _recording ? const Icon(Icons.stop, color: Colors.white, size: 36) : null,
                        ),
                      ),
                      // 右侧区域：翻转按钮紧挨拍摄钮右侧（与拍摄钮垂直居中）
                      Expanded(
                        child: (!_recording && _cameras.length >= 2)
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(width: 32),
                                  GestureDetector(
                                    onTap: _switchCamera,
                                    child: Container(
                                      width: 48,
                                      height: 48,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                                      child: Image.asset(
                                        'asset/images/common/video_change.png',
                                        width: 24,
                                        height: 24,
                                        color: Colors.white,
                                        colorBlendMode: BlendMode.srcIn,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
