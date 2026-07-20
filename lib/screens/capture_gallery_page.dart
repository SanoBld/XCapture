import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart' show Share;
import '../models/capture.dart';
import '../providers/auth_provider.dart';
import '../providers/captures_provider.dart';
import '../providers/settings_provider.dart';
import '../core/localization/l10n_provider.dart';
import '../services/openxbl_service.dart';
import '../services/download_service.dart';
import '../widgets/capture_grid_tile.dart';
import '../widgets/styled_dropdown.dart';
import 'capture_viewer_page.dart';

enum DateRange { all, today, week, month }
enum SortOrder { newest, oldest }

// Shared gallery tab used for both Screenshots and Clips, with its own header,
// game/date filters, sort, and multi-select actions.
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
  bool _groupByDate = false;
  DateRange _dateRange = DateRange.all;
  SortOrder _sort = SortOrder.newest;
  final _scrollController = ScrollController();
  final Map<String, GlobalKey> _sectionKeys = {};

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

  List<Capture> _applyFilters(List<Capture> list) {
    var result = _selectedGame == null ? list : list.where((c) => c.gameTitle == _selectedGame).toList();
    final now = DateTime.now();
    if (_dateRange != DateRange.all) {
      result = result.where((c) {
        final d = c.dateCaptured;
        switch (_dateRange) {
          case DateRange.today:
            return d.year == now.year && d.month == now.month && d.day == now.day;
          case DateRange.week:
            return now.difference(d).inDays <= 7;
          case DateRange.month:
            return d.year == now.year && d.month == now.month;
          case DateRange.all:
            return true;
        }
      }).toList();
    }
    result.sort((a, b) => _sort == SortOrder.newest
        ? b.dateCaptured.compareTo(a.dateCaptured)
        : a.dateCaptured.compareTo(b.dateCaptured));
    return result;
  }

  Map<String, List<Capture>> _groupByMonth(List<Capture> list) {
    final map = <String, List<Capture>>{};
    for (final c in list) {
      final key = DateFormat.yMMMM().format(c.dateCaptured);
      map.putIfAbsent(key, () => []).add(c);
    }
    return map;
  }

  void _openFilters(SettingsProvider settings, L10nProvider l10n) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l10n.t('tile_info'), style: Theme.of(context).textTheme.titleSmall),
                  StyledDropdown<TileInfo>(
                    value: settings.tileInfo,
                    items: [
                      DropdownMenuItem(value: TileInfo.none, child: Text(l10n.t('info_none'))),
                      DropdownMenuItem(value: TileInfo.title, child: Text(l10n.t('info_title'))),
                      DropdownMenuItem(
                          value: TileInfo.titleAndDate, child: Text(l10n.t('info_title_date'))),
                    ],
                    onChanged: (v) => v != null ? settings.setTileInfo(v) : null,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l10n.t('grid_columns'), style: Theme.of(context).textTheme.titleSmall),
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 2, label: Text('2')),
                      ButtonSegment(value: 3, label: Text('3')),
                      ButtonSegment(value: 4, label: Text('4')),
                    ],
                    selected: {settings.gridColumns},
                    onSelectionChanged: (s) => settings.setGridColumns(s.first),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: Text(l10n.t('range_all')),
                    selected: _dateRange == DateRange.all,
                    onSelected: (_) => setState(() {
                      _dateRange = DateRange.all;
                      setSheetState(() {});
                    }),
                  ),
                  ChoiceChip(
                    label: Text(l10n.t('range_today')),
                    selected: _dateRange == DateRange.today,
                    onSelected: (_) => setState(() {
                      _dateRange = DateRange.today;
                      setSheetState(() {});
                    }),
                  ),
                  ChoiceChip(
                    label: Text(l10n.t('range_week')),
                    selected: _dateRange == DateRange.week,
                    onSelected: (_) => setState(() {
                      _dateRange = DateRange.week;
                      setSheetState(() {});
                    }),
                  ),
                  ChoiceChip(
                    label: Text(l10n.t('range_month')),
                    selected: _dateRange == DateRange.month,
                    onSelected: (_) => setState(() {
                      _dateRange = DateRange.month;
                      setSheetState(() {});
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.t('group_by_date')),
                value: _groupByDate,
                onChanged: (v) {
                  setState(() => _groupByDate = v);
                  setSheetState(() {});
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final captures = context.watch<CapturesProvider>();
    final settings = context.watch<SettingsProvider>();
    final l10n = context.watch<L10nProvider>();
    final list = _isScreenshot ? captures.screenshots : captures.clips;
    final loading = _isScreenshot ? captures.loadingScreenshots : captures.loadingClips;
    final games = list.map((c) => c.gameTitle).toSet().toList()..sort();
    final filtered = _applyFilters(list);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t(_isScreenshot ? 'screenshots' : 'clips'),
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 22)),
        actions: [
          IconButton(
            tooltip: l10n.t('layout'),
            icon: Icon(settings.layout == GalleryLayout.grid
                ? Icons.view_agenda_rounded
                : Icons.grid_view_rounded),
            onPressed: () => settings.setLayout(
                settings.layout == GalleryLayout.grid ? GalleryLayout.list : GalleryLayout.grid),
          ),
          IconButton(
            tooltip: l10n.t('sort'),
            icon: Icon(_sort == SortOrder.newest
                ? Icons.south_rounded
                : Icons.north_rounded),
            onPressed: () => setState(
                () => _sort = _sort == SortOrder.newest ? SortOrder.oldest : SortOrder.newest),
          ),
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => _openFilters(settings, l10n),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(28),
          child: Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('${filtered.length}',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Theme.of(context).colorScheme.outline)),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          _buildBody(context, captures, settings, l10n, loading, list, games, filtered),
          AnimatedSlide(
            offset: _selectionMode ? Offset.zero : const Offset(0, 1),
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: _selectionBar(filtered, l10n),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    CapturesProvider captures,
    SettingsProvider settings,
    L10nProvider l10n,
    bool loading,
    List<Capture> list,
    List<String> games,
    List<Capture> filtered,
  ) {
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

    return RefreshIndicator(
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
                : _groupByDate
                    ? _buildGroupedGrid(settings, filtered)
                    : _buildFlatGrid(settings, filtered),
          ),
        ],
      ),
    );
  }

  Widget _buildFlatGrid(SettingsProvider settings, List<Capture> filtered) {
    final isList = settings.layout == GalleryLayout.list;
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = isList ? 1 : _responsiveColumns(constraints.maxWidth, settings.gridColumns);
        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: isList ? 2.4 : 16 / 9,
          ),
          itemCount: filtered.length,
          itemBuilder: (context, i) => _tile(filtered[i], settings),
        );
      },
    );
  }

  Widget _buildGroupedGrid(SettingsProvider settings, List<Capture> filtered) {
    final groups = _groupByMonth(filtered);
    for (final key in groups.keys) {
      _sectionKeys.putIfAbsent(key, () => GlobalKey());
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final isList = settings.layout == GalleryLayout.list;
        final columns = isList ? 1 : _responsiveColumns(constraints.maxWidth, settings.gridColumns);
        return Row(
          children: [
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final entry in groups.entries) ...[
                      Padding(
                        key: _sectionKeys[entry.key],
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(entry.key, style: Theme.of(context).textTheme.titleSmall),
                      ),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: isList ? 2.4 : 16 / 9,
                        ),
                        itemCount: entry.value.length,
                        itemBuilder: (context, i) => _tile(entry.value[i], settings),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SizedBox(
              width: 56,
              child: ListView(
                children: [
                  for (final key in groups.keys)
                    InkWell(
                      onTap: () => Scrollable.ensureVisible(
                        _sectionKeys[key]!.currentContext!,
                        duration: const Duration(milliseconds: 300),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(
                          key.split(' ').first.substring(0, 3),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  int _responsiveColumns(double width, int base) {
    if (width > 900) return base + 2;
    if (width > 600) return base + 1;
    return base;
  }

  Widget _tile(Capture capture, SettingsProvider settings) {
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
            MaterialPageRoute(builder: (_) => CaptureViewerPage(capture: capture)),
          );
        }
      },
      onLongPress: () => _toggleSelect(capture),
    );
  }

  Widget _selectionBar(List<Capture> filtered, L10nProvider l10n) {
    if (!_selectionMode) return const SizedBox.shrink();
    return Material(
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
    );
  }
}
