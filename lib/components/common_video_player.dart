import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// 공통 비디오 플레이어 위젯
class CommonVideoPlayer extends StatelessWidget {
  final VideoPlayerController? controller;
  final bool showControls;
  final VoidCallback? onPlayPause;
  final VoidCallback? onFullscreen;
  final Duration currentPosition;
  final Duration duration;
  final String currentPositionText;
  final String durationText;
  final Function(double)? onSeek;

  const CommonVideoPlayer({
    super.key,
    required this.controller,
    this.showControls = true,
    this.onPlayPause,
    this.onFullscreen,
    this.currentPosition = Duration.zero,
    this.duration = Duration.zero,
    this.currentPositionText = "00:00",
    this.durationText = "00:00",
    this.onSeek,
  });

  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller!.value.isInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Stack(
      children: [
        // 비디오 플레이어
        Center(
          child: AspectRatio(
            aspectRatio: controller!.value.aspectRatio,
            child: VideoPlayer(controller!),
          ),
        ),
        // 컨트롤 오버레이
        if (showControls) _buildControlsOverlay(),
      ],
    );
  }

  /// 컨트롤 오버레이
  Widget _buildControlsOverlay() {
    final durationSeconds = duration.inSeconds.toDouble();
    final positionSeconds = currentPosition.inSeconds.toDouble();

    return Positioned.fill(
      child: Column(
        children: [
          // 중간 공간 (영상 영역)
          Expanded(child: Container()),
          // 하단 재생바
          Container(
            color: Colors.black54,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 슬라이더
                Container(
                  height: 30,
                  child: Slider(
                    min: 0,
                    max: durationSeconds > 0 ? durationSeconds : 1.0,
                    value: positionSeconds.clamp(
                        0.0, durationSeconds > 0 ? durationSeconds : 1.0),
                    activeColor: const Color(0xFF1955EE),
                    inactiveColor: Colors.white30,
                    thumbColor: Colors.white,
                    onChanged: onSeek,
                  ),
                ),
                // 시간 표시 (주석 처리)
                // Row(
                //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                //   children: [
                //     Text(
                //       currentPositionText,
                //       style: const TextStyle(color: Colors.white, fontSize: 11),
                //     ),
                //     Text(
                //       durationText,
                //       style: const TextStyle(color: Colors.white, fontSize: 11),
                //     ),
                //   ],
                // ),
              ],
            ),
          ),
          // 하단 컨트롤 버튼
          Container(
            color: Colors.black54,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 재생/정지 버튼
                if (onPlayPause != null)
                  IconButton(
                    icon: Icon(
                      controller!.value.isPlaying
                          ? Icons.stop
                          : Icons.play_arrow,
                      color: Colors.white,
                    ),
                    onPressed: onPlayPause,
                  ),
                // 전체화면 버튼
                if (onFullscreen != null)
                  IconButton(
                    icon: const Icon(Icons.fullscreen, color: Colors.white),
                    onPressed: onFullscreen,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
