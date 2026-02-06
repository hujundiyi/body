import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../routes/app_routes.dart';
import '../controllers/home_controller.dart';

/// 主页
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // 初始化控制器
    final controller = Get.put(HomeController());
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weeder'),
        backgroundColor: Get.theme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: controller.showUserInfo,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: controller.logout,
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 欢迎信息
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome to Weeder',
                        style: Get.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Smart weeding app to help you manage plants',
                        style: Get.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // 计数器演示
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        'Counter demo',
                        style: Get.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${controller.counter}',
                        style: Get.textTheme.headlineLarge?.copyWith(
                          color: Get.theme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: controller.decrementCounter,
                            icon: const Icon(Icons.remove),
                            label: const Text('Decrease'),
                          ),
                          ElevatedButton.icon(
                            onPressed: controller.resetCounter,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reset'),
                          ),
                          ElevatedButton.icon(
                            onPressed: controller.incrementCounter,
                            icon: const Icon(Icons.add),
                            label: const Text('Increase'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // 功能按钮
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _buildFeatureCard(
                      icon: Icons.camera_alt,
                      title: 'Photo recognition',
                      subtitle: 'Identify weed types',
                      coinBalance: controller.user?.walletBalance ?? 0,
                      onTap: () => controller.showSuccess('Photo recognition'),
                    ),
                  _buildFeatureCard(
                    icon: Icons.analytics,
                    title: 'Data analysis',
                    subtitle: 'View weeding stats',
                    coinBalance: controller.user?.walletBalance ?? 0,
                    onTap: () => controller.showSuccess('Data analysis'),
                  ),
                  _buildFeatureCard(
                    icon: Icons.settings,
                    title: 'Settings',
                    subtitle: 'App settings',
                    coinBalance: controller.user?.walletBalance ?? 0,
                    onTap: () => controller.showSuccess('Settings'),
                  ),
                  _buildFeatureCard(
                    icon: Icons.chat_bubble_outline,
                    title: 'Chat',
                    subtitle: 'Messages',
                    coinBalance: controller.user?.walletBalance ?? 0,
                    onTap: () => Get.toNamed(AppRoutes.chat),
                  ),
                  _buildFeatureCard(
                    icon: Icons.emoji_emotions,
                    title: 'Emoji chat',
                    subtitle: 'Use EmojiPicker',
                    coinBalance: controller.user?.walletBalance ?? 0,
                    onTap: () => Get.toNamed(AppRoutes.emojiPickerChat),
                  ),
                  _buildFeatureCard(
                    icon: Icons.text_fields,
                    title: 'Rich text chat',
                    subtitle: 'ExtendedTextField',
                    coinBalance: controller.user?.walletBalance ?? 0,
                    onTap: () => Get.toNamed(AppRoutes.extendedChat),
                  ),
                  _buildFeatureCard(
                    icon: Icons.help,
                    title: 'Help',
                    subtitle: 'User guide',
                    coinBalance: controller.user?.walletBalance ?? 0,
                    onTap: () => controller.showSuccess('Help'),
                  ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: controller.incrementCounter,
        tooltip: 'Increase count',
        child: const Icon(Icons.add),
      ),
    );
  }
  
  /// 构建功能卡片
  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required int coinBalance,
  }) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: Get.theme.primaryColor,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Get.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              if (coinBalance > 0) ...[
                const SizedBox(height: 6),
                Row(
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
                      '$coinBalance',
                      style: Get.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFFFF8C00),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Get.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
