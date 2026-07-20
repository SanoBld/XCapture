import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../models/capture.dart';
import '../providers/settings_provider.dart';

// Single grid item: thumbnail, duration badge, optional title/date, selection checkbox
class CaptureGridTile extends StatelessWidget {
  final Capture capture;
  final TileInfo tileInfo;
  final bool selectionMode;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const CaptureGridTile({
    super.key,
    required this.capture,
    required this.tileInfo,
    required this.selectionMode,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
  });

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedScale(
        scale: selected ? 0.94 : 1,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: capture.thumbnailUrl,
              fit: BoxFit.cover,
              httpHeaders: const {
                'User-Agent':
                    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36',
              },
              placeholder: (c, u) => Container(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              errorWidget: (c, u, e) => Container(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: const Icon(Icons.broken_image_outlined),
              ),
            ),
            if (tileInfo != TileInfo.none)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(8, 16, 8, 6),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black87],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(capture.gameTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 12)),
                      if (tileInfo == TileInfo.titleAndDate)
                        Text(DateFormat.yMMMd().format(capture.dateCaptured),
                            style: const TextStyle(color: Colors.white70, fontSize: 10)),
                    ],
                  ),
                ),
              ),
            if (capture.type == CaptureType.clip)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 14),
                      Text(
                        _formatDuration(capture.duration ?? Duration.zero),
                        style: const TextStyle(color: Colors.white, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
            AnimatedOpacity(
              opacity: selectionMode ? 1 : 0,
              duration: const Duration(milliseconds: 150),
              child: Positioned(
                left: 6,
                top: 6,
                child: AnimatedScale(
                  scale: selected ? 1.15 : 1,
                  duration: const Duration(milliseconds: 150),
                  child: Icon(
                    selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                    color: selected ? Theme.of(context).colorScheme.primary : Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),
            AnimatedOpacity(
              opacity: selected ? 1 : 0,
              duration: const Duration(milliseconds: 150),
              child: Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).colorScheme.primary, width: 3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}
