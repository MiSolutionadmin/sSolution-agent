import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mms/components/dialogManager.dart';
import 'package:mms/components/common_video_player.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/font/font.dart';
import '../../provider/user_state.dart';
import 'video_fullscreen_page.dart';
import 'dart:async';
import '../navigation/bottom_navigator_view_model.dart';
import '../../services/camera_notification_service.dart';

class VideoPage extends StatefulWidget {
  final String videoUrl;
  final String? type;

  const VideoPage({Key? key, required this.videoUrl, required this.type})
      : super(key: key);

  @override
  State<VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> {
  VideoPlayerController? _controller;
  bool _isReady = false;
  bool _hasError = false;
  String _errorMessage = '';
  Duration _lastPosition = Duration.zero;
  bool _isVolumeMuted = false;
  bool _showControls = true;
  Timer? _timer;
  String _currentVideoUrl = '';
  bool _isVideoExpired = false;
  bool _isSubmissionCompleted = false;
  bool _isRequestingUpdate = false; // 업데이트 요청 중인지 확인
  final UserState us = Get.find<UserState>();

  @override
  void initState() {
    super.initState();
    _currentVideoUrl = widget.videoUrl;
    _isSubmissionCompleted = false; // 새 인스턴스에서 항상 초기화

    if (_currentVideoUrl.isNotEmpty) {
      _initializeVideo();
      _startExpirationTimer();
    } else {
      if (mounted) {
        setState(() {
          _isVideoExpired = true;
        });
      }
    }
  }

  @override
  void didUpdateWidget(VideoPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    // videoUrl이 변경되면 상태 초기화
    if (oldWidget.videoUrl != widget.videoUrl) {
      if (mounted) {
        setState(() {
          _currentVideoUrl = widget.videoUrl;
          _isSubmissionCompleted = false;
          _isVideoExpired = false;
          _hasError = false;
          _errorMessage = '';
          _isRequestingUpdate = false;
        });
      }

      // 새로운 비디오로 초기화
      if (_currentVideoUrl.isNotEmpty) {
        _initializeVideo();
        _startExpirationTimer();
      }
    }
  }

  Future<bool> _checkVideoUrlWithRetry(String url, {int retries = 30}) async {
    for (int i = 0; i < retries; i++) {
      try {
        final response = await http.head(Uri.parse(url));
        print("영상 검사 [시도 ${i + 1}] - 상태코드: ${response.statusCode}");
        print(
            "영상 검사 [시도 ${i + 1}] - Content-Type: ${response.headers['content-type']}");
        print(
            "영상 검사 [시도 ${i + 1}] - Content-Length: ${response.headers['content-length']}");

        if (response.statusCode == 200) {
          // Content-Type 확인
          final contentType = response.headers['content-type']?.toLowerCase();
          if (contentType != null && !contentType.contains('video/')) {
            print("⚠️ 영상 파일이 아닌 것 같습니다: $contentType");

            // GET 요청으로 실제 데이터 확인
            final getResponse = await http.get(Uri.parse(url), headers: {
              'Range': 'bytes=0-1023', // 첫 1KB만 가져와서 확인
            });

            if (getResponse.statusCode == 206 ||
                getResponse.statusCode == 200) {
              print("✅ 부분 요청 성공, 영상 파일로 판단");
              return true;
            }
          } else {
            return true;
          }
        }
      } catch (e) {
        print("영상 검사 실패 [시도 ${i + 1}] - 에러: $e");
      }

      await Future.delayed(Duration(seconds: 1));
    }

    print("❌ ${retries}회 시도 후에도 영상 접근 실패");
    return false;
  }

  void _startExpirationTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      _checkVideoExpiration();
    });
  }

  void _checkVideoExpiration() {
    if (_currentVideoUrl.isEmpty) {
      if (mounted) {
        setState(() {
          _isVideoExpired = true;
        });
      }
      _timer?.cancel();
      return;
    }

    try {
      // URL에서 날짜 추출 (record_2025-07-21-10-29-24.mp4)
      final regex = RegExp(
          r'record_(\d{4})-(\d{2})-(\d{2})-(\d{2})-(\d{2})-(\d{2})\.mp4');
      final match = regex.firstMatch(_currentVideoUrl);

      if (match != null) {
        final year = int.parse(match.group(1)!);
        final month = int.parse(match.group(2)!);
        final day = int.parse(match.group(3)!);
        final hour = int.parse(match.group(4)!);
        final minute = int.parse(match.group(5)!);
        final second = int.parse(match.group(6)!);

        final videoDate = DateTime(year, month, day, hour, minute, second);
        final now = DateTime.now();
        final difference = now.difference(videoDate);

        print('비디오 날짜: $videoDate');
        print('현재 시간: $now');
        print('경과 시간: ${difference.inSeconds}초');

        if (difference.inMinutes >= 1) {
          // GetX의 videoUrl 초기화
          final bottomNavViewModel = Get.find<BottomNavigatorViewModel>();
          bottomNavViewModel.alertVideoUrl.value = '';

          if (mounted) {
            setState(() {
              _currentVideoUrl = '';
              _isVideoExpired = true;
            });
          }

          if (_controller != null) {
            _controller!.pause();
            _controller!.dispose();
            _controller = null;
          }

          _timer?.cancel();
        }
      }
    } catch (e) {
      print('날짜 파싱 오류: $e');
    }
  }

  void _initializeVideo() async {
    print("get url ? : ${_currentVideoUrl}");

    // 에러 상태 초기화
    if (mounted) {
      setState(() {
        _hasError = false;
        _errorMessage = '';
      });
    }

    final exists = await _checkVideoUrlWithRetry(_currentVideoUrl);
    if (!exists) {
      print("❌ 영상이 존재하지 않습니다");
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = '영상을 불러올 수 없습니다. URL을 확인해주세요.';
        });
      }
      return;
    }

    final oldController = _controller;
    if (oldController != null) {
      await oldController.pause();
      await oldController.dispose();
      _controller = null;
      await Future.delayed(Duration(milliseconds: 200)); // 안정화
    }

    try {
      print("📹 비디오 URL 확인: ${_currentVideoUrl}");
      print(
          "📹 HTTP/HTTPS 확인: ${_currentVideoUrl.startsWith('https') ? 'HTTPS' : 'HTTP'}");

      final controller = VideoPlayerController.networkUrl(
        Uri.parse(_currentVideoUrl),
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
        formatHint: VideoFormat.other, // ExoPlayer 포맷 힌트
      );

      await controller.initialize();
      print("✅ 영상 초기화 성공, duration: ${controller.value.duration}");

      // 마지막 위치 복원
      if (_lastPosition < controller.value.duration) {
        await controller.seekTo(_lastPosition);
      }

      if (mounted) {
        setState(() {
          _controller = controller;
          _isReady = true;
          _hasError = false;
          _errorMessage = '';
        });
      }

      // 상태 감시 추가
      _controller!.addListener(_videoListener);

      // 자동 재생
      _controller!.play();
    } catch (e) {
      print("영상 초기화 실패: $e");
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = '영상 재생 중 오류가 발생했습니다: ${e.toString()}';
        });
      }

      // 3초 후 재시도
      Future.delayed(Duration(seconds: 3), () {
        if (mounted) {
          _refreshVideo();
        }
      });
    }
  }

  void _videoListener() {
    if (_controller == null) return;

    final value = _controller!.value;

    if (value.hasError) {
      print("❌ 영상 오류 감지: ${value.errorDescription}");
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = '재생 중 오류가 발생했습니다: ${value.errorDescription}';
        });
      }

      // 5초 후 재연결 시도
      Future.delayed(Duration(seconds: 5), () {
        if (mounted) {
          _refreshVideo();
        }
      });
      return;
    }

    if (!value.isInitialized) return;

    final pos = value.position;
    final dur = value.duration;

    // 영상 상태 디버깅 로그 (5초마다 출력 + 끝 근처에서는 더 자주)
    bool shouldLog = pos.inSeconds % 5 == 0 && pos.inMilliseconds % 1000 < 100;
    bool nearEnd = dur.inSeconds > 0 && (dur.inSeconds - pos.inSeconds <= 2);
    
    if (shouldLog || nearEnd) {
      print("📹 영상 상태 - pos: ${pos.inSeconds}s, dur: ${dur.inSeconds}s, isPlaying: ${value.isPlaying}, isRequestingUpdate: $_isRequestingUpdate");
    }

    // 🎬 영상 종료 또는 끝에 거의 도달 시 새로운 영상 요청하여 계속 재생
    bool isAtEnd = pos >= dur;
    bool isNearEnd = dur.inSeconds > 0 && (dur.inSeconds - pos.inSeconds <= 1);
    
    if ((isAtEnd || isNearEnd) && !_isRequestingUpdate && !_isSubmissionCompleted) {
      print("📹 영상 끝 도달/근접 - 새로운 영상 부분 요청 (pos: $pos, dur: $dur, isPlaying: ${value.isPlaying})");
      if (!isAtEnd) {
        // 아직 끝이 아니라면 일시정지하지 않고 계속 재생
        _requestUpdatedVideo();
      } else {
        // 완전히 끝에 도달했으면 일시정지하고 요청
        _controller!.pause();
        _requestUpdatedVideo();
      }
    }

    _lastPosition = pos;
    if (mounted) {
      setState(() {}); // 슬라이더 갱신
    }
  }

  void _refreshVideo() async {
    if (_controller != null) {
      _controller!.removeListener(_videoListener);
      await _controller!.pause();
      await _controller!.dispose();
      _controller = null;
    }

    if (mounted) {
      setState(() {
        _isReady = false;
        _hasError = false;
        _errorMessage = '';
      });
    }

    _initializeVideo();
  }

  /// 영상 끝에 도달했을 때 업데이트된 영상 요청
  void _requestUpdatedVideo() async {
    if (_currentVideoUrl.isEmpty || _controller == null || _isRequestingUpdate) return;

    _isRequestingUpdate = true; // 요청 시작
    print("📹 업데이트된 영상 요청 중...");
    
    try {
      // 현재 재생 위치 저장
      final currentPosition = _controller!.value.position;
      
      // 새로운 컨트롤러로 같은 URL 재초기화
      final oldController = _controller;
      if (oldController != null) {
        await oldController.pause();
        oldController.removeListener(_videoListener);
        await oldController.dispose();
        _controller = null;
      }

      // 잠시 로딩 상태로 변경
      if (mounted) {
        setState(() {
          _isReady = false;
        });
      }

      // 새 컨트롤러 생성
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(_currentVideoUrl),
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
        formatHint: VideoFormat.other,
      );

      await controller.initialize();
      print("✅ 업데이트된 영상 초기화 성공, 새로운 duration: ${controller.value.duration}");

      // 이전 위치로 복원 (새로운 duration보다 작은 경우에만)
      if (currentPosition < controller.value.duration) {
        await controller.seekTo(currentPosition);
        print("📹 재생 위치 복원: $currentPosition");
      } else {
        // 이전 위치가 새로운 duration보다 크거나 같다면, 새로운 부분부터 재생
        await controller.seekTo(currentPosition);
        print("📹 새로운 부분부터 재생: $currentPosition");
      }

      if (mounted) {
        setState(() {
          _controller = controller;
          _isReady = true;
        });
      }

      // 리스너 추가 및 재생 시작
      _controller!.addListener(_videoListener);
      _controller!.play();
      
      print("📹 업데이트된 영상 재생 시작");

    } catch (e) {
      print("❌ 업데이트된 영상 요청 실패: $e");
      
      // 실패 시 기존 방식대로 마지막 프레임 유지
      if (_controller != null && _controller!.value.isInitialized) {
        final dur = _controller!.value.duration;
        await _controller!.seekTo(dur - Duration(milliseconds: 100) > Duration.zero
            ? dur - Duration(milliseconds: 100)
            : Duration.zero);
      }
      
      // 3초 후 다시 시도
      Future.delayed(Duration(seconds: 3), () {
        if (mounted && !_isSubmissionCompleted) {
          _isRequestingUpdate = false; // 재시도 전에 플래그 해제
          _requestUpdatedVideo();
        }
      });
    } finally {
      _isRequestingUpdate = false; // 요청 완료
    }
  }

  @override
  void dispose() {
    // 화면 방향과 시스템 UI 복원
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    _timer?.cancel();

    if (_controller != null) {
      if (_controller!.value.isInitialized) {
        _lastPosition = _controller!.value.position;
      }
      _controller!.removeListener(_videoListener);
      _controller!.dispose();
      _controller = null;
    }

    super.dispose();
  }

  String _formatDuration(Duration d, Duration total) {
    if (d >= total) d = total;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  Future<void> _openInBrowser() async {
    try {
      final Uri url = Uri.parse(widget.videoUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        Get.snackbar(
          '오류',
          '브라우저에서 열 수 없습니다',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        '오류',
        '브라우저 실행 중 오류가 발생했습니다: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  String _convertToHttps(String url) {
    if (url.startsWith('http://')) {
      return url.replaceFirst('http://', 'https://');
    }
    return url;
  }

  Future<void> _tryHttpsVersion() async {
    final httpsUrl = _convertToHttps(widget.videoUrl);
    if (httpsUrl != widget.videoUrl) {
      print("🔒 HTTPS 버전으로 재시도: $httpsUrl");

      // 임시로 HTTPS URL로 새 VideoPage 열기
      Get.to(() => VideoPage(
            videoUrl: httpsUrl,
            type: widget.type,
          ));
    } else {
      Get.snackbar(
        '알림',
        '이미 HTTPS URL입니다',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
    }
  }

  // 전체화면 페이지로 이동
  void _goToFullscreen() {
    if (_controller != null && _controller!.value.isInitialized) {
      Get.to(
        () => VideoFullscreenPage(
          controller: _controller!,
          videoUrl: widget.videoUrl,
          type: widget.type,
          initialVolumeMuted: _isVolumeMuted,
          onVolumeChanged: (isMuted) {
            if (mounted) {
              setState(() {
                _isVolumeMuted = isMuted;
              });
            }
          },
        ),
        transition: Transition.fade,
        duration: Duration.zero, // 애니메이션 없음
      );
    }
  }

  // 컨트롤 표시/숨김 토글
  void _toggleControls() {
    if (mounted) {
      setState(() {
        _showControls = !_showControls;
      });
    }

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

  @override
  Widget build(BuildContext context) {
    // 제출 완료된 경우 또는 videoUrl이 없거나 만료된 경우
    if (_isSubmissionCompleted || _currentVideoUrl.isEmpty || _isVideoExpired) {
      return Scaffold(
        appBar: AppBar(
          title: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              "실시간 경보 영상",
              style: f20w700Size(),
            ),
          ),
          centerTitle: false,
          backgroundColor: Colors.white,
          titleSpacing: 0,
        ),
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.info_outline,
                size: 60,
                color: Colors.grey,
              ),
              SizedBox(height: 20),
              Text(
                '진행중인 이벤트가 없습니다.',
                style: f18w500Size().copyWith(
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final isControllerReady = _controller != null && _isReady;
    final rawDuration =
        isControllerReady ? _controller!.value.duration : Duration.zero;
    final rawPosition =
        isControllerReady ? _controller!.value.position : Duration.zero;

// 0초 duration 방지
    final duration =
        rawDuration.inMilliseconds > 0 ? rawDuration : Duration(seconds: 1);

    final position = rawPosition;

    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            "실시간 경보 영상",
            style: f20w700Size(),
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        titleSpacing: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child:
                IconButton(icon: Icon(Icons.refresh), onPressed: _refreshVideo),
          )
        ],
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // 비디오 플레이어 영역 (상단)
          Container(
            height: 283,
            width: double.infinity,
            child: _isReady && isControllerReady
                ? GestureDetector(
                    onTap: _toggleControls,
                    child: CommonVideoPlayer(
                      controller: _controller,
                      showControls: _showControls,
                      onPlayPause: () {
                        if (mounted &&
                            _controller != null &&
                            _controller!.value.isInitialized) {
                          setState(() {
                            _controller!.value.isPlaying
                                ? _controller!.pause()
                                : _controller!.play();
                          });
                        }
                      },
                      onFullscreen: _goToFullscreen,
                      currentPosition: position,
                      duration: duration,
                      currentPositionText: _formatDuration(position, duration),
                      durationText: _formatDuration(duration, duration),
                      onSeek: (value) {
                        if (_controller != null &&
                            _controller!.value.isInitialized) {
                          _controller!.seekTo(Duration(seconds: value.toInt()));
                        }
                      },
                    ),
                  )
                : _hasError
                    ? Container(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 48,
                            ),
                            SizedBox(height: 16),
                            Text(
                              '영상 재생 오류',
                              style: f18w700Size(),
                            ),
                            SizedBox(height: 8),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: Text(
                                _errorMessage,
                                style: f14w400Size().copyWith(
                                  color: Colors.grey,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            SizedBox(height: 16),
                            Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: _refreshVideo,
                                      icon: Icon(Icons.refresh),
                                      label: Text('다시 시도'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    ElevatedButton.icon(
                                      onPressed: _openInBrowser,
                                      icon: Icon(Icons.open_in_browser),
                                      label: Text('브라우저'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                if (widget.videoUrl.startsWith('http://')) ...[
                                  SizedBox(height: 12),
                                  ElevatedButton.icon(
                                    onPressed: _tryHttpsVersion,
                                    icon: Icon(Icons.security),
                                    label: Text('HTTPS로 시도'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'HTTP 트래픽이 차단되었을 수 있습니다',
                                    style: f12w400Size().copyWith(
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      )
                    : Container(
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
          ),

          // 영상과 버튼 사이 간격 (30px)
          SizedBox(height: 30),

          // 안내 텍스트
          if (_isReady && isControllerReady)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                '이벤트가 발생한 화면을 보고\n\n화재 또는 비화재로 판단하여 주시기 바랍니다.\n\n판단의 결과가 포인트 지급에 영향을 미칩니다.',
                style: f16w700Size().copyWith(
                  height: 1, // 줄 간격 조정
                ),
                textAlign: TextAlign.left,
              ),
            ),

          // 텍스트와 버튼 사이 간격 (20px)
          SizedBox(height: 50),

          // 액션 버튼들 (영상 아래)
          if (_isReady && isControllerReady)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _isSubmissionCompleted
                          ? null
                          : () {
                              // 화재감지 버튼 클릭 시 처리
                              final buttonText = _getButtonText();
                              _showStyledConfirmDialog(
                                context,
                                buttonText,
                                const Color(0xFFF61A1A),
                                () async {
                                  DialogManager.showLoading(context);
                                  try {
                                    final cameraService =
                                        CameraNotificationService();
                                    await cameraService.submitCameraResponse(
                                      falsePositive: 0, // 화재
                                      reason: null,
                                    );
                                    DialogManager.hideLoading();

                                    if (mounted) {
                                      setState(() {
                                        _isSubmissionCompleted = true;
                                        _currentVideoUrl = '';
                                        _isVideoExpired = true;
                                      });
                                    }

                                    // BottomNavigatorViewModel의 alertVideoUrl도 초기화
                                    final bottomNavViewModel =
                                        Get.find<BottomNavigatorViewModel>();
                                    bottomNavViewModel.alertVideoUrl.value = '';
                                    bottomNavViewModel.alertVideoType.value =
                                        '';
                                  } catch (e) {
                                    DialogManager.hideLoading();
                                    Get.snackbar('오류', '서버 전송 중 오류가 발생했습니다');
                                  }
                                },
                              ); // ✅ 화재감지 버튼 함수
                            },
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 164,
                        height: 46,
                        decoration: BoxDecoration(
                          color: _isSubmissionCompleted
                              ? Colors.grey
                              : const Color(0xFFF61A1A),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Center(
                          child: Text(
                            _getButtonText(),
                            style: f16w700Size().copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: _isSubmissionCompleted
                          ? null
                          : () {
                              // 오탐 버튼 클릭 시 처리
                              _showStyledConfirmDialog(
                                context,
                                "비화재",
                                const Color(0xFF030303),
                                () async {
                                  DialogManager.showLoading(context);
                                  try {
                                    final cameraService =
                                        CameraNotificationService();
                                    await cameraService.submitCameraResponse(
                                      falsePositive: 1, // 비화재(오탐)
                                      reason: null,
                                    );
                                    DialogManager.hideLoading();

                                    if (mounted) {
                                      setState(() {
                                        _isSubmissionCompleted = true;
                                        _currentVideoUrl = '';
                                        _isVideoExpired = true;
                                      });
                                    }

                                    // BottomNavigatorViewModel의 alertVideoUrl도 초기화
                                    final bottomNavViewModel =
                                        Get.find<BottomNavigatorViewModel>();
                                    bottomNavViewModel.alertVideoUrl.value = '';
                                    bottomNavViewModel.alertVideoType.value =
                                        '';
                                  } catch (e) {
                                    DialogManager.hideLoading();
                                    Get.snackbar('오류', '서버 전송 중 오류가 발생했습니다');
                                  }
                                },
                              );
                            },
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 164,
                        height: 46,
                        decoration: BoxDecoration(
                          color: _isSubmissionCompleted
                              ? Colors.grey
                              : const Color(0xFF030303),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Center(
                          child: Text(
                            '비화재',
                            style: f16w700Size().copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // 나머지 공간
          Spacer(),
        ],
      ),
    );
  }

  // 버튼 텍스트 결정 함수
  String _getButtonText() {
    return (widget.type ?? '') == '불꽃 감지' ? '화재' : '연기';
  }

  // 버튼 스타일이 적용된 확인 다이얼로그
  void _showStyledConfirmDialog(BuildContext context, String buttonText,
      Color buttonColor, VoidCallback onConfirm) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          contentPadding: const EdgeInsets.only(top: 35, bottom: 35),
          content: Container(
            width: Get.width,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              spacing: 8,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: buttonColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    buttonText,
                    style: f14w700Size().copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
                Text(
                  '로 판단하시겠습니까?',
                  style: f16w700Size(),
                ),
              ],
            ),
          ),
          actions: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Get.back();
                        onConfirm();
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: Container(
                          width: Get.width,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Color(0xff1955EE),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              '확인',
                              style: f16w700Size().copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Get.back();
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: Container(
                          width: Get.width,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Color(0xffF1F4F7),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              '취소',
                              style: f16w700Size(),
                            ),
                          ),
                        ),
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
}
