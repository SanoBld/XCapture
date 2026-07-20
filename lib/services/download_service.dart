import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../models/capture.dart';

// Downloads a capture's media file to local storage
class DownloadService {
  static Future<File> download(Capture capture) async {
    final dir = await getApplicationDocumentsDirectory();
    final ext = capture.type == CaptureType.screenshot ? 'png' : 'mp4';
    final file = File('${dir.path}/${capture.id}.$ext');
    final res = await http.get(Uri.parse(capture.mediaUrl));
    await file.writeAsBytes(res.bodyBytes);
    return file;
  }
}
