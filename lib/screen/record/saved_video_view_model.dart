import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

class SavedVideoViewModel extends GetxController {
  // 비디오 정보
  final String recordId;
  final String date;
  final String alertType;
  final String eventType;
  final String result;

  // 비디오 컨트롤러
  VideoPlayerController? _controller;
  VideoPlayerController? get controller => _controller;

  // 로딩 및 상태 관리
  final RxBool isLoading = true.obs;
  final RxBool hasError = false.obs;
  final RxString errorMessage = ''.obs;
  final RxBool isReady = false.obs;

  // 비디오 재생 상태
  final RxBool isPlaying = false.obs;
  final RxBool isVolumeMuted = false.obs;
  final RxBool showControls = true.obs;
  final RxDouble currentPosition = 0.0.obs;
  final RxDouble duration = 0.0.obs;

  // 비디오 URL
  final String videoUrl;

  SavedVideoViewModel({
    required this.recordId,
    required this.date,
    required this.alertType,
    required this.eventType,
    required this.result,
    required this.videoUrl,
  });

  @override
  void onInit() {
    super.onInit();
    _initializeVideo();
  }

  @override
  void onClose() {
    _disposeController();
    super.onClose();
  }

  /// 비디오 초기화
  Future<void> _initializeVideo() async {
    try {
      isLoading.value = true;
      hasError.value = false;
      errorMessage.value = '';

      // 기존 컨트롤러 정리
      await _disposeController();

      // 새 컨트롤러 생성
      _controller = VideoPlayerController.network(
        videoUrl,
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: true,
          allowBackgroundPlayback: false,
        ),
        httpHeaders: {
          'User-Agent': 'Flutter VideoPlayer',
          'Accept': 'video/mp4,video/*,*/*',
          'Cache-Control': 'no-cache',
          'Connection': 'keep-alive',
        },
      );

      // 비디오 초기화
      await _controller!.initialize();

      // 리스너 추가
      _controller!.addListener(_videoListener);

      // 상태 업데이트
      isReady.value = true;
      isLoading.value = false;
      duration.value = _controller!.value.duration.inSeconds.toDouble();

      print('✅ 비디오 초기화 성공: ${_controller!.value.duration}');
    } catch (e) {
      print('❌ 비디오 초기화 실패: $e');
      hasError.value = true;
      errorMessage.value = '영상을 불러올 수 없습니다: ${e.toString()}';
      isLoading.value = false;
    }
  }

  /// 비디오 상태 리스너
  void _videoListener() {
    if (_controller == null || !_controller!.value.isInitialized) return;

    final value = _controller!.value;

    // 에러 체크
    if (value.hasError) {
      hasError.value = true;
      errorMessage.value = '재생 중 오류가 발생했습니다: ${value.errorDescription}';
      return;
    }

    // 재생 상태 업데이트
    isPlaying.value = value.isPlaying;
    currentPosition.value = value.position.inSeconds.toDouble();

    // 비디오 종료 시 처리
    if (value.position >= value.duration && value.isPlaying) {
      _controller!.pause();
      _controller!.seekTo(value.duration);
    }
  }

  /// 재생/일시정지 토글
  void togglePlayPause() {
    if (_controller == null || !isReady.value) return;

    if (_controller!.value.isPlaying) {
      _controller!.pause();
    } else {
      _controller!.play();
    }
  }

  /// 볼륨 토글
  void toggleVolume() {
    if (_controller == null || !isReady.value) return;

    isVolumeMuted.value = !isVolumeMuted.value;
    _controller!.setVolume(isVolumeMuted.value ? 0.0 : 1.0);
  }

  /// 컨트롤 표시/숨김
  void toggleControls() {
    showControls.value = !showControls.value;

    // 3초 후 자동 숨김
    if (showControls.value) {
      Future.delayed(const Duration(seconds: 3), () {
        if (showControls.value) {
          showControls.value = false;
        }
      });
    }
  }

  /// 시간 이동
  void seekTo(double seconds) {
    if (_controller == null || !isReady.value) return;

    final position = Duration(seconds: seconds.toInt());
    _controller!.seekTo(position);
  }

  /// 비디오 새로고침
  Future<void> refreshVideo() async {
    await _initializeVideo();
  }

  /// 컨트롤러 정리
  Future<void> _disposeController() async {
    if (_controller != null) {
      _controller!.removeListener(_videoListener);
      await _controller!.pause();
      await _controller!.dispose();
      _controller = null;
    }
  }

  /// 시간 포맷팅
  String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  /// 현재 위치 시간 문자열
  String get currentPositionText {
    if (_controller == null || !isReady.value) return '00:00';
    return formatDuration(_controller!.value.position);
  }

  /// 전체 시간 문자열
  String get durationText {
    if (_controller == null || !isReady.value) return '00:00';
    return formatDuration(_controller!.value.duration);
  }

  /// 비디오 종횡비
  double get aspectRatio {
    if (_controller == null || !isReady.value) return 16 / 9;
    return _controller!.value.aspectRatio;
  }
}