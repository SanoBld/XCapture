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

  // Some OpenXBL responses use "thumbnails"/"screenshotUris"/"gameClipUris",
  // others wrap everything in a generic "contentLocators" list instead.
  static String _fromList(List list, String typeKey, List<String> preferredTypes, String urlKey) {
    if (list.isEmpty) return '';
    for (final wanted in preferredTypes) {
      for (final item in list) {
        if (item[typeKey] == wanted) return item[urlKey] ?? '';
      }
    }
    return list.first[urlKey] ?? '';
  }

  static String _thumbnail(Map<String, dynamic> json) {
    final thumbnails = (json['thumbnails'] as List?) ?? [];
    if (thumbnails.isNotEmpty) {
      return _fromList(thumbnails, 'thumbnailType', ['Large', 'Medium', 'Small'], 'uri');
    }
    final locators = (json['contentLocators'] as List?) ?? [];
    return _fromList(locators, 'locatorType', ['Thumbnail'], 'uri');
  }

  static String _media(Map<String, dynamic> json, String urisKey) {
    final uris = (json[urisKey] as List?) ?? [];
    if (uris.isNotEmpty) {
      return _fromList(uris, 'uriType', ['Download'], 'uri');
    }
    final locators = (json['contentLocators'] as List?) ?? [];
    return _fromList(locators, 'locatorType', ['Download'], 'uri');
  }

  factory Capture.fromScreenshotJson(Map<String, dynamic> json) {
    final media = _media(json, 'screenshotUris');
    return Capture(
      id: json['screenshotId']?.toString() ?? json['contentId']?.toString() ?? '',
      type: CaptureType.screenshot,
      gameTitle: json['titleName'] ?? 'Unknown game',
      // The screenshot itself doubles as a reliable thumbnail
      thumbnailUrl: _thumbnail(json).isNotEmpty ? _thumbnail(json) : media,
      mediaUrl: media,
      dateCaptured: DateTime.tryParse(json['dateTaken'] ?? '') ?? DateTime.now(),
    );
  }

  factory Capture.fromClipJson(Map<String, dynamic> json) {
    return Capture(
      id: json['gameClipId']?.toString() ?? json['contentId']?.toString() ?? '',
      type: CaptureType.clip,
      gameTitle: json['titleName'] ?? 'Unknown game',
      thumbnailUrl: _thumbnail(json),
      mediaUrl: _media(json, 'gameClipUris'),
      dateCaptured: DateTime.tryParse(json['dateRecorded'] ?? '') ?? DateTime.now(),
      duration: Duration(seconds: (json['durationInSeconds'] ?? 0) as int),
    );
  }
}
