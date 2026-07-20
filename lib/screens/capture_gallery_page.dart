import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/capture.dart';
import '../providers/auth_provider.dart';
import '../providers/captures_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/capture_grid_tile.dart';
import 'capture_viewer_page.dart';

// Shared gallery grid used for both Screenshots and Clips tabs
class CaptureGalleryPage extends StatefulWidget {
  final CaptureType type;
  const CaptureGalleryPage({super.key, required this.type});

  @override
  State<CaptureGalleryPage> createState() => _CaptureGalleryPageState();
}

class _CaptureGalleryPageState extends State<CaptureGalleryPage> {
  bool _isScreenshot = false;

  @override
  void initState() {
    super.initState();
    _isScreenshot = widget.type == CaptureType.screenshot;
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load({bool refresh = false}) async {
    final service = context.read<AuthProvider>().service;
    if (service == null) return;
    final provider = context.read<CapturesProvider>();
    if (_isScreenshot) {
      await provider.loadScreenshots(service, refresh: refresh);
    } else {
      await provider.loadClips(service, refresh: refresh);
    }
  }

  @override
  Widget build(BuildContext context) {
    final captures = context.watch<CapturesProvider>();
    final settings = context.watch<SettingsProvider>();
    final list = _isScreenshot ? captures.screenshots : captures.clips;
    final loading = _isScreenshot ? captures.loadingScreenshots : captures.loadingClips;

    return RefreshIndicator(
      onRefresh: () => _load(refresh: true),
      child: loading && list.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : list.isEmpty
              ? ListView(
                  children: [
                    const SizedBox(height: 120),
                    Icon(
                      _isScreenshot ? Icons.image_outlined : Icons.videocam_outlined,
                      size: 48,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: 12),
                    Center(child: Text('No ${_isScreenshot ? "screenshots" : "clips"} found')),
                  ],
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: settings.gridColumns,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 16 / 9,
                  ),
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    final capture = list[i];
                    return CaptureGridTile(
                      capture: capture,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => CaptureViewerPage(capture: capture)),
                      ),
                    );
                  },
                ),
    );
  }
}
