import 'dart:convert';
import 'package:get/get.dart';
import '../network/anchor_api_service.dart';
import 'storage_service.dart';
import '../../data/models/dict_model.dart';

const String _storageKeyCountry = 'dict_country';

/// 国家字典服务：优先读本地缓存，无缓存再请求字典接口并写入本地
class CountryDictService extends GetxService {
  static CountryDictService get shared => Get.find<CountryDictService>();

  StorageService get _storage => Get.find<StorageService>();
  AnchorAPIService get _api => AnchorAPIService.shared;

  final RxMap<int, String> countryMap = <int, String>{}.obs;
  final RxList<DictItem> countryItems = <DictItem>[].obs;

  /// 先读本地，无则请求接口并保存
  Future<void> loadCountryDict() async {
    final cached = _storage.getString(_storageKeyCountry);
    if (cached != null && cached.isNotEmpty) {
      try {
        final list = (jsonDecode(cached) as List<dynamic>)
            .map((e) => DictItem.fromJson(e as Map<String, dynamic>))
            .toList();
        _assignFromItems(list);
        return;
      } catch (_) {}
    }
    try {
      final list = await _api.getDict(['country']);
      for (final res in list) {
        if (res.dictType == 'country' && res.dictItems.isNotEmpty) {
          final items = res.dictItems;
          _assignFromItems(items);
          await _storage.setString(
            _storageKeyCountry,
            jsonEncode(items.map((e) => e.toJson()).toList()),
          );
          return;
        }
      }
    } catch (_) {
      countryMap.clear();
      countryItems.clear();
    }
  }

  void _assignFromItems(List<DictItem> items) {
    final map = <int, String>{};
    for (final item in items) {
      map[item.value] = item.label;
    }
    countryMap.assignAll(map);
    countryItems.assignAll(items);
  }

  /// 根据 value 取国家名称，无则返回 '--'
  String getCountryLabel(int value) {
    if (value <= 0) return '--';
    return countryMap[value] ?? '--';
  }

  /// 供主播申请等页使用的国家列表（含 value/label/icon）
  List<DictItem> getCountryItemsList() => List.from(countryItems);
}
