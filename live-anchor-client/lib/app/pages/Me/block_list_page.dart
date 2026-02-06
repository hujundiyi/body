import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/network/anchor_api_service.dart';
import '../../../core/services/blocked_user_service.dart';
import '../../../core/utils/toast_utils.dart';
import '../../widgets/avatar_network_image.dart';

class BlockedUserItem {
  final int userId;
  final String name;
  final String avatar;

  const BlockedUserItem({
    required this.userId,
    required this.name,
    required this.avatar,
  });
}

class BlockListPage extends StatefulWidget {
  const BlockListPage({super.key});

  @override
  State<BlockListPage> createState() => _BlockListPageState();
}

class _BlockListPageState extends State<BlockListPage> {
  final AnchorAPIService _api = AnchorAPIService.shared;
  final List<BlockedUserItem> _items = [];
  final Set<int> _removingIds = <int>{};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBlackList();
  }

  Future<void> _loadBlackList() async {
    setState(() => _isLoading = true);
    try {
      final list = await _api.getBlackList(page: 1, size: 200);
      final items = <BlockedUserItem>[];
      for (final raw in list) {
        final userId = _parseUserId(raw);
        if (userId == null || userId <= 0) continue;
        items.add(BlockedUserItem(
          userId: userId,
          name: _parseName(raw),
          avatar: _parseAvatar(raw),
        ));
      }
      setState(() {
        _items
          ..clear()
          ..addAll(items);
      });
    } catch (e) {
      ToastUtils.showError('Failed to load blocked list');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  int? _parseUserId(Map<String, dynamic> raw) {
    final id = raw['userId'] ?? raw['blackUserId'] ?? raw['id'];
    if (id is int) return id;
    if (id is num) return id.toInt();
    if (id is String) return int.tryParse(id.trim());
    return null;
  }

  String _parseName(Map<String, dynamic> raw) {
    return (raw['nickname'] ??
            raw['name'] ??
            raw['userName'] ??
            raw['username'] ??
            raw['nickName'])
        ?.toString()
        .trim()
        .isNotEmpty ==
        true
        ? (raw['nickname'] ??
            raw['name'] ??
            raw['userName'] ??
            raw['username'] ??
            raw['nickName'])
            .toString()
            .trim()
        : 'Unknown';
  }

  String _parseAvatar(Map<String, dynamic> raw) {
    return (raw['avatar'] ??
            raw['headImg'] ??
            raw['head_img'] ??
            raw['portrait'] ??
            raw['photo'])
        ?.toString() ??
        '';
  }

  int? _blackStatusCode(dynamic result) {
    if (result == null) return null;
    if (result is int) return result;
    if (result is num) return result.toInt();
    if (result is String) return int.tryParse(result.trim());
    if (result is Map) {
      final v = result['status'] ?? result['value'] ?? result['data'];
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v.trim());
    }
    return null;
  }

  Future<void> _removeBlocked(BlockedUserItem item) async {
    if (_removingIds.contains(item.userId)) return;
    setState(() => _removingIds.add(item.userId));
    try {
      final result = await _api.blackStatus(blackUserId: item.userId, black: false);
      final code = _blackStatusCode(result);
      // 如果 data 不是 1 或 3，仍将该项从列表中移除
      if (code != null && code != 1 && code != 3) {
        setState(() {
          _items.removeWhere((e) => e.userId == item.userId);
        });
        BlockedUserService.shared.removeBlocked(item.userId);
        ToastUtils.showSuccess('Removed');
        return;
      }
      setState(() {
        _items.removeWhere((e) => e.userId == item.userId);
      });
      BlockedUserService.shared.removeBlocked(item.userId);
      ToastUtils.showSuccess('Removed');
    } catch (e) {
      ToastUtils.showError('Failed to remove');
    } finally {
      setState(() => _removingIds.remove(item.userId));
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
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Blocklist',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF1493)))
          : _items.isEmpty
              ? const Center(
                  child: Text(
                    'No blocked users',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    final isRemoving = _removingIds.contains(item.userId);
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2A4A),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          AvatarNetworkImage(
                            imageUrl: item.avatar.isNotEmpty ? item.avatar : null,
                            size: 46,
                            placeholderAssetImage: 'asset/images/common/avatar_placeholder.svg',
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              item.name,
                              style: const TextStyle(color: Colors.white, fontSize: 16),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),
                          TextButton(
                            onPressed: isRemoving ? null : () => _removeBlocked(item),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: const Color(0xFF3A3A5A),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: isRemoving
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text('Remove'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
