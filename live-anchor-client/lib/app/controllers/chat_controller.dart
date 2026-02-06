import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../core/base/base_controller.dart';

class ChatController extends BaseController {
  final textController = TextEditingController();
  final FocusNode inputFocusNode = FocusNode();
  final EmojiInputFormatter emojiInputFormatter = EmojiInputFormatter();

  final RxString _inputText = ''.obs;
  String get inputText => _inputText.value;

  final RxBool _showEmojiPanel = false.obs;
  bool get showEmojiPanel => _showEmojiPanel.value;

  final RxList<ChatMessage> _messages = <ChatMessage>[].obs;
  List<ChatMessage> get messages => _messages;

  // Emoji assets list from asset/images/chat
  final List<String> emojiAssets = const [
    'asset/images/chat/Group@3x.png',
    'asset/images/chat/Group@3x(1).png',
    'asset/images/chat/Group@3x(2).png',
    'asset/images/chat/Group@3x(3).png',
    'asset/images/chat/Group@3x(4).png',
    'asset/images/chat/Group@3x(5).png',
    'asset/images/chat/Group@3x(6).png',
    'asset/images/chat/Group@3x(7).png',
    'asset/images/chat/Group@3x(8).png',
    'asset/images/chat/Group@3x(9).png',
    'asset/images/chat/Group@3x(10).png',
    'asset/images/chat/Group@3x(11).png',
    'asset/images/chat/Group@3x(12).png',
    'asset/images/chat/Group@3x(13).png',
    'asset/images/chat/Group@3x(14).png',
    'asset/images/chat/Group@3x(15).png',
    'asset/images/chat/Group@3x(16).png',
    'asset/images/chat/Group@3x(17).png',
    'asset/images/chat/Group@3x(18).png',
    'asset/images/chat/Group@3x(19).png',
    'asset/images/chat/Group@3x(20).png',
    'asset/images/chat/Group@3x(21).png',
    'asset/images/chat/Group@3x(22).png',
  ];

  @override
  void onControllerInit() {
    super.onControllerInit();
    textController.addListener(() {
      _inputText.value = textController.text;
    });
  } 

  @override
  void onControllerClose() {
    textController.dispose();
    inputFocusNode.dispose();
    super.onControllerClose();
  }

  void toggleEmojiPanel() {
    _showEmojiPanel.value = !_showEmojiPanel.value;
    if (_showEmojiPanel.value) {
      inputFocusNode.unfocus();
    } else {
      inputFocusNode.requestFocus();
    }
  }

  void insertEmoji(int index) {
    if (index < 0 || index >= emojiAssets.length) return;
    final code = ':e$index:'; // placeholder code in text
    final selection = textController.selection;
    final text = textController.text;
    final newText = selection.isValid
        ? text.replaceRange(selection.start, selection.end, code)
        : text + code;
    final cursor = (selection.isValid ? selection.start : newText.length);
    textController.text = newText;
    textController.selection = TextSelection.collapsed(offset: cursor + code.length);
  }

  void sendMessage({bool mine = true}) {
    final raw = textController.text.trim();
    if (raw.isEmpty) return;

    final nodes = _parseInline(raw);
    _messages.add(ChatMessage(nodes: nodes, isMine: mine, timestamp: DateTime.now()));
    textController.clear();
  }

  List<InlineNode> _parseInline(String input) {
    final List<InlineNode> nodes = [];
    final regex = RegExp(r':e(\d+):');
    int lastIndex = 0;
    for (final match in regex.allMatches(input)) {
      if (match.start > lastIndex) {
        nodes.add(TextNode(input.substring(lastIndex, match.start)));
      }
      final idx = int.tryParse(match.group(1) ?? '') ?? -1;
      if (idx >= 0 && idx < emojiAssets.length) {
        nodes.add(EmojiNode(emojiAssets[idx]));
      } else {
        nodes.add(TextNode(input.substring(match.start, match.end)));
      }
      lastIndex = match.end;
    }
    if (lastIndex < input.length) {
      nodes.add(TextNode(input.substring(lastIndex)));
    }
    return nodes;
  }

  List<InlineNode> parse(String input) => _parseInline(input);
}

class ChatMessage {
  final List<InlineNode> nodes;
  final bool isMine;
  final DateTime timestamp;
  ChatMessage({required this.nodes, required this.isMine, required this.timestamp});
}

abstract class InlineNode {}

class TextNode extends InlineNode {
  final String text;
  TextNode(this.text);
}

class EmojiNode extends InlineNode {
  final String assetPath;
  EmojiNode(this.assetPath);
}

class EmojiInputFormatter extends TextInputFormatter {
  final RegExp _token = RegExp(r':e(\d+):');

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    // Handle backspace within an emoji token: remove the whole token
    if (oldValue.text.length > newValue.text.length && newValue.selection.isCollapsed) {
      final delPos = newValue.selection.baseOffset; // position after deletion
      for (final m in _token.allMatches(oldValue.text)) {
        if (delPos >= m.start && delPos <= m.end) {
          final replaced = oldValue.text.replaceRange(m.start, m.end, '');
          return TextEditingValue(
            text: replaced,
            selection: TextSelection.collapsed(offset: m.start),
          );
        }
      }
    }

    // Prevent caret staying inside a token after arbitrary edits
    for (final m in _token.allMatches(newValue.text)) {
      final offset = newValue.selection.baseOffset;
      if (offset > m.start && offset < m.end) {
        return TextEditingValue(
          text: newValue.text,
          selection: TextSelection.collapsed(offset: m.end),
          composing: TextRange.empty,
        );
      }
    }
    return newValue;
  }
}
