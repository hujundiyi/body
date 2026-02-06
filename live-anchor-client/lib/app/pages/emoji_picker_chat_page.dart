import 'package:flutter/material.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';

class EmojiPickerChatPage extends StatefulWidget {
  const EmojiPickerChatPage({super.key});

  @override
  State<EmojiPickerChatPage> createState() => _EmojiPickerChatPageState();
}

class _EmojiPickerChatPageState extends State<EmojiPickerChatPage> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _showEmojiPanel = false;

  final List<_Message> _messages = [];

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _toggleEmojiPanel() {
    setState(() {
      _showEmojiPanel = !_showEmojiPanel;
      if (_showEmojiPanel) {
        _focusNode.unfocus();
      } else {
        _focusNode.requestFocus();
      }
    });
  }

  void _insertEmoji(String emojiChar) {
    final selection = _textController.selection;
    final text = _textController.text;
    final insert = emojiChar;
    final newText = selection.isValid
        ? text.replaceRange(selection.start, selection.end, insert)
        : text + insert;
    final cursor = selection.isValid ? selection.start + insert.length : newText.length;
    setState(() {
      _textController.text = newText;
      _textController.selection = TextSelection.collapsed(offset: cursor);
    });
  }

  void _sendMessage() {
    final raw = _textController.text.trim();
    if (raw.isEmpty) return;
    setState(() {
      _messages.add(_Message(text: raw, isMine: true, timestamp: DateTime.now()));
      _textController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('EmojiPicker chat'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return Align(
                  alignment: msg.isMine ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: msg.isMine
                          ? theme.colorScheme.primary.withValues(alpha: 0.15)
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      msg.text,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                );
              },
            ),
          ),
          _buildInputBar(theme),
          if (_showEmojiPanel) _buildEmojiPicker(theme),
        ],
      ),
    );
  }

  Widget _buildInputBar(ThemeData theme) {
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
            IconButton(
              icon: const Icon(Icons.emoji_emotions_outlined),
              onPressed: _toggleEmojiPanel,
            ),
            Expanded(
              child: TextField(
                controller: _textController,
                focusNode: _focusNode,
                maxLines: 4,
                minLines: 1,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  hintText: 'Type message, system emoji supported',
                  border: OutlineInputBorder(borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(width: 8),
            FloatingActionButton.small(
              onPressed: _sendMessage,
              child: const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmojiPicker(ThemeData theme) {
    return SizedBox(
      height: 280,
      child: EmojiPicker(
        onEmojiSelected: (category, emoji) {
          _insertEmoji(emoji.emoji);
        },
        config: Config(
          height: 280,
          checkPlatformCompatibility: true,
          emojiViewConfig: EmojiViewConfig(
            backgroundColor: theme.colorScheme.surface,
            columns: 7,
            emojiSizeMax: 24,
          ),
          categoryViewConfig: const CategoryViewConfig(),
          searchViewConfig: const SearchViewConfig(),
          skinToneConfig: const SkinToneConfig(),
        ),
      ),
    );
  }
}

class _Message {
  final String text;
  final bool isMine;
  final DateTime timestamp;
  _Message({required this.text, required this.isMine, required this.timestamp});
}
