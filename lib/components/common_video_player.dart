import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
  final bool? isPlaying; // 외부에서 재생 상태를 받을 수 있도록 추가

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
    this.isPlaying,
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
        Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.black,
          child: FittedBox(
            fit: BoxFit.fill,
            child: SizedBox(
              width: controller!.value.size.width,
              height: controller!.value.size.height,
              child: VideoPlayer(controller!),
            ),
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
          // 하단 컨트롤 (고정 높이 55)
          Container(
            height: 65,
            color: Color(0xFF000000),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 슬라이더 (padding 제거)
                SizedBox(
                  height: 30,
                  child: SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 4.0,
                      thumbShape: RoundSliderThumbShape(enabledThumbRadius: 7),
                      overlayShape: RoundSliderOverlayShape(overlayRadius: 0),
                      trackShape: RectangularSliderTrackShape(),
                      activeTrackColor: const Color(0xFF1955EE),
                      inactiveTrackColor: Colors.white30,
                      thumbColor: Colors.white,
                    ),
                    child: Slider(
                      min: 0,
                      max: durationSeconds > 0 ? durationSeconds : 1.0,
                      value: positionSeconds.clamp(
                          0.0, durationSeconds > 0 ? durationSeconds : 1.0),
                      onChanged: onSeek,
                    ),
                  ),
                ),
                // 컨트롤 버튼
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left:16,bottom: 8,right: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // 재생/정지 버튼
                        if (onPlayPause != null)
                          GestureDetector(
                            onTap: onPlayPause,
                            child: Container(
                              width: 24,
                              height: 24,
                              alignment: Alignment.center,
                              child: (isPlaying ?? controller!.value.isPlaying)
                                  ? Icon(
                                      Icons.pause,
                                      color: Colors.white,
                                      size: 24,
                                    )
                                  : Icon(
                                      Icons.play_arrow,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                            ),
                          )
                        else
                          SizedBox(width: 16),
                        // 전체화면 버튼
                        if (onFullscreen != null)
                          GestureDetector(
                            onTap: onFullscreen,
                            child: Container(
                              width: 24,
                              height: 24,
                              child: const Icon(
                                Icons.fullscreen,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          )
                        else
                          SizedBox(width: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
