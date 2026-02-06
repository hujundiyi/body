import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:extended_text_field/extended_text_field.dart';
import '../../core/base/base_controller.dart';

class ExtendedChatController extends BaseController {
  final textController = TextEditingController();
  final FocusNode inputFocusNode = FocusNode();

  final RxList<String> _messages = <String>[].obs;
  List<String> get messages => _messages;

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

  late final MySpecialTextSpanBuilder spanBuilder = MySpecialTextSpanBuilder(emojiAssets: emojiAssets);

  @override
  void onControllerClose() {
    textController.dispose();
    inputFocusNode.dispose();
    super.onControllerClose();
  }

  void insertEmoji(int index) {
    if (index < 0 || index >= emojiAssets.length) return;
    final token = '[e$index]';
    final sel = textController.selection;
    final text = textController.text;
    final newText = sel.isValid ? text.replaceRange(sel.start, sel.end, token) : text + token;
    final cursor = sel.isValid ? sel.start + token.length : newText.length;
    textController.text = newText;
    textController.selection = TextSelection.collapsed(offset: cursor);
  }

  void sendMessage() {
    final raw = textController.text.trim();
    if (raw.isEmpty) return;
    _messages.add(raw);
    textController.clear();
  }
}

class MySpecialTextSpanBuilder extends SpecialTextSpanBuilder {
  final List<String> emojiAssets;
  MySpecialTextSpanBuilder({required this.emojiAssets});

  @override
  SpecialText? createSpecialText(String flag, {TextStyle? textStyle, SpecialTextGestureTapCallback? onTap, int? index}) {
    if (flag.isEmpty) return null;
    if (isStart(flag, EmojiText.flag)) {
      final start = (index ?? 0) - (EmojiText.flag.length - 1);
      return EmojiText(textStyle, emojiAssets, start: start);
    }
    return null;
  }
}

class EmojiText extends SpecialText {
  static const String flag = '[e';
  final int start;
  final List<String> emojiAssets;

  EmojiText(TextStyle? textStyle, this.emojiAssets, {required this.start})
      : super(flag, ']', textStyle);

  @override
  InlineSpan finishText() {
    final raw = toString();
    final m = RegExp(r"^\[e(\d+)\]").firstMatch(raw);
    final idx = m != null ? int.tryParse(m.group(1)!) ?? -1 : -1;
    if (idx >= 0 && idx < emojiAssets.length) {
      return ImageSpan(
        AssetImage(emojiAssets[idx]),
        imageWidth: 22,
        imageHeight: 22,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        start: start,
        actualText: raw,
        alignment: PlaceholderAlignment.middle,
      );
    }
    return TextSpan(text: raw, style: textStyle);
  }
}
