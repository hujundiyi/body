import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'faq_detail_page.dart';

/// FAQ 列表页（第一张图：banner + 3 个选项）
class FaqPage extends StatelessWidget {
  const FaqPage({super.key});

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
        title: const Text(
          'FAQ',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildBanner(),
            const SizedBox(height: 20),
            _buildFaqItem(
              title: 'How to get more gifts',
              onTap: () => Get.to(() => const FaqDetailPage(
                pageTitle: 'Skill',
                topicTitle: 'How to get more gifts',
                icon: Icons.card_giftcard,
                iconColor: Color(0xFFFFB74D),
                tips: [
                  'Maintain a close relationship with users and respond to every message they send in a timely manner.',
                  'Learn to compliment every user and show them how charming and sexy you are.',
                  'You can ask them for gifts when necessary and promise to provide them with more exciting performances after receiving the gifts.',
                  'Be enthusiastic to every user so that you can get more gift income.',
                ],
              )),
            ),
            const SizedBox(height: 12),
            _buildFaqItem(
              title: 'How to convert new users into intimate users',
              onTap: () => Get.to(() => const FaqDetailPage(
                pageTitle: 'Skill',
                topicTitle: 'How to convert new users into intimate users',
                icon: Icons.favorite,
                iconColor: Color(0xFFE91E63),
                tips: [
                  'Respond positively to every message the user sends, tease the user with verbal pictures when appropriate, and proactively ask the user to make a video call.',
                  'Make video calls to new users and let them feel your enthusiasm.',
                  'Open match calls, answer every match call invitation, do not be naked in the match calls, stimulate users to recharge and convert to official calls, you will get an extra conversion bonus for every match call converted to official calls.',
                ],
              )),
            ),
            const SizedBox(height: 12),
            _buildFaqItem(
              title: 'How to extend the duration of the call',
              onTap: () => Get.to(() => const FaqDetailPage(
                pageTitle: 'Skill',
                topicTitle: 'How to extend the duration of the call',
                icon: Icons.phone_in_talk,
                iconColor: Color(0xFFFF5722),
                tips: [
                  'Do not show your sexy first after entering the call, first tease the user through words and expressions.',
                  'Praise the user as much as possible, slow down the user\'s excitement, and then slowly show your sexy parts when appropriate.',
                  'Show the user that you are not satisfied, so that they can stay with you longer in the video chat.',
                  'Build a long and stable relationship with the user, and talk about more topics related to your hobbies when you talk to them.',
                ],
              )),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF9C27B0), Color(0xFFFF1493)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            child: Image.asset('asset/images/common/coin.png', width: 28, height: 28, fit: BoxFit.contain),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Image.asset('asset/images/common/coin.png', width: 28, height: 28, fit: BoxFit.contain),
          ),
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'How to become the most profitable anchor',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqItem({required String title, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A4A),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 14),
          ],
        ),
      ),
    );
  }
}
