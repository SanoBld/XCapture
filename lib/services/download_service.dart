import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';
import '../models/capture.dart';

// Saves a capture's media to the device gallery (mobile) or Downloads folder (desktop)
class DownloadService {
  static Future<void> download(Capture capture) async {
    final res = await http.get(Uri.parse(capture.mediaUrl));
    final ext = capture.type == CaptureType.screenshot ? 'png' : 'mp4';
    final fileName = 'xcapture_${capture.id}.$ext';

    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      // Save directly to the device gallery / Photos app
      if (capture.type == CaptureType.screenshot) {
        await Gal.putImageBytes(res.bodyBytes, name: fileName);
      } else {
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/$fileName');
        await tempFile.writeAsBytes(res.bodyBytes);
        await Gal.putVideo(tempFile.path, album: 'XCapture');
      }
      return;
    }

    // Desktop: save to the Downloads folder
    final dir = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(res.bodyBytes);
  }
}
