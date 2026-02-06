import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:weeder/data/models/user_model_entity.dart';
import '../../controllers/user_list_controller.dart';
import '../../widgets/avatar_network_image.dart';

/// 用户列表页面
class UserListPage extends GetView<UserListController> {
  const UserListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildTabBar(),
            Expanded(child: _buildTabBarView()),
          ],
        ),
      ),
    );
  }

  /// 构建 TabBar
  Widget _buildTabBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TabBar(
        controller: controller.tabController,
        tabs: const [
          Tab(text: 'All'),
          Tab(text: 'Intimate'),
          Tab(text: 'Follower'),
        ],
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey,
        labelStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.normal),
        indicatorColor: const Color(0xFFFF1493),
        indicatorSize: TabBarIndicatorSize.label,
        indicatorWeight: 3,
        dividerColor: Colors.transparent,
      ),
    );
  }

  /// 构建 TabBarView
  Widget _buildTabBarView() {
    return TabBarView(
      controller: controller.tabController,
      children: [_buildUserListView(0), _buildUserListView(1), _buildUserListView(2)],
    );
  }

  /// 构建用户列表视图
  Widget _buildUserListView(int tabIndex) {
    return Obx(() {
      final userList = controller.getUserListByTab(tabIndex);
      final isLoading = controller.getLoadingByTab(tabIndex);

      if (isLoading && userList.isEmpty) {
        return const Center(child: CircularProgressIndicator(color: Color(0xFFFF1493)));
      }

      if (userList.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_off_outlined, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('No users', style: TextStyle(color: Colors.grey, fontSize: 16)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => controller.refreshListByTab(tabIndex),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF1493)),
                child: const Text('Refresh'),
              ),
            ],
          ),
        );
      }

      final hasMore = controller.getHasMoreByTab(tabIndex);
      final scrollController = controller.getScrollControllerByTab(tabIndex);

      return RefreshIndicator(
        onRefresh: () => controller.refreshListByTab(tabIndex),
        color: const Color(0xFFFF1493),
        child: ListView.builder(
          controller: scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: userList.length + (hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == userList.length) {
              return _buildLoadMoreFooter(tabIndex);
            }
            final user = userList[index];
            return _buildUserListItem(user);
          },
        ),
      );
    });
  }

  /// 构建底部“加载更多”占位（上拉时显示 loading 或“上拉加载更多”）
  Widget _buildLoadMoreFooter(int tabIndex) {
    return Obx(() {
      final loading = controller.getLoadingByTab(tabIndex);
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Color(0xFFFF1493),
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  'Pull up for more',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                ),
        ),
      );
    });
  }

  /// 构建用户列表项
  Widget _buildUserListItem(UserModelEntity user) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          // 左侧头像+信息，点击进入详情
          Expanded(
            child: GestureDetector(
              onTap: () => controller.openUserDetail(user),
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  _buildAvatar(user),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 昵称
                        Text(
                          user.nickname ?? '',
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        // 金币（接口字段 coinBalance）
                        if (user.coinBalance > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF8C00),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Image.asset(
                                    'asset/images/common/coin.png',
                                    width: 14,
                                    height: 14,
                                    fit: BoxFit.contain,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${user.coinBalance}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 右侧按钮
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 聊天按钮
              GestureDetector(
                onTap: () => controller.startChat(user),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF00C853)),
                  child: const Icon(Icons.chat_bubble, color: Colors.white, size: 22),
                ),
              ),
              const SizedBox(width: 12),
              // 视频按钮
              GestureDetector(
                onTap: () => controller.startVideoCall(user),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFFF1493)),
                  child: const Icon(Icons.videocam, color: Colors.white, size: 24),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建头像（带在线状态，占位图）
  Widget _buildAvatar(UserModelEntity user) {
    final avatarUrl = user.avatar.isNotEmpty ? user.avatar : null;
    return Stack(
      children: [
        // 头像外圈（渐变边框）
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFFFF1493), Color(0xFFFF69B4)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: Colors.transparent, width: 1),
          ),
          padding: const EdgeInsets.all(1),
          child: AvatarNetworkImage(
            imageUrl: avatarUrl,
            size: 54,
            placeholderAssetImage: 'asset/images/common/avatar_placeholder.svg',
            placeholderColor: const Color(0xFF4A4A5A),
            placeholderIconColor: Colors.white54,
          ),
        ),
        // 在线状态小圆点（onlineStatus==0 表示在线）
        if (user.onlineStatus == 0)
          Positioned(
            right: 2,
            bottom: 2,
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
    );
  }

  /// 获取国旗 emoji
  String _getCountryFlag(int? countryCode) {
    // 国家代码映射表
    const countryMap = {
      // 主要国家
      840: 'US', // United States
      826: 'GB', // United Kingdom
      124: 'CA', // Canada
      156: 'CN', // China
      356: 'IN', // India
      276: 'DE', // Germany
      250: 'FR', // France
      392: 'JP', // Japan
      410: 'KR', // South Korea
      36: 'AU', // Australia (ISO 3166-1 numeric: 036)
      554: 'NZ', // New Zealand
      // 欧洲国家
      724: 'ES', // Spain
      380: 'IT', // Italy
      643: 'RU', // Russia
      528: 'NL', // Netherlands
      56: 'BE', // Belgium
      756: 'CH', // Switzerland
      40: 'AT', // Austria
      752: 'SE', // Sweden
      578: 'NO', // Norway
      208: 'DK', // Denmark
      246: 'FI', // Finland
      616: 'PL', // Poland
      620: 'PT', // Portugal
      300: 'GR', // Greece
      372: 'IE', // Ireland
      642: 'RO', // Romania
      203: 'CZ', // Czech Republic
      348: 'HU', // Hungary
      100: 'BG', // Bulgaria
      191: 'HR', // Croatia
      688: 'RS', // Serbia
      703: 'SK', // Slovakia
      705: 'SI', // Slovenia
      440: 'LT', // Lithuania
      428: 'LV', // Latvia
      233: 'EE', // Estonia
      112: 'BY', // Belarus
      398: 'KZ', // Kazakhstan
      804: 'UA', // Ukraine
      // 亚洲国家
      608: 'PH', // Philippines
      764: 'TH', // Thailand
      704: 'VN', // Vietnam
      360: 'ID', // Indonesia
      458: 'MY', // Malaysia
      702: 'SG', // Singapore
      784: 'AE', // United Arab Emirates
      682: 'SA', // Saudi Arabia
      376: 'IL', // Israel
      792: 'TR', // Turkey
      586: 'PK', // Pakistan
      50: 'BD', // Bangladesh
      144: 'LK', // Sri Lanka
      104: 'MM', // Myanmar
      116: 'KH', // Cambodia
      418: 'LA', // Laos
      496: 'MN', // Mongolia
      524: 'NP', // Nepal
      4: 'AF', // Afghanistan
      368: 'IQ', // Iraq
      364: 'IR', // Iran
      400: 'JO', // Jordan
      422: 'LB', // Lebanon
      760: 'SY', // Syria
      887: 'YE', // Yemen
      512: 'OM', // Oman
      414: 'KW', // Kuwait
      634: 'QA', // Qatar
      48: 'BH', // Bahrain
      // 美洲国家
      76: 'BR', // Brazil
      484: 'MX', // Mexico
      32: 'AR', // Argentina
      152: 'CL', // Chile
      170: 'CO', // Colombia
      604: 'PE', // Peru
      862: 'VE', // Venezuela
      // 非洲国家
      710: 'ZA', // South Africa
      566: 'NG', // Nigeria
      450: 'MG', // Madagascar
      120: 'CM', // Cameroon
      384: 'CI', // Côte d'Ivoire
      686: 'SN', // Senegal
      466: 'ML', // Mali
      854: 'BF', // Burkina Faso
      562: 'NE', // Niger
      404: 'KE', // Kenya
      834: 'TZ', // Tanzania
      800: 'UG', // Uganda
      894: 'ZM', // Zambia
      716: 'ZW', // Zimbabwe
      24: 'AO', // Angola
      508: 'MZ', // Mozambique
      504: 'MA', // Morocco
      12: 'DZ', // Algeria
      788: 'TN', // Tunisia
      434: 'LY', // Libya
      729: 'SD', // Sudan
      231: 'ET', // Ethiopia
      288: 'GH', // Ghana
      // 其他
      818: 'EG', // Egypt
    };

    final code = countryMap[countryCode];
    if (code == null || code.length != 2) {
      return '🌍';
    }

    // 将国家代码转换为 emoji 国旗
    final int firstLetter = code.codeUnitAt(0) - 0x41 + 0x1F1E6;
    final int secondLetter = code.codeUnitAt(1) - 0x41 + 0x1F1E6;
    return String.fromCharCode(firstLetter) + String.fromCharCode(secondLetter);
  }
}
