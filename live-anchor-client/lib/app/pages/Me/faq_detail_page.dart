import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// FAQ/Skill 详情页（第二、三、四张图：图标 + 标题 + 编号列表，内容可配置）
class FaqDetailPage extends StatelessWidget {
  const FaqDetailPage({
    super.key,
    required this.pageTitle,
    required this.topicTitle,
    required this.icon,
    required this.tips,
    this.iconColor = Colors.white54,
  });

  final String pageTitle;
  final String topicTitle;
  final IconData icon;
  final Color iconColor;
  final List<String> tips;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: Text(
          pageTitle,
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        child: Column(
          children: [
            const SizedBox(height: 24),
            Icon(icon, size: 80, color: iconColor),
            const SizedBox(height: 24),
            Text(
              topicTitle,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            ...tips.asMap().entries.map((entry) {
              final index = entry.key;
              final text = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${index + 1}.',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        text,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
