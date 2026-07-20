import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:share_plus/share_plus.dart' show Share;
import '../models/capture.dart';
import '../services/download_service.dart';
import '../core/localization/l10n_provider.dart';
import '../widgets/full_video_player.dart';

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

  @override
  void initState() {
    super.initState();
    if (widget.capture.type == CaptureType.clip) {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.capture.mediaUrl))
        ..initialize().then((_) {
          setState(() {});
          _videoController!.play();
        });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(widget.capture.gameTitle),
        actions: [
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
      body: Center(
        child: isClip
            ? (_videoController != null && _videoController!.value.isInitialized
                ? FullVideoPlayer(controller: _videoController!)
                : const CircularProgressIndicator())
            : InteractiveViewer(
                child: CachedNetworkImage(imageUrl: widget.capture.mediaUrl),
              ),
      ),
    );
  }
}
