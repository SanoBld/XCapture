import 'package:flutter/foundation.dart';
import '../models/capture.dart';
import '../services/openxbl_service.dart';

// Fetches and caches screenshots + clips lists for the session
class CapturesProvider extends ChangeNotifier {
  List<Capture> screenshots = [];
  List<Capture> clips = [];
  bool loadingScreenshots = false;
  bool loadingClips = false;
  String? error;

  Future<void> loadScreenshots(OpenXblService service, {bool refresh = false}) async {
    if (loadingScreenshots) return;
    if (screenshots.isNotEmpty && !refresh) return;
    loadingScreenshots = true;
    error = null;
    notifyListeners();
    try {
      screenshots = await service.fetchScreenshots();
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
    }
    loadingScreenshots = false;
    notifyListeners();
  }

  Future<void> loadClips(OpenXblService service, {bool refresh = false}) async {
    if (loadingClips) return;
    if (clips.isNotEmpty && !refresh) return;
    loadingClips = true;
    error = null;
    notifyListeners();
    try {
      clips = await service.fetchClips();
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
    }
    loadingClips = false;
    notifyListeners();
  }
}
