import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../../core/services/auth_service.dart';
import '../../../core/utils/toast_utils.dart';
import '../../../core/network/anchor_api_service.dart';
import '../../../core/network/api_client.dart';
import '../../../routes/app_routes.dart';
import '../../../core/constants/app_constants.dart';
import 'change_password_page.dart';
import 'block_list_page.dart';

/// 设置页面
class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  AuthService get _authService => Get.find<AuthService>();

  final RxString _cacheSize = '0 B'.obs;
  final RxBool _isClearing = false.obs;
  final RxBool _isSigningOut = false.obs;

  @override
  void initState() {
    super.initState();
    _calculateCacheSize();
  }

  /// 计算缓存大小
  Future<void> _calculateCacheSize() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      final size = await _getDirectorySize(cacheDir);
      _cacheSize.value = _formatBytes(size);
    } catch (e) {
      _cacheSize.value = '0 B';
    }
  }

  /// 获取目录大小
  Future<int> _getDirectorySize(Directory dir) async {
    int size = 0;
    try {
      if (await dir.exists()) {
        await for (var entity in dir.list(recursive: true, followLinks: false)) {
          if (entity is File) {
            size += await entity.length();
          }
        }
      }
    } catch (e) {
      debugPrint('获取目录大小失败: $e');
    }
    return size;
  }

  /// 格式化字节大小
  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var i = 0;
    double size = bytes.toDouble();
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(2)} ${suffixes[i]}';
  }

  /// 获取环境名称
  String _getEnvironmentName(AppEnvironment env) {
    switch (env) {
      case AppEnvironment.development:
        return 'Development';
      case AppEnvironment.staging:
        return 'Staging';
      case AppEnvironment.production:
        return 'Production';
    }
  }

  /// 清除缓存
  Future<void> _clearCache() async {
    _isClearing.value = true;
    try {
      final cacheDir = await getTemporaryDirectory();
      if (await cacheDir.exists()) {
        await for (var entity in cacheDir.list()) {
          try {
            if (entity is File) {
              await entity.delete();
            } else if (entity is Directory) {
              await entity.delete(recursive: true);
            }
          } catch (e) {
            debugPrint('删除缓存项失败: $e');
          }
        }
      }
      _cacheSize.value = '0 B';
      ToastUtils.showSuccess('Cache cleared successfully');
    } catch (e) {
      ToastUtils.showError('Failed to clear cache');
    } finally {
      _isClearing.value = false;
    }
  }

  /// 显示登出确认对话框（Tips + Sign out / Cancel），弹窗不占满全屏
  void _showSignOutDialog() {
    Get.dialog(
      Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          decoration: BoxDecoration(color: const Color(0xFF2A2A4A), borderRadius: BorderRadius.circular(20)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Tips',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Are you sure you want to sign out of this account?',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 15, height: 1.4, decoration: TextDecoration.none),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Obx(() {
                      final loading = _isSigningOut.value;
                      return GestureDetector(
                        onTap: loading
                            ? null
                            : () async {
                                _isSigningOut.value = true;
                                try {
                                  await AnchorAPIService.shared.loginOut();
                                } catch (e) {
                                  debugPrint('loginOut API error: $e');
                                }
                                await _authService.logout();
                                if (Get.isDialogOpen == true) Get.back();
                                AppRoutes.goToAnchorLogin();
                              },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF4444), Color(0xFFE91E63)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: loading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text(
                                  'Sign out',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Obx(
                      () => GestureDetector(
                        onTap: _isSigningOut.value ? null : () => Get.back(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF1493), Color(0xFF9C27B0)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Setting',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            decoration: TextDecoration.none,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildMenuSection([
                    Obx(
                      () => _SettingItem(
                        icon: Icons.person_outline,
                        iconColor: const Color(0xFF2196F3),
                        title: 'Account',
                        trailing: Text(
                          _authService.userInfo?.nickname ?? '',
                          style: const TextStyle(color: Colors.grey, fontSize: 14, decoration: TextDecoration.none),
                          overflow: TextOverflow.ellipsis,
                        ),
                        showArrow: false,
                        onTap: null,
                      ),
                    ),
                    _SettingItem(
                      icon: Icons.lock_outline,
                      iconColor: const Color(0xFF9C27B0),
                      title: 'Change Password',
                      onTap: () => Get.to(() => const ChangePasswordPage()),
                    ),
                    _SettingItem(
                      icon: Icons.block,
                      iconColor: const Color(0xFFE53935),
                      title: 'Blocklist',
                      onTap: () => Get.to(() => const BlockListPage(), preventDuplicates: false),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  _buildMenuSection([
                    Obx(
                      () => _SettingItem(
                        icon: Icons.cleaning_services_outlined,
                        iconColor: const Color(0xFFFF9800),
                        title: 'Clear Cache',
                        trailing: _isClearing.value
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Text(
                                _cacheSize.value,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                        showArrow: false,
                        onTap: _isClearing.value ? null : _clearCache,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  _buildMenuSection([
                    // 仅在非生产环境显示当前环境
                    if (EnvironmentConfig.current != AppEnvironment.production)
                      _SettingItem(
                        icon: Icons.developer_mode,
                        iconColor: const Color(0xFFFFC107),
                        title: 'Current Environment',
                        trailing: Text(
                          _getEnvironmentName(EnvironmentConfig.current),
                          style: const TextStyle(
                            color: Color(0xFFFFC107),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.none,
                          ),
                        ),
                        showArrow: false,
                        onTap: null,
                      ),
                    _SettingItem(
                      icon: Icons.info_outline,
                      iconColor: const Color(0xFF00C853),
                      title: 'About Us',
                      onTap: () {
                        // TODO: 跳转到关于我们页面
                        _showAboutDialog();
                      },
                    ),
                  ]),
                ],
              ),
            ),
          ),
          // 底部 Sign Out 按钮（离底部留足间距）
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.only(top: 24, bottom: 32, left: 16, right: 16),
              child: _buildSignOutButton(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection(List<Widget> items) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: const Color(0xFF2A2A4A), borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Column(
            children: [
              item,
              if (index < items.length - 1) const Divider(color: Colors.white12, height: 1, indent: 56),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSignOutButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _showSignOutDialog,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2A2A4A),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: const Text(
          'Sign Out',
          style: TextStyle(
            color: Color(0xFFFF4444),
            fontSize: 16,
            fontWeight: FontWeight.bold,
            decoration: TextDecoration.none,
          ),
        ),
      ),
    );
  }

  void _showAboutDialog() {
    final version = Get.isRegistered<APIClient>()
        ? Get.find<APIClient>().getAppVersion()
        : '1.0.1';
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF2A2A4A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'About Us',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, decoration: TextDecoration.none),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Anchor App',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Version $version',
              style: const TextStyle(color: Colors.white70, decoration: TextDecoration.none),
            ),
            const SizedBox(height: 16),
            const Text(
              'A professional live streaming platform for anchors.',
              style: TextStyle(color: Colors.white70, decoration: TextDecoration.none),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              'OK',
              style: TextStyle(color: Color(0xFF2196F3), decoration: TextDecoration.none),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showArrow;

  const _SettingItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.trailing,
    this.onTap,
    this.showArrow = true,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: iconColor, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.none,
              ),
            ),
          ),
          if (trailing != null) ...[trailing!, if (showArrow) const SizedBox(width: 8)],
          if (showArrow) const Icon(Icons.chevron_right, color: Colors.grey, size: 24),
        ],
      ),
    );
    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(12), child: content),
      );
    }
    return content;
  }
}
