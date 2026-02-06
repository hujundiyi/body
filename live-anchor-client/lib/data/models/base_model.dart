import 'package:json_annotation/json_annotation.dart';

/// 基础模型类
/// 提供通用的JSON序列化方法
abstract class BaseModel {
  /// 从JSON创建模型
  Map<String, dynamic> toJson();
  
  /// 转换为JSON
  factory BaseModel.fromJson(Map<String, dynamic> json) {
    throw UnimplementedError('子类必须实现fromJson方法');
  }
  
  /// 复制模型并修改部分字段
  BaseModel copyWith();
  
  @override
  String toString();
  
  @override
  bool operator ==(Object other);
  
  @override
  int get hashCode;
}

/// 分页模型
@JsonSerializable(genericArgumentFactories: true)
class PaginationModel<T> {
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int itemsPerPage;
  final List<T> items;
  
  const PaginationModel({
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.itemsPerPage,
    required this.items,
  });
  
  /// 从JSON创建分页模型
  factory PaginationModel.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) {
    return PaginationModel<T>(
      currentPage: json['currentPage'] as int,
      totalPages: json['totalPages'] as int,
      totalItems: json['totalItems'] as int,
      itemsPerPage: json['itemsPerPage'] as int,
      items: (json['items'] as List)
          .map((item) => fromJsonT(item))
          .toList(),
    );
  }
  
  /// 转换为JSON
  Map<String, dynamic> toJson(Object Function(T value) toJsonT) {
    return {
      'currentPage': currentPage,
      'totalPages': totalPages,
      'totalItems': totalItems,
      'itemsPerPage': itemsPerPage,
      'items': items.map((item) => toJsonT(item)).toList(),
    };
  }
  
  /// 是否有下一页
  bool get hasNextPage => currentPage < totalPages;
  
  /// 是否有上一页
  bool get hasPreviousPage => currentPage > 1;
  
  @override
  String toString() {
    return 'PaginationModel(currentPage: $currentPage, totalPages: $totalPages, totalItems: $totalItems, itemsPerPage: $itemsPerPage, items: ${items.length} items)';
  }
}
