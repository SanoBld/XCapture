import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart' show Share;
import '../models/capture.dart';
import '../providers/auth_provider.dart';
import '../providers/captures_provider.dart';
import '../providers/settings_provider.dart';
import '../core/localization/l10n_provider.dart';
import '../services/openxbl_service.dart';
import '../services/download_service.dart';
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
  String? _selectedGame;
  final Set<String> _selectedIds = {};
  bool _busy = false;

  bool get _selectionMode => _selectedIds.isNotEmpty;

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

  void _toggleSelect(Capture c) => setState(() {
        _selectedIds.contains(c.id) ? _selectedIds.remove(c.id) : _selectedIds.add(c.id);
      });

  Future<void> _bulkDownload(List<Capture> all) async {
    setState(() => _busy = true);
    for (final c in all.where((c) => _selectedIds.contains(c.id))) {
      try {
        await DownloadService.download(c);
      } catch (_) {}
    }
    setState(() {
      _busy = false;
      _selectedIds.clear();
    });
  }

  void _bulkShare(List<Capture> all) {
    final urls = all.where((c) => _selectedIds.contains(c.id)).map((c) => c.mediaUrl).join('\n');
    Share.share(urls);
    setState(() => _selectedIds.clear());
  }

  @override
  Widget build(BuildContext context) {
    final captures = context.watch<CapturesProvider>();
    final settings = context.watch<SettingsProvider>();
    final l10n = context.watch<L10nProvider>();
    final list = _isScreenshot ? captures.screenshots : captures.clips;
    final loading = _isScreenshot ? captures.loadingScreenshots : captures.loadingClips;
    final games = list.map((c) => c.gameTitle).toSet().toList()..sort();
    final filtered =
        _selectedGame == null ? list : list.where((c) => c.gameTitle == _selectedGame).toList();

    if (loading && list.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (captures.error != null && list.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 48, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 12),
            Text(l10n.t('load_error')),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(captures.error!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Theme.of(context).colorScheme.outline)),
            ),
            const SizedBox(height: 12),
            FilledButton(onPressed: () => _load(refresh: true), child: Text(l10n.t('retry'))),
          ],
        ),
      );
    }

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: () => _load(refresh: true),
          child: Column(
            children: [
              if (games.length > 1)
                SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(l10n.t('all_games')),
                          selected: _selectedGame == null,
                          onSelected: (_) => setState(() => _selectedGame = null),
                        ),
                      ),
                      for (final game in games)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(game),
                            selected: _selectedGame == game,
                            onSelected: (_) => setState(() => _selectedGame = game),
                          ),
                        ),
                    ],
                  ),
                ),
              Expanded(
                child: filtered.isEmpty
                    ? ListView(
                        children: [
                          const SizedBox(height: 120),
                          Icon(
                            _isScreenshot ? Icons.image_outlined : Icons.videocam_outlined,
                            size: 48,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          const SizedBox(height: 12),
                          Center(child: Text(l10n.t(_isScreenshot ? 'no_screenshots' : 'no_clips'))),
                          if (OpenXblService.lastRawResponse.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                              child: Text(
                                'Debug: ${OpenXblService.lastRawResponse}',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.outline, fontSize: 10),
                              ),
                            ),
                        ],
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          // Responsive: widen columns automatically on tablets/desktop
                          final width = constraints.maxWidth;
                          final columns = width > 900
                              ? settings.gridColumns + 2
                              : width > 600
                                  ? settings.gridColumns + 1
                                  : settings.gridColumns;
                          return GridView.builder(
                            padding: const EdgeInsets.all(12),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: columns,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                              childAspectRatio: 16 / 9,
                            ),
                            itemCount: filtered.length,
                            itemBuilder: (context, i) {
                              final capture = filtered[i];
                              return CaptureGridTile(
                                capture: capture,
                                tileInfo: settings.tileInfo,
                                selectionMode: _selectionMode,
                                selected: _selectedIds.contains(capture.id),
                                onTap: () {
                                  if (_selectionMode) {
                                    _toggleSelect(capture);
                                  } else {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => CaptureViewerPage(capture: capture)),
                                    );
                                  }
                                },
                                onLongPress: () => _toggleSelect(capture),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
        if (_selectionMode)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Material(
              elevation: 8,
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => setState(() => _selectedIds.clear()),
                      ),
                      Expanded(
                        child: Text(l10n.t('selected_count').replaceAll('{n}', '${_selectedIds.length}')),
                      ),
                      TextButton(
                        onPressed: () => setState(() {
                          _selectedIds
                            ..clear()
                            ..addAll(filtered.map((c) => c.id));
                        }),
                        child: Text(l10n.t('select_all')),
                      ),
                      IconButton(
                        icon: const Icon(Icons.share_rounded),
                        onPressed: () => _bulkShare(filtered),
                      ),
                      _busy
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                  width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                            )
                          : IconButton(
                              icon: const Icon(Icons.download_rounded),
                              onPressed: () => _bulkDownload(filtered),
                            ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
