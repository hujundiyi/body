import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 本地存储服务
class StorageService extends GetxService {
  late SharedPreferences _prefs;
  
  /// 初始化服务
  Future<StorageService> init() async {
    _prefs = await SharedPreferences.getInstance();
    return this;
  }
  
  /// 存储字符串
  Future<bool> setString(String key, String value) async {
    return await _prefs.setString(key, value);
  }
  
  /// 获取字符串
  String? getString(String key) {
    return _prefs.getString(key);
  }
  
  /// 存储整数
  Future<bool> setInt(String key, int value) async {
    return await _prefs.setInt(key, value);
  }
  
  /// 获取整数
  int? getInt(String key) {
    return _prefs.getInt(key);
  }
  
  /// 存储布尔值
  Future<bool> setBool(String key, bool value) async {
    return await _prefs.setBool(key, value);
  }
  
  /// 获取布尔值
  bool? getBool(String key) {
    return _prefs.getBool(key);
  }
  
  /// 存储双精度浮点数
  Future<bool> setDouble(String key, double value) async {
    return await _prefs.setDouble(key, value);
  }
  
  /// 获取双精度浮点数
  double? getDouble(String key) {
    return _prefs.getDouble(key);
  }
  
  /// 存储字符串列表
  Future<bool> setStringList(String key, List<String> value) async {
    return await _prefs.setStringList(key, value);
  }
  
  /// 获取字符串列表
  List<String>? getStringList(String key) {
    return _prefs.getStringList(key);
  }
  
  /// 删除指定键的值
  Future<bool> remove(String key) async {
    return await _prefs.remove(key);
  }
  
  /// 清空所有数据
  Future<bool> clear() async {
    return await _prefs.clear();
  }
  
  /// 检查键是否存在
  bool containsKey(String key) {
    return _prefs.containsKey(key);
  }
  
  /// 获取所有键
  Set<String> getKeys() {
    return _prefs.getKeys();
  }
}
