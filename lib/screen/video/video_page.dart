import 'package:flutter/material.dart';
import 'package:mms/components/dialog.dart';
import 'package:mms/components/dialogManager.dart';
import 'package:mms/db/camera_table.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';

class VideoPage extends StatefulWidget {
  final String videoUrl;
  final String? type;

  const VideoPage({Key? key,
    required this.videoUrl,
    required this.type
  }) : super(key: key);

  @override
  State<VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> {
  VideoPlayerController? _controller;
  bool _isReady = false;
  Duration _lastPosition = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<bool> _checkVideoUrlWithRetry(String url, {int retries = 10}) async {
    for (int i = 0; i < retries; i++) {
      try {
        final response = await http.head(Uri.parse(url));
        print("영상 검사 [시도 ${i + 1}] - 상태코드: ${response.statusCode}");

        if (response.statusCode == 200) {
          return true;
        }
      } catch (e) {
        print("영상 검사 실패 [시도 ${i + 1}] - 에러: $e");
      }

      await Future.delayed(Duration(seconds: 3));
    }

    print("❌ 5회 시도 후에도 영상 접근 실패");
    return false;
  }

  void _initializeVideo() async {
    print("get url ? : ${widget.videoUrl}");

    final exists = await _checkVideoUrlWithRetry(widget.videoUrl);
    if (!exists) {
      print("❌ 영상이 존재하지 않습니다");
      return;
    }

    final oldController = _controller;
    if (oldController != null) {
      await oldController.pause();
      await oldController.dispose();
      _controller = null;
      await Future.delayed(Duration(milliseconds: 200)); // 안정화
    }

    final controller = VideoPlayerController.network(widget.videoUrl);

    try {
      await controller.initialize();
      print("✅ 영상 초기화 성공, duration: ${controller.value.duration}");

      // 마지막 위치 복원
      if (_lastPosition < controller.value.duration) {
        await controller.seekTo(_lastPosition);
      }

      setState(() {
        _controller = controller;
        _isReady = true;
      });

      _controller!.play();
    } catch (e) {
      print("영상 초기화 실패: $e");
      // 🔹 실패 시 재연결 시도
      Future.delayed(Duration(seconds: 1), _refreshVideo);
      return;
    }

    // 상태 감시
    _controller!.addListener(() {
      final value = _controller!.value;

      if (value.hasError) {
        print("❌ 영상 오류 감지: ${value.errorDescription}");
        _refreshVideo(); // 🔹 재연결
        return;
      }

      if (!value.isInitialized) return;

      final pos = value.position;
      final dur = value.duration;

      // 🎬 영상 종료 시 마지막 프레임 유지
      if (pos >= dur && value.isPlaying) {
        _controller!.pause();
        _controller!.seekTo(
            dur - Duration(milliseconds: 100) > Duration.zero
                ? dur - Duration(milliseconds: 100)
                : Duration.zero
        );
      }

      _lastPosition = pos;
      setState(() {}); // 슬라이더 갱신
    });
  }

  void _refreshVideo() async {
    if (_controller != null) {
      await _controller!.pause();
      await _controller!.dispose();
      _controller = null;
    }

    setState(() {
      _isReady = false;
    });

    _initializeVideo();
  }

  @override
  void dispose() {
    if (_controller != null && _controller!.value.isInitialized) {
      _lastPosition = _controller!.value.position;
    }

    _controller?.dispose();
    _controller = null;

    super.dispose();
  }

  String _formatDuration(Duration d, Duration total) {
    if (d >= total) d = total;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  @override
  Widget build(BuildContext context) {
    final isControllerReady = _controller != null && _isReady;
    final rawDuration = isControllerReady ? _controller!.value.duration : Duration.zero;
    final rawPosition = isControllerReady ? _controller!.value.position : Duration.zero;

// 0초 duration 방지
    final duration = rawDuration.inMilliseconds > 0 ? rawDuration : Duration(seconds: 1);
    final position = rawPosition;

// 안전한 슬라이더 범위 계산
    final durationSeconds = duration.inSeconds;
    final positionSeconds = position.inSeconds.clamp(0, durationSeconds).toDouble();

    return Scaffold(
      appBar: AppBar(
        title: Text("영상 보기"),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed:  _refreshVideo
          )
        ],
      ),
      body: Center(
        child: _isReady && isControllerReady
            ? Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              aspectRatio: _controller!.value.aspectRatio,
              child: VideoPlayer(_controller!),
            ),
            SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Slider(
                min: 0,
                max: durationSeconds.toDouble(),
                value: positionSeconds,
                onChanged: (value) {
                  _controller!.seekTo(Duration(seconds: value.toInt()));
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_formatDuration(position, duration)),
                  Text(_formatDuration(duration, duration)),
                ],
              ),
            ),
            SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () {
                    // 화재감지 버튼 클릭 시 처리
                    showConfirmTapDialog(
                      context,
                      "서버로 전송 하시겠습니까?",
                          () async {
                        DialogManager.showLoading(context);
                        await completeAgentWork(null, 0);
                        DialogManager.hideLoading();
                        Get.back();
                        Get.back();
                        //Get.offAll(() => AlimScreen());
                      },
                    ); // ✅ 화재감지 버튼 함수
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    (widget.type ?? '') == '불꽃 감지' ? '화재감지' : '연기감지',
                  ),
                ),
                SizedBox(width: 16),
                TextButton(
                  onPressed: () {
                    // 오탐 버튼 클릭 시 처리
                    showAlimCheckTapDialog(context, "");
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.grey,        // 배경색
                    foregroundColor: Colors.white,       // 텍스트 색
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text('오탐'),
                ),
              ],
            ),
            Spacer(),
          ],
        )
            : CircularProgressIndicator(),
      ),
      floatingActionButton: _isReady && isControllerReady
          ? FloatingActionButton(
        onPressed: () {
          print("_controller ??? :  ${_controller}");
          setState(() {
            _controller!.value.isPlaying
                ? _controller!.pause()
                : _controller!.play();

          });
        },
        child: Icon(
          _controller!.value.isPlaying ? Icons.pause : Icons.play_arrow,
        ),
      )
          : null,
    );
  }
}
