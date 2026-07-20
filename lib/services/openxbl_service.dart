import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../models/capture.dart';

// Wraps OpenXBL free API (xbl.io) for screenshots and game clips
class OpenXblService {
  final String apiKey;
  OpenXblService(this.apiKey);

  Map<String, String> get _headers => {
        'X-Authorization': apiKey,
        'Accept': 'application/json',
      };

  Future<List<Capture>> fetchScreenshots({String continuationToken = ''}) async {
    final uri = Uri.parse(
        '${AppConstants.openXblBaseUrl}/dvr/screenshots?maxItems=100&continuationToken=$continuationToken');
    final res = await http.get(uri, headers: _headers);
    if (res.statusCode != 200) {
      throw Exception('OpenXBL error ${res.statusCode}');
    }
    final data = jsonDecode(res.body);
    final values = (data['values'] as List?) ?? [];
    return values.map((e) => Capture.fromScreenshotJson(e)).toList();
  }

  Future<List<Capture>> fetchClips({String continuationToken = ''}) async {
    final uri = Uri.parse(
        '${AppConstants.openXblBaseUrl}/dvr/gameclips?maxItems=100&continuationToken=$continuationToken');
    final res = await http.get(uri, headers: _headers);
    if (res.statusCode != 200) {
      throw Exception('OpenXBL error ${res.statusCode}');
    }
    final data = jsonDecode(res.body);
    final values = (data['values'] as List?) ?? [];
    return values.map((e) => Capture.fromClipJson(e)).toList();
  }

  Future<bool> validateKey() async {
    final uri = Uri.parse('${AppConstants.openXblBaseUrl}/account');
    final res = await http.get(uri, headers: _headers);
    return res.statusCode == 200;
  }
}
