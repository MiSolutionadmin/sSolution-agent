import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:get/get.dart';

class VideoFullscreenPage extends StatefulWidget {
  final VideoPlayerController controller;
  final String videoUrl;
  final String? type;
  final bool initialVolumeMuted;
  final Function(bool) onVolumeChanged;

  const VideoFullscreenPage({
    Key? key,
    required this.controller,
    required this.videoUrl,
    this.type,
    required this.initialVolumeMuted,
    required this.onVolumeChanged,
  }) : super(key: key);

  @override
  State<VideoFullscreenPage> createState() => _VideoFullscreenPageState();
}

class _VideoFullscreenPageState extends State<VideoFullscreenPage> {
  bool _showControls = true;
  bool _isVolumeMuted = false;

  @override
  void initState() {
    super.initState();
    
    // 전체화면 모드 설정 (애니메이션 없이)
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    
    // 볼륨 상태 초기화 (전달받은 상태 사용)
    _isVolumeMuted = widget.initialVolumeMuted;
    
    // 비디오 상태 리스너 추가
    widget.controller.addListener(_videoListener);
  }

  void _videoListener() {
    if (mounted) {
      setState(() {}); // seekBar 업데이트를 위한 setState
    }
  }

  @override
  void dispose() {
    // 리스너 제거
    widget.controller.removeListener(_videoListener);
    
    // 화면 방향과 시스템 UI 복원
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  String _formatDuration(Duration d, Duration total) {
    if (d >= total) d = total;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  // 볼륨 토글
  void _toggleVolume() {
    setState(() {
      _isVolumeMuted = !_isVolumeMuted;
      widget.controller.setVolume(_isVolumeMuted ? 0.0 : 1.0);
      // 부모 페이지에 상태 변경 알림
      widget.onVolumeChanged(_isVolumeMuted);
    });
  }

  // 컨트롤 표시/숨김 토글
  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    
    // 3초 후 자동으로 컨트롤 숨김
    if (_showControls) {
      Future.delayed(Duration(seconds: 3), () {
        if (mounted && _showControls) {
          setState(() {
            _showControls = false;
          });
        }
      });
    }
  }

  // 전체화면 종료
  void _exitFullscreen() {
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    final isControllerReady = widget.controller.value.isInitialized;
    final rawDuration = isControllerReady ? widget.controller.value.duration : Duration.zero;
    final rawPosition = isControllerReady ? widget.controller.value.position : Duration.zero;

    // 0초 duration 방지
    final duration = rawDuration.inMilliseconds > 0 ? rawDuration : Duration(seconds: 1);
    final position = rawPosition;

    // 안전한 슬라이더 범위 계산
    final durationSeconds = duration.inSeconds;
    final positionSeconds = position.inSeconds.clamp(0, durationSeconds).toDouble();

    return Scaffold(
      backgroundColor: Colors.black,
      body: isControllerReady
          ? Stack(
              children: [
                // 전체화면 비디오 (탭 가능)
                Center(
                  child: GestureDetector(
                    onTap: _toggleControls,
                    child: AspectRatio(
                      aspectRatio: widget.controller.value.aspectRatio,
                      child: VideoPlayer(widget.controller),
                    ),
                  ),
                ),
                
                // 하단 컨트롤 바 (조건부 표시)
                if (_showControls)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: _buildControlBar(durationSeconds.toDouble(), positionSeconds, duration, position),
                  ),
              ],
            )
          : Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
    );
  }

  // 컨트롤 바 위젯
  Widget _buildControlBar(double durationSeconds, double positionSeconds, Duration duration, Duration position) {
    return Container(
      color: Colors.black54,
      child: Row(
        children: [
          // 시작/중지 버튼
          IconButton(
            icon: Icon(
              widget.controller.value.isPlaying
                  ? Icons.stop
                  : Icons.play_arrow
            ),
            color: Colors.white,
            onPressed: () {
              setState(() {
                widget.controller.value.isPlaying
                    ? widget.controller.pause()
                    : widget.controller.play();
              });
            },
          ),

          // 소리 버튼
          IconButton(
            icon: Icon(_isVolumeMuted ? Icons.volume_off : Icons.volume_up),
            color: Colors.white,
            onPressed: _toggleVolume,
          ),

          Flexible(
            flex: 1,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 슬라이더
                Container(
                  height: 30,
                  child: Slider(
                    min: 0,
                    max: durationSeconds > 0 ? durationSeconds.toDouble() : 1.0,
                    value: positionSeconds.clamp(0.0, durationSeconds > 0 ? durationSeconds.toDouble() : 1.0),
                    activeColor: Colors.red,
                    inactiveColor: Colors.white30,
                    thumbColor: Colors.white,
                    onChanged: (value) {
                      if (widget.controller.value.isInitialized) {
                        widget.controller.seekTo(Duration(seconds: value.toInt()));
                      }
                    },
                  ),
                ),
                // 시간 표시
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(position, duration),
                        style: TextStyle(color: Colors.white, fontSize: 11),
                      ),
                      Text(
                        _formatDuration(duration, duration),
                        style: TextStyle(color: Colors.white, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 전체화면 종료 버튼
          IconButton(
            icon: Icon(Icons.fullscreen_exit),
            color: Colors.white,
            onPressed: _exitFullscreen,
          )
        ],
      ),
    );
  }
}