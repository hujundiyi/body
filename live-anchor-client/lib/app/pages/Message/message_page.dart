import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/message_list_controller.dart';
import '../../controllers/call_history_controller.dart';
import 'message_list_view.dart';
import 'call_history_view.dart';

/// 消息页面（包含 Message 和 Call History 两个 Tab）
class MessagePage extends StatefulWidget {
  const MessagePage({super.key});

  @override
  State<MessagePage> createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage> {
  late final MessageListController messageListController;
  late final CallHistoryController callHistoryController;
  late final PageController _pageController;
  
  // 当前选中的 tab 索引
  final RxInt currentTabIndex = 0.obs;

  @override
  void initState() {
    super.initState();
    messageListController = Get.put(MessageListController());
    callHistoryController = Get.put(CallHistoryController());
    _pageController = PageController(initialPage: currentTabIndex.value);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// 切换 Tab
  void switchTab(int index) {
    currentTabIndex.value = index;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:  Colors.black, // 深色背景
      body: SafeArea(
        child: Column(
          children: [
            _buildTabHeader(),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  switchTab(index);
                },
                children: [
                  MessageListView(controller: messageListController),
                  CallHistoryView(controller: callHistoryController),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建 Tab 头部
  Widget _buildTabHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Message Tab
          Obx(() => _buildTabItem(
            title: 'Message',
            index: 0,
            isSelected: currentTabIndex.value == 0,
          )),
          const SizedBox(width: 24),
          // Call History Tab
          Obx(() => _buildTabItem(
            title: 'Call History',
            index: 1,
            isSelected: currentTabIndex.value == 1,
          )),
        ],
      ),
    );
  }

  /// 构建单个 Tab 项
  Widget _buildTabItem({
    required String title,
    required int index,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        switchTab(index);
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[400],
              fontSize: isSelected ? 18 : 16,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const SizedBox(height: 4),
          // 下划线指示器
          Container(
            width: 24,
            height: 3,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFFF1493) : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}
