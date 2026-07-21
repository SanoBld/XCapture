import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:share_plus/share_plus.dart' show Share;
import '../models/capture.dart';
import '../services/download_service.dart';
import '../core/localization/l10n_provider.dart';
import '../widgets/full_video_player.dart';

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
  VideoPlayerController? _videoController;
  bool _saving = false;
  bool _fullscreen = false;

  bool _videoUnavailable = false;
  String? _videoError;

  @override
  void initState() {
    super.initState();
    if (widget.capture.type == CaptureType.clip) {
      if (widget.capture.mediaUrl.isEmpty) {
        _videoUnavailable = true;
        return;
      }
      try {
        _videoController = VideoPlayerController.networkUrl(
          Uri.parse(widget.capture.mediaUrl),
          httpHeaders: const {'User-Agent': _browserUA},
        )
          ..initialize().timeout(const Duration(seconds: 20)).then((_) {
            setState(() {});
            _videoController!.play();
          }).catchError((e) {
            if (mounted) setState(() {
              _videoUnavailable = true;
              _videoError = e.toString();
            });
          });
      } catch (e) {
        _videoUnavailable = true;
        _videoError = e.toString();
      }
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
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
    final isClip = widget.capture.type == CaptureType.clip;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _fullscreen
          ? null
          : AppBar(
              backgroundColor: Colors.transparent,
              title: Text(widget.capture.gameTitle),
              actions: [
                if (isClip)
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
        onDoubleTap: isClip ? (_fullscreen ? _exitFullscreen : _enterFullscreen) : null,
        child: SizedBox.expand(
          child: isClip
              ? Center(
                  child: _videoUnavailable
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.videocam_off_outlined, color: Colors.white54, size: 48),
                            if (_videoError != null)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                                child: Text(_videoError!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(color: Colors.white38, fontSize: 11)),
                              ),
                          ],
                        )
                      : (_videoController != null && _videoController!.value.isInitialized
                          ? FullVideoPlayer(controller: _videoController!)
                          : const CircularProgressIndicator()),
                )
              : InteractiveViewer(
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
                ),
        ),
      ),
    );
  }
}
