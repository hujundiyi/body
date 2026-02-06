/// picture/getList 接口单条数据
class PictureListItem {
  final int? id;
  final String? url;
  final bool? cover;
  final int? type; // 0: Daily, 1: Sexy
  final int? coin;
  final bool? isPay;

  PictureListItem({this.id, this.url, this.cover, this.type, this.coin, this.isPay});

  factory PictureListItem.fromJson(Map<String, dynamic> json) {
    return PictureListItem(
      id: json['id'] as int?,
      url: json['url'] as String?,
      cover: json['cover'] as bool?,
      type: json['type'] as int?,
      coin: json['coin'] as int?,
      isPay: json['isPay'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'cover': cover ?? false,
      'type': type ?? 0,
      'coin': coin ?? 0,
      'isPay': isPay ?? false,
    };
  }
}
