import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/constants.dart';

// Secure storage wrapper for sensitive data (API key)
class StorageService {
  static const _storage = FlutterSecureStorage();

  static Future<void> saveApiKey(String key) =>
      _storage.write(key: AppConstants.secureKeyApiKey, value: key);

  static Future<String?> getApiKey() =>
      _storage.read(key: AppConstants.secureKeyApiKey);

  static Future<void> deleteApiKey() =>
      _storage.delete(key: AppConstants.secureKeyApiKey);
}
