import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:share_plus/share_plus.dart' show Share;
import '../models/capture.dart';
import '../services/download_service.dart';
import '../core/localization/l10n_provider.dart';

const _browserUA =
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36';

// Fullscreen viewer for a single screenshot or clip
class CaptureViewerPage extends StatefulWidget {
  final Capture capture;
  const CaptureViewerPage({super.key, required this.capture});

  @override
  State<CaptureViewerPage> createState() => _CaptureViewerPageState();
}

class _CaptureViewerPageState extends State<CaptureViewerPage> {
  Player? _player;
  VideoController? _videoController;
  bool _saving = false;
  bool _fullscreen = false;
  String? _videoError;

  bool get _isClip => widget.capture.type == CaptureType.clip;

  @override
  void initState() {
    super.initState();
    if (_isClip) {
      if (widget.capture.mediaUrl.isEmpty) {
        _videoError = 'no_media_url';
        return;
      }
      _player = Player();
      _videoController = VideoController(_player!);
      _player!.stream.error.listen((e) {
        if (mounted) setState(() => _videoError = e);
      });
      _player!.open(
        Media(widget.capture.mediaUrl, httpHeaders: const {'User-Agent': _browserUA}),
      );
    }
  }

  @override
  void dispose() {
    _player?.dispose();
    if (_fullscreen) _exitFullscreen();
    super.dispose();
  }

  void _enterFullscreen() {
    setState(() => _fullscreen = true);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
  }

  void _exitFullscreen() {
    setState(() => _fullscreen = false);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
  }

  Future<void> _save() async {
    final l10n = context.read<L10nProvider>();
    setState(() => _saving = true);
    try {
      await DownloadService.download(widget.capture);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.t('saved'))));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.t('save_failed'))));
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _fullscreen
          ? null
          : AppBar(
              backgroundColor: Colors.transparent,
              title: Text(widget.capture.gameTitle),
              actions: [
                if (_isClip)
                  IconButton(
                    icon: const Icon(Icons.fullscreen_rounded),
                    onPressed: _enterFullscreen,
                  ),
                IconButton(
                  icon: _saving
                      ? const SizedBox(
                          width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.download_rounded),
                  onPressed: _saving ? null : _save,
                ),
                IconButton(
                  icon: const Icon(Icons.share_rounded),
                  onPressed: () => Share.share(widget.capture.mediaUrl),
                ),
              ],
            ),
      body: GestureDetector(
        onDoubleTap: _isClip ? (_fullscreen ? _exitFullscreen : _enterFullscreen) : null,
        child: SizedBox.expand(
          child: _isClip ? _buildVideo() : _buildImage(),
        ),
      ),
    );
  }

  Widget _buildVideo() {
    if (_videoError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.videocam_off_outlined, color: Colors.white54, size: 48),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Text(_videoError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white38, fontSize: 11)),
            ),
          ],
        ),
      );
    }
    if (_videoController == null) return const Center(child: CircularProgressIndicator());
    return Video(controller: _videoController!, controls: AdaptiveVideoControls);
  }

  Widget _buildImage() {
    return InteractiveViewer(
      minScale: 1,
      maxScale: 5,
      child: CachedNetworkImage(
        imageUrl: widget.capture.mediaUrl,
        httpHeaders: const {'User-Agent': _browserUA},
        fit: BoxFit.contain,
        width: double.infinity,
        height: double.infinity,
        placeholder: (c, u) => const Center(child: CircularProgressIndicator()),
        errorWidget: (c, u, e) =>
            const Center(child: Icon(Icons.broken_image_outlined, color: Colors.white54, size: 48)),
      ),
    );
  }
}
