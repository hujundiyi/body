import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import '../controllers/chat_controller.dart';

class EmojiChatPage extends StatelessWidget {
  const EmojiChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ChatController());
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emoji chat'),
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
                        color: msg.isMine ? Get.theme.primaryColor.withValues(alpha: 0.15) : Colors.grey.shade200,
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
          Obx(() => controller.showEmojiPanel ? _buildEmojiPicker(controller) : const SizedBox.shrink()),
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
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, -2)),
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

  Widget _buildEmojiPicker(ChatController controller) {
    return SizedBox(
      height: 280,
      child: EmojiPicker(
        onEmojiSelected: (category, emoji) {
          final selection = controller.textController.selection;
          final text = controller.textController.text;
          final insert = emoji.emoji;
          final newText = selection.isValid
              ? text.replaceRange(selection.start, selection.end, insert)
              : text + insert;
          final cursor = selection.isValid ? selection.start + insert.length : newText.length;
          controller.textController.text = newText;
          controller.textController.selection = TextSelection.collapsed(offset: cursor);
        },
        config: Config(
          height: 280,
          checkPlatformCompatibility: true,
          emojiViewConfig: EmojiViewConfig(
            backgroundColor: Get.theme.colorScheme.surface,
            columns: 7,
            emojiSizeMax: 24,
          ),
          categoryViewConfig: const CategoryViewConfig(),
          searchViewConfig: const SearchViewConfig(),
          skinToneConfig: const SkinToneConfig(),
          emojiSet: (locale) => myCustomEmojis,
        ),
      ),
    );
  }

  static final List<CategoryEmoji> myCustomEmojis = [
    CategoryEmoji(Category.OBJECTS, const [
      Emoji('🌿', 'leaf'),
      Emoji('🌱', 'seedling'),
      Emoji('🌾', 'herb'),
      Emoji('🌼', 'blossom'),
      Emoji('🍀', 'four_leaf_clover'),
      Emoji('🌻', 'sunflower'),
      Emoji('🌹', 'rose'),
      Emoji('🌲', 'evergreen_tree'),
      Emoji('🌳', 'deciduous_tree'),
      Emoji('🌵', 'cactus'),
    ]),
  ];
}
