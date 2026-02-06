import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/chat_controller.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ChatController());
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              final messages = controller.messages;
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  return Align(
                    alignment: msg.isMine ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: msg.isMine ? Get.theme.primaryColor.withOpacity(0.15) : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _buildRichContent(msg),
                    ),
                  );
                },
              );
            }),
          ),
          _buildInputBar(controller),
          Obx(() => controller.showEmojiPanel ? _buildEmojiPanel(controller) : const SizedBox.shrink()),
        ],
      ),
    );
  }

  Widget _buildRichContent(ChatMessage message) {
    final spans = <InlineSpan>[];
    for (final node in message.nodes) {
      if (node is TextNode) {
        spans.add(TextSpan(text: node.text, style: Get.textTheme.bodyMedium));
      } else if (node is EmojiNode) {
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Image.asset(node.assetPath, width: 22, height: 22),
          ),
        ));
      }
    }
    return RichText(text: TextSpan(children: spans, style: Get.textTheme.bodyMedium));
  }

  Widget _buildInputBar(ChatController controller) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Get.theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, -2)),
          ],
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.emoji_emotions_outlined),
              onPressed: controller.toggleEmojiPanel,
            ),
            Expanded(
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Obx(() {
                    final nodes = controller.parse(controller.inputText);
                    final spans = <InlineSpan>[];
                    for (final n in nodes) {
                      if (n is TextNode) {
                        spans.add(TextSpan(text: n.text, style: Get.textTheme.bodyMedium));
                      } else if (n is EmojiNode) {
                        spans.add(WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: Image.asset(n.assetPath, width: 22, height: 22),
                          ),
                        ));
                      }
                    }
                    return IgnorePointer(
                      ignoring: true,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        child: RichText(text: TextSpan(children: spans, style: Get.textTheme.bodyMedium)),
                      ),
                    );
                  }),
                  TextField(
                    controller: controller.textController,
                    focusNode: controller.inputFocusNode,
                    maxLines: 4,
                    minLines: 1,
                    inputFormatters: [controller.emojiInputFormatter],
                    style: Get.textTheme.bodyMedium?.copyWith(color: Colors.transparent),
                    cursorColor: Get.theme.colorScheme.primary,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      hintText: 'Type message, emoji and text supported',
                      border: OutlineInputBorder(borderSide: BorderSide.none),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FloatingActionButton.small(
              onPressed: () => controller.sendMessage(mine: true),
              child: const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmojiPanel(ChatController controller) {
    return SizedBox(
      height: 260,
      child: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 6,
          childAspectRatio: 1,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
        ),
        itemCount: controller.emojiAssets.length,
        itemBuilder: (context, index) {
          final asset = controller.emojiAssets[index];
          return InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => controller.insertEmoji(index),
            child: Container(
              decoration: BoxDecoration(
                color: Get.theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(8),
              child: Image.asset(asset),
            ),
          );
        },
      ),
    );
  }
}
