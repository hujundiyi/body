import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:weeder/core/utils/toast_utils.dart';
import 'package:weeder/data/models/user_model_entity.dart';
import 'package:weeder/data/models/call_history_model.dart';
import 'package:weeder/data/models/dict_model.dart';
import '../../controllers/user_detail_controller.dart';
import '../../widgets/avatar_network_image.dart';

/// 用户详情页
/// 进入时调用 user/getInfo，展示头像、昵称、ID、数据列表、通话历史、底部操作按钮
class UserDetailPage extends GetView<UserDetailController> {
  const UserDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: Obx(
              () => Text(
                controller.user.value?.nickname ?? '--',
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: () {
                if (controller.fromFollowList) {
                  Get.back(result: {'userId': controller.userId, 'isNowFollowing': controller.isFollowing});
                } else {
                  Get.back();
                }
              },
            ),
            actions: [IconButton(icon: const Icon(Icons.more_horiz), onPressed: () => _showMoreMenu(context))],
          ),
          body: Obx(() {
            if (controller.isLoading.value && controller.user.value == null) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFFFF1493)));
            }
            final u = controller.user.value;
            if (u == null) {
              return const Center(
                child: Text('User not found', style: TextStyle(color: Colors.grey)),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeader(u),
                        const SizedBox(height: 24),
                        _buildDataList(u),
                        const SizedBox(height: 24),
                        _buildCallHistorySection(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(padding: const EdgeInsets.fromLTRB(20, 12, 20, 8), child: _buildBottomButtons()),
                ),
              ],
            );
          }),
        ),
        // 拉黑成功后由页面执行 Get.back，确保 Navigator 上下文正确
        Obx(() {
          final userId = controller.blockSuccessUserId.value;
          if (userId > 0) {
            controller.blockSuccessUserId.value = 0;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Get.back(result: {'blockedUserId': userId});
              Future.delayed(const Duration(milliseconds: 200), () {
                ToastUtils.showSuccess('Blocked');
              });
            });
          }
          return const SizedBox.shrink();
        }),
      ],
    );
  }

  /// 右上角更多菜单：从底部弹出 Report / Block / Cancel
  void _showMoreMenu(BuildContext context) {
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Color(0xFF2A2A4A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMoreMenuItem(
                label: 'Report',
                color: const Color(0xFFFF1493),
                onTap: () {
                  Get.back();
                  _showReportDialog();
                },
              ),
              _buildMoreMenuItem(
                label: 'Block',
                color: const Color(0xFFFF1493),
                onTap: () {
                  Get.back();
                  controller.onBlock();
                },
              ),
              _buildMoreMenuItem(label: 'Cancel', color: Colors.grey, onTap: () => Get.back()),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
    );
  }

  /// 举报弹窗：从字典 report_type 加载选项，单选，Submit 调用 user/reportUser
  Future<void> _showReportDialog() async {
    final options = await controller.loadReportTypes();
    if (options.isEmpty) {
      ToastUtils.showError('No report types available');
      return;
    }
    Get.dialog(
      Align(
        alignment: Alignment.center,
        child: Material(
          color: Colors.transparent,
          child: _ReportDialogContent(options: options, controller: controller),
        ),
      ),
      barrierDismissible: false,
    );
  }

  Widget _buildMoreMenuItem({required String label, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text(
            label,
            style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w500, decoration: TextDecoration.none),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(UserModelEntity u) {
    final avatarUrl = u.avatar.isNotEmpty ? u.avatar : null;
    return Row(
      children: [
        Stack(
          children: [
            AvatarNetworkImage(
              imageUrl: avatarUrl,
              size: 64,
              placeholderAssetImage: 'asset/images/common/avatar_placeholder.svg',
              placeholderColor: const Color(0xFF4A4A5A),
              placeholderIconColor: Colors.white54,
            ),
            if (u.onlineStatus == 0) // 0 表示在线
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00FF00),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                u.nickname,
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text('ID:${u.userId}', style: TextStyle(color: Colors.grey[400], fontSize: 14)),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: controller.copyId,
                    child: Icon(Icons.copy, size: 18, color: Colors.grey[400]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDataList(UserModelEntity u) {
    final items = <_DataRow>[
      _DataRow(icon: Icons.cake, label: 'Age:', value: u.age > 0 ? '${u.age} yrs' : '--'),
      _DataRow(icon: Icons.location_on, label: 'Country:', value: controller.countryLabel(u.country)),
      _DataRow(icon: Icons.wc, label: 'Gender:', value: u.genderDict.isNotEmpty ? u.genderDict : '--'),
      _DataRow(icon: Icons.phone, label: 'Number of calls:', value: '${u.callNum}', iconColor: const Color(0xFF2196F3)),
      _DataRow(
        icon: Icons.access_time,
        label: 'Average call time:',
        value: controller.averageCallTimeFormatted,
        iconColor: const Color(0xFF9C27B0),
      ),
      _DataRow(
        icon: Icons.person_add,
        label: 'Registration time:',
        value: controller.registrationTimeFormatted(u.createTime),
        iconColor: const Color(0xFF4CAF50),
      ),
      _DataRow(
        icon: Icons.monetization_on,
        iconAsset: 'asset/images/common/coin.png',
        label: 'Coins balance:',
        value: '${u.coinBalance}',
        iconColor: const Color(0xFFFFC107),
      ),
    ];
    return Column(children: items.map((e) => _buildDataRow(e)).toList());
  }

  Widget _buildDataRow(_DataRow row) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          if (row.iconAsset != null)
            Image.asset(row.iconAsset!, width: 22, height: 22, fit: BoxFit.contain)
          else
            Icon(row.icon, size: 22, color: row.iconColor ?? Colors.grey),
          const SizedBox(width: 12),
          Text(row.label, style: TextStyle(color: Colors.grey[400], fontSize: 15)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              row.value,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Call history',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Obx(() {
          if (controller.callHistoryList.isEmpty) {
            return Container(
              height: 80,
              alignment: Alignment.center,
              child: Text('No call history', style: TextStyle(color: Colors.grey[500], fontSize: 14)),
            );
          }
          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.callHistoryList.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final call = controller.callHistoryList[index];
              return _buildCallHistoryItem(call);
            },
          );
        }),
      ],
    );
  }

  Widget _buildCallHistoryItem(CallHistory call) {
    final duration = call.formattedDuration;
    final time = call.createDateTime != null
        ? '${call.createDateTime!.year}-${call.createDateTime!.month.toString().padLeft(2, '0')}-${call.createDateTime!.day.toString().padLeft(2, '0')}'
        : '--';
    final selfId = controller.selfUserId;
    final isOutgoing = selfId != null && call.createUserId == selfId;
    final iconAsset = isOutgoing
        ? 'asset/images/common/call_out.png' // 拨打-红色
        : 'asset/images/common/call_in.png'; // 接听-绿色
    final spendCoin = call.spendCoin ?? 0;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(color: const Color(0xFF1C1C1E), borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Image.asset(iconAsset, width: 28, height: 28, fit: BoxFit.contain),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(duration, style: const TextStyle(color: Colors.white, fontSize: 14)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Image.asset('asset/images/common/coin.png', width: 16, height: 16, fit: BoxFit.contain),
                    const SizedBox(width: 4),
                    Text('$spendCoin', style: TextStyle(color: Colors.amber[400], fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
          Center(
            child: Text(time, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Row(
      children: [
        // 消息
        GestureDetector(
          onTap: controller.sendMessage,
          child: Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF00C853)),
            child: const Icon(Icons.chat_bubble, color: Colors.white, size: 26),
          ),
        ),
        const SizedBox(width: 20),
        // 喜欢：由 followStatus 控制（0/1/2/3），进入详情按接口 followStatus 显示，点击后按接口返回值更新
        Obx(() {
          final followStatus = controller.followStatus;
          final isLiked = followStatus == 2 || followStatus == 3;
          return GestureDetector(
            onTap: controller.like,
            child: Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFFF1493)),
              child: Icon(isLiked ? Icons.favorite : Icons.favorite_border, color: Colors.white, size: 26),
            ),
          );
        }),
        const SizedBox(width: 20),
        // 视频通话
        Expanded(
          child: GestureDetector(
            onTap: controller.videoCall,
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF1493), Color(0xFF9C27B0)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.videocam, color: Colors.white, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Video Call',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DataRow {
  final IconData icon;
  final String? iconAsset;
  final String label;
  final String value;
  final Color? iconColor;
  _DataRow({required this.icon, this.iconAsset, required this.label, required this.value, this.iconColor});
}

/// 举报弹窗内容：单选列表 + Cancel/Submit
class _ReportDialogContent extends StatefulWidget {
  final List<DictItem> options;
  final UserDetailController controller;

  const _ReportDialogContent({required this.options, required this.controller});

  @override
  State<_ReportDialogContent> createState() => _ReportDialogContentState();
}

class _ReportDialogContentState extends State<_ReportDialogContent> {
  DictItem? _selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      decoration: BoxDecoration(color: const Color(0xFF2A2A4A), borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Report',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 20),
          ...widget.options.map((item) => _buildOption(item)),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Get.back(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFF1493), width: 1),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (_selected == null) {
                      ToastUtils.showError('Please select a report reason');
                      return;
                    }
                    widget.controller.submitReport(_selected!.value);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF1493), Color(0xFF9C27B0)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'Submit',
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
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOption(DictItem item) {
    final isSelected = _selected?.value == item.value;
    return GestureDetector(
      onTap: () => setState(() => _selected = item),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                item.label,
                style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 15, decoration: TextDecoration.none),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? Colors.white : Colors.grey.withOpacity(0.5),
                border: Border.all(color: isSelected ? Colors.white : Colors.grey, width: 1),
              ),
              child: isSelected ? const Icon(Icons.check, color: Color(0xFF4CAF50), size: 16) : null,
            ),
          ],
        ),
      ),
    );
  }
}
