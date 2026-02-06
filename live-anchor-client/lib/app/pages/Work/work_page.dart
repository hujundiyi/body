import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_user_status.dart';
import 'package:tencent_cloud_chat_sdk/tencent_im_sdk_plugin.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_callback.dart';
import '../../../core/network/anchor_api_service.dart';
import '../../../core/services/im_service.dart';
import '../../controllers/main_tab_controller.dart';
import '../../../core/utils/toast_utils.dart';

/// 工作状态页面（上下班）：直接使用腾讯 IM 的工作状态，不本地维护
class WorkPage extends StatefulWidget {
  const WorkPage({super.key});

  @override
  State<WorkPage> createState() => _WorkPageState();
}

class _WorkPageState extends State<WorkPage> {
  bool _isWorking = false;
  bool _isLoading = false;
  final IMService _imService = Get.find<IMService>();

  @override
  void initState() {
    super.initState();
    _fetchWorkStatusFromTencent();
    _imService.onWorkStatusSetToOffByApp = _syncToOffWork;
    _imService.onAppResumedToForeground = _fetchWorkStatusFromTencent;
    _imService.onUserStatusChanged = _onUserStatusChanged;
    _imService.onWorkTabSelected = _syncWorkStatusWithServer;
    _subscribeCurrentUserStatus();
    // 若当前已是 Work Tab（如恢复状态），进入时也同步一次
    if (Get.isRegistered<MainTabController>() &&
        Get.find<MainTabController>().currentIndex.value == MainTabController.workTabIndex) {
      _syncWorkStatusWithServer();
    }
  }

  @override
  void dispose() {
    _imService.onWorkStatusSetToOffByApp = null;
    _imService.onAppResumedToForeground = null;
    _imService.onUserStatusChanged = null;
    _imService.onWorkTabSelected = null;
    _unsubscribeCurrentUserStatus();
    super.dispose();
  }

  /// 订阅当前用户状态，以便在离线/状态变更时收到 onUserStatusChanged 并更新页面
  Future<void> _subscribeCurrentUserStatus() async {
    final userID = _imService.currentUserID;
    if (userID == null || userID.isEmpty) return;
    try {
      await TencentImSDKPlugin.v2TIMManager.subscribeUserStatus(
        userIDList: [userID],
      );
    } catch (_) {}
  }

  /// 取消订阅当前用户状态
  Future<void> _unsubscribeCurrentUserStatus() async {
    final userID = _imService.currentUserID;
    if (userID == null || userID.isEmpty) return;
    try {
      await TencentImSDKPlugin.v2TIMManager.unsubscribeUserStatus(
        userIDList: [userID],
      );
    } catch (_) {}
  }

  /// 用户状态变更回调：若当前用户离线或自定义状态非 OnWork，则主动更新页面
  void _onUserStatusChanged(List<V2TimUserStatus> userStatusList) {
    final userID = _imService.currentUserID;
    if (userID == null || userID.isEmpty || !mounted) return;
    for (final status in userStatusList) {
      if (status.userID != userID) continue;
      // statusType: 1=在线 2=离线 3=未登录
      final isOnline = status.statusType == 1;
      final isOnWork = (status.customStatus ?? '') == 'OnWork';
      if (mounted) {
        setState(() => _isWorking = isOnline && isOnWork);
      }
      break;
    }
  }

  /// IM 因 APP 重启/重新登录被设为离线时，同步更新本页 UI
  void _syncToOffWork() {
    if (mounted) setState(() => _isWorking = false);
  }

  /// 切换到 Work 页时：拉取一次用户信息，若服务端在线状态与腾讯不一致则设置腾讯状态
  /// 服务端 onlineStatus：0=离线 1=在线 2=忙碌（AnchorModel）
  Future<void> _syncWorkStatusWithServer() async {
    final userID = _imService.currentUserID;
    if (userID == null || userID.isEmpty || !mounted) return;
    try {
      final anchor = await AnchorAPIService.shared.getAnchorInfo();
      // 服务端期望「上班」：仅当 onlineStatus == 1（离线）时为 true
      final serverWantsOnWork = anchor.onlineStatus == 0;

      final result = await TencentImSDKPlugin.v2TIMManager.getUserStatus(
        userIDList: [userID],
      );
      final tencentIsOnWork = result.code == 0 &&
          result.data != null &&
          result.data!.isNotEmpty &&
          (result.data!.first.customStatus ?? '') == 'OnWork';

      if (serverWantsOnWork != tencentIsOnWork && mounted) {
        await _setWorkStatus(serverWantsOnWork, silent: true);
      }
    } catch (_) {
      // 拉取失败仅忽略，不改变当前腾讯状态
    }
  }

