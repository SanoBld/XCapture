import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const _browserUA =
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36';

// Small in-memory cache so scrolling back doesn't re-download the same thumbnail
final Map<String, Uint8List> _thumbCache = {};

// FIX: grid views can build 20-30 NetworkThumb widgets at once, all firing
// http.get() in the same frame. The OpenXBL free API rate-limits these
// requests, so most of them fail/timeout and show as gray boxes -- even
// though a single request (like opening the viewer) works fine.
// This simple semaphore limits how many downloads run at the same time,
// queueing the rest instead of firing them all in parallel.
class _DownloadQueue {
  static const int _maxConcurrent = 4;
  static int _active = 0;
  static final List<Completer<void>> _waiting = [];

  static Future<void> acquire() async {
    if (_active < _maxConcurrent) {
      _active++;
      return;
    }
    final completer = Completer<void>();
    _waiting.add(completer);
    await completer.future;
    _active++;
  }

  static void release() {
    _active--;
    if (_waiting.isNotEmpty) {
      _waiting.removeAt(0).complete();
    }
  }
}

// Fetches image bytes manually (same proven http client as the API calls) instead of
// relying on cached_network_image, which was silently hanging on some networks.
class NetworkThumb extends StatefulWidget {
  final String url;
  final Widget Function(BuildContext) placeholderBuilder;
  final Widget Function(BuildContext) errorBuilder;
  final BoxFit fit;

  const NetworkThumb({
    super.key,
    required this.url,
    required this.placeholderBuilder,
    required this.errorBuilder,
    this.fit = BoxFit.cover,
  });

  @override
  State<NetworkThumb> createState() => _NetworkThumbState();
}

class _NetworkThumbState extends State<NetworkThumb> {
  late Future<Uint8List> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(covariant NetworkThumb oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload if the tile got reused for a different capture (grid recycling)
    if (oldWidget.url != widget.url) {
      _future = _load();
    }
  }

  Future<Uint8List> _load() async {
    final cached = _thumbCache[widget.url];
    if (cached != null) return cached;

    // FIX: wait for a free download slot instead of hitting the API all at once
    await _DownloadQueue.acquire();
    try {
      // FIX: retry once on rate-limit (HTTP 429) after a short delay
      http.Response res = await http
          .get(Uri.parse(widget.url), headers: const {'User-Agent': _browserUA})
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 429) {
        await Future.delayed(const Duration(milliseconds: 800));
        res = await http
            .get(Uri.parse(widget.url), headers: const {'User-Agent': _browserUA})
            .timeout(const Duration(seconds: 15));
      }
      // FIX: some OpenXBL urls return 200 with empty/dead bytes -> treat as error
      if (res.statusCode != 200 || res.bodyBytes.isEmpty) {
        throw Exception('HTTP ${res.statusCode} (${res.bodyBytes.length} bytes)');
      }
      _thumbCache[widget.url] = res.bodyBytes;
      if (_thumbCache.length > 200) _thumbCache.remove(_thumbCache.keys.first);
      return res.bodyBytes;
    } finally {
      _DownloadQueue.release();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return widget.placeholderBuilder(context);
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return widget.errorBuilder(context);
        }
        // FIX: this is the real bug - Image.memory can silently fail to
        // decode bad bytes (invalid/corrupt image) and render nothing at
        // all, which looked like a permanent gray box. errorBuilder catches
        // that and falls back to a visible broken-image icon instead.
        return Image.memory(
          snapshot.data!,
          fit: widget.fit,
          gaplessPlayback: true,
          errorBuilder: (context, error, stackTrace) => widget.errorBuilder(context),
        );
      },
    );
  }
}
