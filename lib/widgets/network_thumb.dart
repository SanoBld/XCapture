import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const _browserUA =
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36';

// Small in-memory cache so scrolling back doesn't re-download the same thumbnail
final Map<String, Uint8List> _thumbCache = {};

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

  Future<Uint8List> _load() async {
    final cached = _thumbCache[widget.url];
    if (cached != null) return cached;
    final res = await http
        .get(Uri.parse(widget.url), headers: const {'User-Agent': _browserUA})
        .timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
    _thumbCache[widget.url] = res.bodyBytes;
    if (_thumbCache.length > 200) _thumbCache.remove(_thumbCache.keys.first);
    return res.bodyBytes;
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
        return Image.memory(snapshot.data!, fit: widget.fit, gaplessPlayback: true);
      },
    );
  }
}
