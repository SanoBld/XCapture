import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:share_plus/share_plus.dart' show Share;
import '../models/capture.dart';
import '../services/download_service.dart';
import '../core/localization/l10n_provider.dart';
import '../widgets/network_thumb.dart';

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

  // Material You 3 style pill/circle button, bigger tap target than plain IconButton
  Widget _roundAction(IconData icon, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Container(
        decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
        child: IconButton(
          icon: Icon(icon, color: Colors.white, size: 22),
          iconSize: 22,
          onPressed: onPressed,
        ),
      ),
    );
  }

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
              elevation: 0,
              // FIX: force white text/icons + a dark scrim behind the bar so
              // the title stays readable no matter what's in the video/photo
              iconTheme: const IconThemeData(color: Colors.white),
              titleTextStyle:
                  const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
              flexibleSpace: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black87, Colors.transparent],
                  ),
                ),
              ),
              title: Text(widget.capture.gameTitle),
              actions: [
                if (_isClip) _roundAction(Icons.fullscreen_rounded, _enterFullscreen),
                _saving
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                            width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                      )
                    : _roundAction(Icons.download_rounded, _save),
                _roundAction(Icons.share_rounded, () => Share.share(widget.capture.mediaUrl)),
                const SizedBox(width: 4),
              ],
            ),
      // FIX: SafeArea so the control bar doesn't sit flush against the
      // bottom system nav bar (was cramped before)
      body: SafeArea(
        top: false,
        bottom: !_fullscreen,
        child: GestureDetector(
          onDoubleTap: _isClip ? (_fullscreen ? _exitFullscreen : _enterFullscreen) : null,
          child: SizedBox.expand(
            child: _isClip ? _buildVideo() : _buildImage(),
          ),
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
    final scheme = Theme.of(context).colorScheme;
    final themeData = MaterialVideoControlsThemeData(
      seekBarPositionColor: scheme.primary,
      seekBarThumbColor: scheme.primary,
      seekBarColor: Colors.white24,
      seekBarBufferColor: Colors.white38,
      buttonBarButtonColor: Colors.white,
      // FIX: bigger rounder play button + more breathing room (Material You 3 look)
      bottomButtonBarMargin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      seekBarMargin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      seekBarHeight: 4,
      seekBarThumbSize: 14,
      // FIX: swipe gestures were accidentally changing brightness/volume, disabled
      brightnessGesture: false,
      volumeGesture: false,
      speedUpOnLongPress: true,
      shiftSubtitlesOnControlsVisibilityChange: false,
    );
    final desktopThemeData = MaterialDesktopVideoControlsThemeData(
      seekBarPositionColor: scheme.primary,
      seekBarThumbColor: scheme.primary,
      seekBarColor: Colors.white24,
      seekBarBufferColor: Colors.white38,
      buttonBarButtonColor: Colors.white,
      toggleFullscreenOnDoublePress: true,
    );
    return MaterialVideoControlsTheme(
      normal: themeData,
      fullscreen: themeData,
      child: MaterialDesktopVideoControlsTheme(
        normal: desktopThemeData,
        fullscreen: desktopThemeData,
        child: Video(controller: _videoController!, controls: AdaptiveVideoControls),
      ),
    );
  }

  Widget _buildImage() {
    return InteractiveViewer(
      minScale: 1,
      maxScale: 5,
      child: SizedBox.expand(
        child: NetworkThumb(
          url: widget.capture.mediaUrl,
          fit: BoxFit.contain,
          placeholderBuilder: (c) => const Center(child: CircularProgressIndicator()),
          errorBuilder: (c) =>
              const Center(child: Icon(Icons.broken_image_outlined, color: Colors.white54, size: 48)),
        ),
      ),
    );
  }
}
