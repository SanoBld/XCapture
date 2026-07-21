enum CaptureType { screenshot, clip }

// Unified model for both screenshots and game clips
class Capture {
  final String id;
  final CaptureType type;
  final String gameTitle;
  final String thumbnailUrl;
  final String mediaUrl;
  final DateTime dateCaptured;
  final Duration? duration; // clips only

  Capture({
    required this.id,
    required this.type,
    required this.gameTitle,
    required this.thumbnailUrl,
    required this.mediaUrl,
    required this.dateCaptured,
    this.duration,
  });

  // OpenXBL's "thumbnails" entries always report fileSize:0 (dead/never-generated
  // blobs) — the signed "screenshotUris"/"gameClipUris" are the only reliable URLs.
  static String _media(List<dynamic> uris) {
    if (uris.isEmpty) return '';
    final download = uris.firstWhere((u) => u['uriType'] == 2, orElse: () => uris.first);
    return download['uri'] ?? '';
  }

  factory Capture.fromScreenshotJson(Map<String, dynamic> json) {
    final media = _media((json['screenshotUris'] as List?) ?? []);
    return Capture(
      id: json['screenshotId']?.toString() ?? json['contentId']?.toString() ?? '',
      type: CaptureType.screenshot,
      gameTitle: json['titleName'] ?? 'Unknown game',
      thumbnailUrl: media, // reuse the working full image as its own thumbnail
      mediaUrl: media,
      dateCaptured: DateTime.tryParse(json['dateTaken'] ?? '') ?? DateTime.now(),
    );
  }

  factory Capture.fromClipJson(Map<String, dynamic> json) {
    return Capture(
      id: json['gameClipId']?.toString() ?? json['contentId']?.toString() ?? '',
      type: CaptureType.clip,
      gameTitle: json['titleName'] ?? 'Unknown game',
      // No reliable thumbnail source for clips: the grid shows a video icon instead
      thumbnailUrl: '',
      mediaUrl: _media((json['gameClipUris'] as List?) ?? []),
      dateCaptured: DateTime.tryParse(json['dateRecorded'] ?? '') ?? DateTime.now(),
      duration: Duration(seconds: (json['durationInSeconds'] ?? 0) as int),
    );
  }
}
