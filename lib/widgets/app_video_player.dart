import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';

class AppVideoPlayer extends StatefulWidget {
  final String? videoUrl;
  final String? videoPath;
  final double? height;
  final BoxFit fit;
  final bool autoPlay;
  final bool isDark;

  const AppVideoPlayer({
    super.key,
    this.videoUrl,
    this.videoPath,
    this.height,
    this.fit = BoxFit.contain,
    this.autoPlay = false,
    this.isDark = false,
  });

  @override
  State<AppVideoPlayer> createState() => _AppVideoPlayerState();
}

class _AppVideoPlayerState extends State<AppVideoPlayer> {
  VideoPlayerController? _controller;
  bool _isInitializing = true;
  bool _hasError = false;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  @override
  void didUpdateWidget(AppVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl ||
        oldWidget.videoPath != widget.videoPath) {
      _disposePlayer();
      _initPlayer();
    }
  }

  Future<void> _initPlayer() async {
    final url = widget.videoUrl;
    final path = widget.videoPath;

    if ((url == null || url.isEmpty) && (path == null || path.isEmpty)) {
      if (!mounted) return;
      setState(() {
        _isInitializing = false;
        _hasError = true;
      });
      return;
    }

    setState(() {
      _isInitializing = true;
      _hasError = false;
    });

    final controllersToTry = <Future<VideoPlayerController> Function()>[];

    if (path != null && path.isNotEmpty) {
      final cleanPath = path.trim();
      if (cleanPath.startsWith('http://') ||
          cleanPath.startsWith('https://') ||
          cleanPath.startsWith('blob:') ||
          cleanPath.startsWith('content://')) {
        controllersToTry.add(
          () async => VideoPlayerController.networkUrl(Uri.parse(cleanPath)),
        );
      } else if (cleanPath.startsWith('file://')) {
        final fileUri = Uri.tryParse(cleanPath);
        if (fileUri != null) {
          try {
            controllersToTry.add(
              () async => VideoPlayerController.file(File.fromUri(fileUri)),
            );
          } catch (_) {}
        }
        controllersToTry.add(
          () async => VideoPlayerController.networkUrl(Uri.parse(cleanPath)),
        );
      } else {
        controllersToTry.add(
          () async => VideoPlayerController.file(File(cleanPath)),
        );
        controllersToTry.add(
          () async => VideoPlayerController.networkUrl(Uri.file(cleanPath)),
        );
        final parsedUri = Uri.tryParse(cleanPath);
        if (parsedUri != null && parsedUri.hasScheme) {
          controllersToTry.add(
            () async => VideoPlayerController.networkUrl(parsedUri),
          );
        }
      }
    }

    if (url != null && url.isNotEmpty) {
      final cleanUrl = url.trim();
      final parsedUri = Uri.tryParse(cleanUrl);
      if (parsedUri != null) {
        controllersToTry.add(
          () async => VideoPlayerController.networkUrl(parsedUri),
        );
      }
      if (cleanUrl.startsWith('file://')) {
        try {
          controllersToTry.add(
            () async =>
                VideoPlayerController.file(File.fromUri(Uri.parse(cleanUrl))),
          );
        } catch (_) {}
      } else if (!cleanUrl.startsWith('http')) {
        controllersToTry.add(
          () async => VideoPlayerController.file(File(cleanUrl)),
        );
      }
    }

    VideoPlayerController? successfulController;

    for (final createController in controllersToTry) {
      try {
        final controller = await createController();
        await controller.initialize();
        successfulController = controller;
        break;
      } catch (_) {}
    }

    if (!mounted) {
      successfulController?.dispose();
      return;
    }

    if (successfulController != null) {
      _controller = successfulController;
      successfulController.addListener(_onControllerUpdate);
      setState(() {
        _isInitializing = false;
      });
      if (widget.autoPlay) {
        successfulController.play();
      }
    } else {
      setState(() {
        _isInitializing = false;
        _hasError = true;
      });
    }
  }

  void _onControllerUpdate() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _disposePlayer() async {
    final controller = _controller;
    _controller = null;
    if (controller != null) {
      controller.removeListener(_onControllerUpdate);
      await controller.dispose();
    }
  }

  @override
  void dispose() {
    _disposePlayer();
    super.dispose();
  }

  bool get _isEnded {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return false;
    final position = controller.value.position;
    final duration = controller.value.duration;
    return position >= duration && duration > Duration.zero;
  }

  void _togglePlayPause() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    if (_isEnded) {
      controller.seekTo(Duration.zero);
      controller.play();
    } else if (controller.value.isPlaying) {
      controller.pause();
    } else {
      controller.play();
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final containerHeight = widget.height ?? 220;

    if (_isInitializing) {
      return Container(
        height: containerHeight,
        width: double.infinity,
        color: widget.isDark ? Colors.black : const Color(0xFF1E293B),
        child: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF2196F3),
          ),
        ),
      );
    }

    if (_hasError || _controller == null || !_controller!.value.isInitialized) {
      return Container(
        height: containerHeight,
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: widget.isDark ? const Color(0xFF111827) : const Color(0xFFEAF2FF),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFF2196F3),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.videocam_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Video Attached & Ready',
              style: GoogleFonts.poppins(
                color: widget.isDark ? Colors.white : Colors.black87,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Video media will be included with your report submission.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: widget.isDark ? Colors.white60 : Colors.black54,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _initPlayer,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(
                'Reload Player',
                style: GoogleFonts.poppins(fontSize: 12),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF2196F3),
                side: const BorderSide(color: Color(0xFF2196F3)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final controller = _controller!;
    final value = controller.value;
    final isPlaying = value.isPlaying;
    final isEnded = _isEnded;

    return GestureDetector(
      onTap: () {
        setState(() {
          _showControls = !_showControls;
        });
      },
      child: Container(
        height: widget.height,
        width: double.infinity,
        color: Colors.black,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: value.aspectRatio > 0 ? value.aspectRatio : (16 / 9),
                child: VideoPlayer(controller),
              ),
            ),

            // Controls Overlay
            AnimatedOpacity(
              opacity: (_showControls || !isPlaying || isEnded) ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 250),
              child: Container(
                color: Colors.black38,
                child: Stack(
                  children: [
                    // Center Big Play/Pause/Replay Button
                    Center(
                      child: GestureDetector(
                        onTap: _togglePlayPause,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2196F3).withValues(alpha: 0.95),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            isEnded
                                ? Icons.replay_rounded
                                : (isPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded),
                            color: Colors.white,
                            size: 38,
                          ),
                        ),
                      ),
                    ),

                    // Bottom Control Bar (Full-width Progress Bar + Duration on Left)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.85),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: VideoProgressIndicator(
                                controller,
                                allowScrubbing: true,
                                padding: EdgeInsets.zero,
                                colors: const VideoProgressColors(
                                  playedColor: Color(0xFF2196F3),
                                  bufferedColor: Colors.white38,
                                  backgroundColor: Colors.white24,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                              child: Text(
                                '${_formatDuration(value.position)} / ${_formatDuration(value.duration)}',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
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
