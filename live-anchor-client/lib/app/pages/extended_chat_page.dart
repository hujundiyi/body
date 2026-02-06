import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:extended_text_field/extended_text_field.dart';
import 'package:extended_text/extended_text.dart';
import '../controllers/extended_chat_controller.dart';

class ExtendedChatPage extends StatelessWidget {
  const ExtendedChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ExtendedChatController());
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rich text chat'),
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
                  final raw = messages[index];
                  final isMine = index % 2 == 0;
                  return Align(
                    alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isMine ? theme.colorScheme.primary.withValues(alpha: 0.15) : theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ExtendedText(
                        raw,
                        specialTextSpanBuilder: controller.spanBuilder,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  );
                },
              );
            }),
          ),
          _buildInputBar(controller, theme),
          _buildEmojiPanel(controller, theme),
        ],
      ),
    );
  }

  Widget _buildInputBar(ExtendedChatController controller, ThemeData theme) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, -2)),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.sticky_note_2_outlined),
            const SizedBox(width: 8),
            Expanded(
              child: ExtendedTextField(
                controller: controller.textController,
                focusNode: controller.inputFocusNode,
                maxLines: 4,
                minLines: 1,
                specialTextSpanBuilder: controller.spanBuilder,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  hintText: 'Type here, insert custom emoji [e0] [e1] ...',
                  border: OutlineInputBorder(borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(width: 8),
            FloatingActionButton.small(
              onPressed: controller.sendMessage,
              child: const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmojiPanel(ExtendedChatController controller, ThemeData theme) {
    return SizedBox(
      height: 220,
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
                color: theme.colorScheme.surface,
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
