import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../models/capture.dart';

// Wraps OpenXBL free API (xbl.io) for screenshots and game clips
class OpenXblService {
  final String apiKey;
  OpenXblService(this.apiKey);

  // Raw response body of the last DVR call, kept for on-screen debugging
  static String lastRawResponse = '';

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

  List<Capture> _parseList(
    http.Response res,
    Capture Function(Map<String, dynamic>) fromJson,
  ) {
    if (res.statusCode != 200) {
      throw Exception('OpenXBL HTTP ${res.statusCode}: ${res.body}');
    }
    lastRawResponse = res.body.length > 500 ? res.body.substring(0, 500) : res.body;
    final data = jsonDecode(res.body);
    // The API wraps results in "values"; fall back to other known keys just in case.
    final values = (data['values'] ?? data['gameClips'] ?? data['screenshots'] ?? []) as List;
    return values.map((e) => fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Capture>> fetchScreenshots() async {
    final res = await _get('dvr/screenshots');
    return _parseList(res, Capture.fromScreenshotJson);
  }

  Future<List<Capture>> fetchClips() async {
    final res = await _get('dvr/gameclips');
    return _parseList(res, Capture.fromClipJson);
  }

  Future<bool> validateKey() async {
    final res = await _get('account');
    return res.statusCode == 200;
  }
}
