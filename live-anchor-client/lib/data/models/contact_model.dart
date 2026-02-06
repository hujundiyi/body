/// 联系方式模型
class ContactModel {
  final String? icon;
  final String? title;
  final String? number;

  ContactModel({
    this.icon,
    this.title,
    this.number,
  });

  factory ContactModel.fromJson(Map<String, dynamic> json) {
    return ContactModel(
      icon: json['icon'] as String?,
      title: json['title'] as String?,
      number: json['number'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'icon': icon,
      'title': title,
      'number': number,
    };
  }
}
