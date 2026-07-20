import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

// YouTube-style video player: seek bar, play/pause, skip, mute, auto-hide controls
class FullVideoPlayer extends StatefulWidget {
  final VideoPlayerController controller;
  const FullVideoPlayer({super.key, required this.controller});

  @override
  State<FullVideoPlayer> createState() => _FullVideoPlayerState();
}

class _FullVideoPlayerState extends State<FullVideoPlayer> {
  bool _showControls = true;
  bool _muted = false;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTick);
    _scheduleHide();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTick);
    _hideTimer?.cancel();
    super.dispose();
  }

  void _onTick() => setState(() {});

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && widget.controller.value.isPlaying) setState(() => _showControls = false);
    });
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) _scheduleHide();
  }

  void _togglePlay() {
    setState(() {
      widget.controller.value.isPlaying ? widget.controller.pause() : widget.controller.play();
    });
    _scheduleHide();
  }

  void _seekBy(Duration offset) {
    final pos = widget.controller.value.position + offset;
    widget.controller.seekTo(pos);
    _scheduleHide();
  }

  void _toggleMute() {
    setState(() {
      _muted = !_muted;
      widget.controller.setVolume(_muted ? 0 : 1);
    });
  }

  String _format(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.controller.value;
    return GestureDetector(
      onTap: _toggleControls,
      child: AspectRatio(
        aspectRatio: value.aspectRatio,
        child: Stack(
          alignment: Alignment.center,
          children: [
            VideoPlayer(widget.controller),
            AnimatedOpacity(
              opacity: _showControls ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                color: Colors.black.withValues(alpha: 0.25),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        icon: Icon(_muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                            color: Colors.white),
                        onPressed: _toggleMute,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          iconSize: 36,
                          icon: const Icon(Icons.replay_10_rounded, color: Colors.white),
                          onPressed: () => _seekBy(const Duration(seconds: -10)),
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          iconSize: 56,
                          icon: Icon(value.isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded,
                              color: Colors.white),
                          onPressed: _togglePlay,
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          iconSize: 36,
                          icon: const Icon(Icons.forward_10_rounded, color: Colors.white),
                          onPressed: () => _seekBy(const Duration(seconds: 10)),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          Text(_format(value.position),
                              style: const TextStyle(color: Colors.white, fontSize: 12)),
                          Expanded(
                            child: SliderTheme(
                              data: SliderThemeData(
                                trackHeight: 2,
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                              ),
                              child: Slider(
                                value: value.position.inMilliseconds
                                    .clamp(0, value.duration.inMilliseconds)
                                    .toDouble(),
                                max: value.duration.inMilliseconds.toDouble().clamp(1, double.infinity),
                                activeColor: Colors.white,
                                inactiveColor: Colors.white38,
                                onChanged: (v) =>
                                    widget.controller.seekTo(Duration(milliseconds: v.toInt())),
                                onChangeStart: (_) => _hideTimer?.cancel(),
                                onChangeEnd: (_) => _scheduleHide(),
                              ),
                            ),
                          ),
                          Text(_format(value.duration),
                              style: const TextStyle(color: Colors.white, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
