import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

// Minimal JSON-based translation provider (avoids full flutter_localizations setup)
class L10nProvider extends ChangeNotifier {
  Map<String, String> _strings = {};
  String languageCode = 'en';

  Future<void> load(String code) async {
    languageCode = code;
    final data = await rootBundle.loadString('assets/l10n/$code.json');
    _strings = Map<String, String>.from(jsonDecode(data));
    notifyListeners();
  }

  String t(String key) => _strings[key] ?? key;
}
