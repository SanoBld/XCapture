import 'package:flutter/foundation.dart';
import '../services/storage_service.dart';
import '../services/openxbl_service.dart';

// Holds the current API key and exposes the API client
class AuthProvider extends ChangeNotifier {
  String? _apiKey;
  OpenXblService? _service;

  String? get apiKey => _apiKey;
  OpenXblService? get service => _service;
  bool get isLoggedIn => _apiKey != null && _apiKey!.isNotEmpty;

  Future<void> loadFromStorage() async {
    _apiKey = await StorageService.getApiKey();
    if (_apiKey != null) _service = OpenXblService(_apiKey!);
    notifyListeners();
  }

  Future<bool> login(String key) async {
    final svc = OpenXblService(key);
    final valid = await svc.validateKey();
    if (!valid) return false;
    _apiKey = key;
    _service = svc;
    await StorageService.saveApiKey(key);
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    _apiKey = null;
    _service = null;
    await StorageService.deleteApiKey();
    notifyListeners();
  }
}
