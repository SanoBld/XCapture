import 'dart:convert';
import 'dart:io';
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

  Future<http.Response> _get(String path) async {
    try {
      return await http
          .get(Uri.parse('${AppConstants.openXblBaseUrl}/$path'), headers: _headers)
          .timeout(const Duration(seconds: 15));
    } on SocketException {
      throw Exception('network_error');
    }
  }

  Future<List<Capture>> fetchScreenshots() async {
    final res = await _get('dvr/screenshots');
    if (res.statusCode != 200) throw Exception('OpenXBL error ${res.statusCode}');
    final data = jsonDecode(res.body);
    final values = (data['values'] as List?) ?? [];
    return values.map((e) => Capture.fromScreenshotJson(e)).toList();
  }

  Future<List<Capture>> fetchClips() async {
    final res = await _get('dvr/gameclips');
    if (res.statusCode != 200) throw Exception('OpenXBL error ${res.statusCode}');
    final data = jsonDecode(res.body);
    final values = (data['values'] as List?) ?? [];
    return values.map((e) => Capture.fromClipJson(e)).toList();
  }

  Future<bool> validateKey() async {
    final res = await _get('account');
    return res.statusCode == 200;
  }
}
