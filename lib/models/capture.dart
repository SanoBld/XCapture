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

  // Picks the best thumbnail (prefers 'Large')
  static String _bestThumbnail(List thumbnails) {
    if (thumbnails.isEmpty) return '';
    final large = thumbnails.firstWhere(
      (t) => t['thumbnailType'] == 'Large',
      orElse: () => thumbnails.first,
    );
    return large['uri'] ?? '';
  }

  // Picks the downloadable media URI (uriType == 'Download')
  static String _bestMediaUri(List uris) {
    if (uris.isEmpty) return '';
    final download = uris.firstWhere(
      (u) => u['uriType'] == 'Download',
      orElse: () => uris.first,
    );
    return download['uri'] ?? '';
  }

  factory Capture.fromScreenshotJson(Map<String, dynamic> json) {
    final thumbnails = (json['thumbnails'] as List?) ?? [];
    final uris = (json['screenshotUris'] as List?) ?? [];
    return Capture(
      id: json['screenshotId']?.toString() ?? json['contentId'].toString(),
      type: CaptureType.screenshot,
      gameTitle: json['titleName'] ?? 'Unknown game',
      thumbnailUrl: _bestThumbnail(thumbnails),
      mediaUrl: _bestMediaUri(uris),
      dateCaptured: DateTime.tryParse(json['dateTaken'] ?? '') ?? DateTime.now(),
    );
  }

  factory Capture.fromClipJson(Map<String, dynamic> json) {
    final thumbnails = (json['thumbnails'] as List?) ?? [];
    final uris = (json['gameClipUris'] as List?) ?? [];
    return Capture(
      id: json['gameClipId']?.toString() ?? json['contentId'].toString(),
      type: CaptureType.clip,
      gameTitle: json['titleName'] ?? 'Unknown game',
      thumbnailUrl: _bestThumbnail(thumbnails),
      mediaUrl: _bestMediaUri(uris),
      dateCaptured: DateTime.tryParse(json['dateRecorded'] ?? '') ?? DateTime.now(),
      duration: Duration(seconds: (json['durationInSeconds'] ?? 0) as int),
    );
  }
}
