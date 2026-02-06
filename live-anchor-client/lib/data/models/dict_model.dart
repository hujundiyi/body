/// 字典项模型
class DictItem {
  final int value;      // 值
  final String label;    // 标签
  final String? icon;   // 图标（可选）

  DictItem({
    required this.value,
    required this.label,
    this.icon,
  });

  factory DictItem.fromJson(Map<String, dynamic> json) {
    return DictItem(
      value: json['value'] as int,
      label: json['label'] as String,
      icon: json['icon'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'label': label,
      if (icon != null) 'icon': icon,
    };
  }
}

/// 字典响应模型
class DictResponse {
  final String dictType;           // 字典类型（如 "country", "gender", "anchor_self_tags"）
  final List<DictItem> dictItems;  // 字典项列表

  DictResponse({
    required this.dictType,
    required this.dictItems,
  });

  factory DictResponse.fromJson(Map<String, dynamic> json) {
    return DictResponse(
      dictType: json['dictType'] as String,
      dictItems: (json['dictItems'] as List<dynamic>?)
          ?.map((e) => DictItem.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dictType': dictType,
      'dictItems': dictItems.map((e) => e.toJson()).toList(),
    };
  }
}
