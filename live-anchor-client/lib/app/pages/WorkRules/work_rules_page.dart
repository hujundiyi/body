import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../controllers/work_rules_controller.dart';

/// Work Rules 规则页（弹窗形式，加载 H5 URL）
class WorkRulesPage extends StatelessWidget {
  const WorkRulesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<WorkRulesController>();

    return Scaffold(
      backgroundColor: const Color(0xFF1A0D2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A0D2E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Rule',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              if (controller.isLoading) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF1493)),
                  ),
                );
              }
              final url = controller.h5Url.value;
              if (url == null || url.isEmpty) {
                return Center(
                  child: Text(
                    'Failed to load rules',
                    style: TextStyle(color: Colors.grey[400], fontSize: 16),
                  ),
                );
              }
              return ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: _RuleWebView(url: url),
              );
            }),
          ),
          // 底部按钮
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            decoration: const BoxDecoration(
              color: Color(0xFF1A0D2E),
            ),
            child: Obx(() {
              return GestureDetector(
                onTap: controller.isLoading ? null : controller.agreeAndContinue,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: controller.isLoading
                        ? null
                        : const LinearGradient(
                            colors: [Color(0xFFFF1493), Color(0xFFFF6B35)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                    color: controller.isLoading ? Colors.grey[700] : null,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Agree and continue',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.double_arrow,
                        color: Colors.white.withOpacity(0.9),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

/// 规则 H5 WebView（单次创建 controller，避免重复加载）
class _RuleWebView extends StatefulWidget {
  final String url;

  const _RuleWebView({required this.url});

  @override
  State<_RuleWebView> createState() => _RuleWebViewState();
}

class _RuleWebViewState extends State<_RuleWebView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: _controller);
  }
}