  /// 从腾讯 IM 获取当前工作状态
  Future<void> _fetchWorkStatusFromTencent() async {
    final userID = _imService.currentUserID;
    if (userID == null || userID.isEmpty) {
      if (mounted) setState(() => _isWorking = false);
      return;
    }
    try {
      final result = await TencentImSDKPlugin.v2TIMManager.getUserStatus(
        userIDList: [userID],
      );
      if (result.code == 0 && result.data != null && result.data!.isNotEmpty) {
        final customStatus = result.data!.first.customStatus ?? '';
        if (mounted) {
          setState(() => _isWorking = customStatus == 'OnWork');
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  /// 设置工作状态（直接设置腾讯 IM 状态）
  /// [silent] 为 true 时不显示 Snackbar
  Future<void> _setWorkStatus(bool isWorking, {bool silent = false}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final status = isWorking ? 'OnWork' : 'OffWork';

      V2TimCallback result =
          await TencentImSDKPlugin.v2TIMManager.setSelfStatus(
        status: status,
      );

      if (result.code == 0) {
        if (mounted) {
          setState(() {
            _isWorking = isWorking;
          });
        }
        if (!silent) {
          ToastUtils.showSuccess(
            isWorking
                ? 'Clocked in, ready to accept calls'
                : 'Clocked out, no longer accepting calls',
            title: 'Success',
          );
        }
      } else {
        if (!silent) {
          ToastUtils.showError(
            result.desc ?? 'Failed to set status',
            title: 'Failed',
          );
        }
      }
    } catch (e) {
      if (!silent) {
        ToastUtils.showError(
          'Failed to set status: $e',
          title: 'Error',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildStatusIndicator(),
                    const SizedBox(height: 40),
                    _buildWorkButton(),
                    const SizedBox(height: 20),
                    _buildStatusText(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建头部
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Work',
            style: TextStyle(
              color: Color(0xFFFF1493),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _isWorking ? const Color(0xFF00C853) : Colors.grey,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _isWorking ? 'Online' : 'Offline',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建状态指示器
  Widget _buildStatusIndicator() {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: _isWorking
              ? [const Color(0xFF00C853), const Color(0xFF69F0AE)]
              : [const Color(0xFF424242), const Color(0xFF616161)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: _isWorking
                ? const Color(0xFF00C853).withOpacity(0.4)
                : Colors.black.withOpacity(0.3),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isWorking ? Icons.work : Icons.work_off,
              size: 64,
              color: Colors.white,
            ),
            const SizedBox(height: 8),
            Text(
              _isWorking ? 'Working' : 'Off Duty',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建上下班按钮
  Widget _buildWorkButton() {
    return GestureDetector(
      onTap: _isLoading ? null : () => _setWorkStatus(!_isWorking),
      child: Container(
        width: 280,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isWorking
                ? [Colors.orange, Colors.deepOrange]
                : [const Color(0xFFFF1493), const Color(0xFFFF69B4)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: _isWorking
                  ? Colors.orange.withOpacity(0.4)
                  : const Color(0xFFFF1493).withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Center(
          child: _isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isWorking ? Icons.stop_circle : Icons.play_circle,
                      color: Colors.white,
                      size: 28,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isWorking ? 'Clock Out' : 'Clock In',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  /// 构建状态文字
  Widget _buildStatusText() {
    return Text(
      _isWorking
          ? 'You are now accepting calls'
          : 'Click to start accepting calls',
      style: TextStyle(
        color: Colors.grey[400],
        fontSize: 14,
      ),
    );
  }
}
