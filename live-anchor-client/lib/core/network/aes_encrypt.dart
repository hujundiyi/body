import 'dart:convert';
import 'package:encrypt/encrypt.dart';
import 'package:crypto/crypto.dart';

/// AES 加密解密工具类
/// 对应 Swift 版本的 BHIAESEncrypt
class AESEncrypt {
  // MARK: - 常量

  /// 默认 IV 向量
  static const String defaultIV = 'Dj81dVagerpeQdv8';

  /// 默认密钥
  static const String defaultKey = 'TaV1qx4CCBUjXjJztJMx8rHRfGWoMuax';

  // MARK: - AES 加密

  /// AES 加密字符串
  /// - Parameters:
  ///   - plainText: 明文字符串
  ///   - key: 密钥，默认使用 defaultKey
  ///   - iv: 初始化向量，默认使用 defaultIV
  /// - Returns: Base64 编码的加密字符串
  static String? encrypt(String plainText, {String key = defaultKey, String iv = defaultIV}) {
    try {
      final keyBytes = Key.fromUtf8(key);
      final ivBytes = IV.fromUtf8(iv);

      final encrypter = Encrypter(AES(keyBytes, mode: AESMode.cbc, padding: 'PKCS7'));
      final encrypted = encrypter.encrypt(plainText, iv: ivBytes);

      return encrypted.base64;
    } catch (e) {
      print('AES 加密失败: $e');
      return null;
    }
  }

  // MARK: - AES 解密

  /// AES 解密字符串
  /// - Parameters:
  ///   - cipherText: Base64 编码的密文字符串
  ///   - key: 密钥，默认使用 defaultKey
  ///   - iv: 初始化向量，默认使用 defaultIV
  /// - Returns: 解密后的明文字符串
  static String? decrypt(String cipherText, {String key = defaultKey, String iv = defaultIV}) {
    try {
      final keyBytes = Key.fromUtf8(key);
      final ivBytes = IV.fromUtf8(iv);

      final encrypter = Encrypter(AES(keyBytes, mode: AESMode.cbc, padding: 'PKCS7'));
      final decrypted = encrypter.decrypt64(cipherText, iv: ivBytes);

      return decrypted;
    } catch (e) {
      print('AES 解密失败: $e');
      return null;
    }
  }

  // MARK: - MD5

  /// 计算 MD5 哈希值
  /// - Parameter input: 输入字符串
  /// - Returns: MD5 哈希值（小写）
  static String md5Hash(String input) {
    final bytes = utf8.encode(input);
    final digest = md5.convert(bytes);
    return digest.toString();
  }

  /// 计算 MD5 哈希值（大写）
  /// - Parameter input: 输入字符串
  /// - Returns: MD5 哈希值（大写）
  static String md5HashUppercase(String input) {
    return md5Hash(input).toUpperCase();
  }
}
