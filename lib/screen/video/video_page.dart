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
import '../../provider/notification_state.dart';
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
  bool _isPending = false; // ⭐ 보류 상태 추가
  Duration? _lastKnownDuration; // ⭐ 마지막으로 알려진 duration 저장
  final UserState us = Get.find<UserState>();
  final NotificationState ns = Get.find<NotificationState>();

  @override
  void initState() {
    super.initState();
    print('🎬 VideoPage initState - videoUrl: ${widget.videoUrl.isEmpty ? "empty" : "present"}');

    // ⭐ 모든 상태 초기화
    _currentVideoUrl = widget.videoUrl;
    _isSubmissionCompleted = false;
    _isReady = false;
    _hasError = false;
    _errorMessage = '';
    _lastPosition = Duration.zero;  // ⭐ 타임라인 초기화
    _isRequestingUpdate = false;
    _isPending = false;
    _lastKnownDuration = null;

    if (_currentVideoUrl.isNotEmpty) {
      print('✅ 영상 URL 존재 - 초기화 시작');
      _initializeVideo();
      _startExpirationTimer();
    } else {
      print('⚠️ 영상 URL 없음 - 빈 화면 표시');
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
      print('🔄 VideoPage didUpdateWidget - URL 변경 감지');
      print('   이전: ${oldWidget.videoUrl.isEmpty ? "empty" : "present"}');
      print('   현재: ${widget.videoUrl.isEmpty ? "empty" : "present"}');

      // ⭐ 기존 컨트롤러 정리
      if (_controller != null) {
        _controller!.removeListener(_videoListener);
        _controller!.pause();
        _controller!.dispose();
        _controller = null;
      }

      // ⭐ 타이머 정리
      _timer?.cancel();

      if (mounted) {
        setState(() {
          _currentVideoUrl = widget.videoUrl;
          _isSubmissionCompleted = false;
          _isVideoExpired = false;
          _hasError = false;
          _errorMessage = '';
          _isRequestingUpdate = false;
          _isPending = false;
          _lastKnownDuration = null;
          _isReady = false;  // ⭐ 로딩 상태로 전환
          _lastPosition = Duration.zero;  // ⭐ 타임라인 초기화
        });
      }

      // 새로운 비디오로 초기화
      if (_currentVideoUrl.isNotEmpty) {
        print('✅ 새로운 영상 초기화 시작');
        _initializeVideo();
        _startExpirationTimer();
      } else {
        print('⚠️ 빈 URL - 로딩 화면 유지');
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

  void _checkVideoExpiration() async {
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
      // ⭐ control_complete 체크 (주기적으로 확인)
      final docId = ns.notificationData['docId'];
      print('🔍 control_complete 체크 시작: docId=$docId');
      print('🔍 현재 notificationList: ${ns.notificationList.map((n) => n['docId']).toList()}');
      print('🔍 현재 notificationData 전체: ${ns.notificationData}');

      if (docId != null && docId.toString().isNotEmpty) {
        final cameraService = CameraNotificationService();
        final controlComplete = await cameraService.checkControlComplete(docId.toString());
        print('🔍 control_complete 결과: $controlComplete (타입: ${controlComplete.runtimeType})');

        // ⭐ control_complete가 null이면 서버에서 알림이 삭제됨 (404) → 앱에서도 제거
        if (controlComplete == null) {
          print('⚠️ 서버에 알림이 없음 (404) - 앱에서도 제거');

          // 알림 리스트에서 제거
          ns.removeNotification(docId.toString());

          // 페이지 종료 또는 다음 영상으로 전환
          if (mounted) {
            setState(() {
              _isSubmissionCompleted = true;
              _currentVideoUrl = '';
              _isVideoExpired = true;
            });
          }

          // BottomNavigatorViewModel의 alertVideoUrl도 초기화
          final bottomNavViewModel = Get.find<BottomNavigatorViewModel>();

          // 다른 영상이 있으면 다음 영상으로 전환
          if (ns.notificationList.isNotEmpty) {
            // 현재 인덱스가 범위를 벗어나면 마지막 영상으로
            if (bottomNavViewModel.currentVideoIndex.value >= ns.notificationList.length) {
              bottomNavViewModel.currentVideoIndex.value = ns.notificationList.length - 1;
            }

            // 다음 영상 로드
            await bottomNavViewModel.loadVideoAtIndex(bottomNavViewModel.currentVideoIndex.value);
          } else {
            // 더 이상 영상이 없으면 빈 페이지
            bottomNavViewModel.alertVideoUrl.value = '';
            bottomNavViewModel.alertVideoType.value = '';
          }

          return;
        }

        // control_complete가 1이면 자동 만료 (제출 완료)
        if (controlComplete == 1) {
          print('✅ control_complete=1 감지됨, 영상 자동 제거');

          // 알림 리스트에서 제거
          ns.removeNotification(docId.toString());

          // 페이지 종료 또는 다음 영상으로 전환
          if (mounted) {
            setState(() {
              _isSubmissionCompleted = true;
              _currentVideoUrl = '';
              _isVideoExpired = true;
            });
          }

          // BottomNavigatorViewModel의 alertVideoUrl도 초기화
          final bottomNavViewModel = Get.find<BottomNavigatorViewModel>();

          // 다른 영상이 있으면 다음 영상으로 전환
          if (ns.notificationList.isNotEmpty) {
            // 현재 인덱스가 범위를 벗어나면 마지막 영상으로
            if (bottomNavViewModel.currentVideoIndex.value >= ns.notificationList.length) {
              bottomNavViewModel.currentVideoIndex.value = ns.notificationList.length - 1;
            }

            // 다음 영상 로드
            await bottomNavViewModel.loadVideoAtIndex(bottomNavViewModel.currentVideoIndex.value);
          } else {
            // 더 이상 영상이 없으면 빈 페이지
            bottomNavViewModel.alertVideoUrl.value = '';
            bottomNavViewModel.alertVideoType.value = '';
          }

          _timer?.cancel();
          return;
        }
      }

      // ⭐ NotificationState에서 createDate 가져오기 (우선순위 1)
      final createDateStr = ns.notificationData['createDate'];

      DateTime? videoDate;

      if (createDateStr != null && createDateStr.toString().isNotEmpty) {
        // createDate가 있으면 사용
        videoDate = DateTime.parse(createDateStr.toString());
        print('📅 createDate 사용: $videoDate');
      } else {
        // createDate가 없으면 URL에서 날짜 추출 (기존 로직)
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

          videoDate = DateTime(year, month, day, hour, minute, second);
          print('📹 URL에서 날짜 추출: $videoDate');
        } else {
          print('⚠️ 날짜를 추출할 수 없습니다');
          return;
        }
      }

      if (videoDate != null) {
        final now = DateTime.now();
        final difference = now.difference(videoDate);

        print('비디오 날짜: $videoDate');
        print('현재 시간: $now');
        print('경과 시간: ${difference.inSeconds}초');

        // ⭐ 60초 경과 시 보류 상태로 변경 (영상은 유지)
        if (difference.inMinutes >= 1) {
          if (!_isPending) {
            if (mounted) {
              setState(() {
                _isPending = true;
              });
            }
            print('⏸️ 영상이 보류 상태로 전환됨 (60초 경과)');
          }
          // 타이머는 계속 실행하여 control_complete 체크
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

      // ⭐ duration 저장
      _lastKnownDuration = controller.value.duration;

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
      // 현재 재생 위치와 duration 저장
      final currentPosition = _controller!.value.position;
      final oldDuration = _controller!.value.duration;

      // 새 컨트롤러 생성 (기존 컨트롤러는 아직 유지)
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
      final newDuration = controller.value.duration;
      print("✅ 업데이트된 영상 초기화 성공, 기존 duration: $oldDuration, 새 duration: $newDuration");

      // ⭐ duration이 증가하지 않았으면 새 컨트롤러 버리고 마지막 프레임에서 멈춤
      if (newDuration <= oldDuration) {
        print("⏸️ 새로운 영상 부분 없음 - 마지막 프레임에서 일시정지");

        // 새 컨트롤러 dispose
        await controller.dispose();

        // 기존 컨트롤러를 마지막 프레임에서 일시정지
        if (_controller != null && _controller!.value.isInitialized) {
          final dur = _controller!.value.duration;
          await _controller!.seekTo(dur - Duration(milliseconds: 100) > Duration.zero
              ? dur - Duration(milliseconds: 100)
              : Duration.zero);
          await _controller!.pause();
        }

        _isRequestingUpdate = false;
        return;
      }

      // ⭐ duration이 증가했으므로 기존 컨트롤러를 새 컨트롤러로 교체
      print("✅ 새로운 영상 부분 감지됨 - 컨트롤러 교체");

      // 기존 컨트롤러 정리
      final oldController = _controller;
      if (oldController != null) {
        await oldController.pause();
        oldController.removeListener(_videoListener);
        await oldController.dispose();
        _controller = null;
      }

      // 로딩 상태로 변경
      if (mounted) {
        setState(() {
          _isReady = false;
        });
      }

      _lastKnownDuration = newDuration;

      // 이전 위치로 복원
      await controller.seekTo(currentPosition);
      print("📹 재생 위치 복원: $currentPosition");

      if (mounted) {
        setState(() {
          _controller = controller;
          _isReady = true;
        });
      }

      // 리스너 추가 및 재생 시작
      _controller!.addListener(_videoListener);
      _controller!.play();

      print("📹 업데이트된 영상 재생 시작 (duration: $oldDuration → $newDuration)");

    } catch (e) {
      print("❌ 업데이트된 영상 요청 실패: $e");

      // 실패 시 마지막 프레임에서 일시정지
      if (_controller != null && _controller!.value.isInitialized) {
        final dur = _controller!.value.duration;
        await _controller!.seekTo(dur - Duration(milliseconds: 100) > Duration.zero
            ? dur - Duration(milliseconds: 100)
            : Duration.zero);
        await _controller!.pause();
      }
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

          // ⭐ 안내 텍스트 (항상 표시)
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

          // ⭐ 액션 버튼들 (항상 표시, 로딩 중에는 비활성화)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Row(
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

                                    // ⭐ 다음 영상으로 전환 또는 페이지 초기화
                                    final bottomNavViewModel =
                                        Get.find<BottomNavigatorViewModel>();

                                    if (ns.notificationList.isNotEmpty) {
                                      // 현재 인덱스가 범위를 벗어나면 조정
                                      if (bottomNavViewModel.currentVideoIndex.value >= ns.notificationList.length) {
                                        bottomNavViewModel.currentVideoIndex.value = ns.notificationList.length - 1;
                                      }

                                      // 다음 영상 로드
                                      await bottomNavViewModel.loadVideoAtIndex(bottomNavViewModel.currentVideoIndex.value);
                                    } else {
                                      // 더 이상 영상이 없으면 빈 페이지
                                      bottomNavViewModel.alertVideoUrl.value = '';
                                      bottomNavViewModel.alertVideoType.value = '';
                                    }
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

                                    // ⭐ 다음 영상으로 전환 또는 페이지 초기화
                                    final bottomNavViewModel =
                                        Get.find<BottomNavigatorViewModel>();

                                    if (ns.notificationList.isNotEmpty) {
                                      // 현재 인덱스가 범위를 벗어나면 조정
                                      if (bottomNavViewModel.currentVideoIndex.value >= ns.notificationList.length) {
                                        bottomNavViewModel.currentVideoIndex.value = ns.notificationList.length - 1;
                                      }

                                      // 다음 영상 로드
                                      await bottomNavViewModel.loadVideoAtIndex(bottomNavViewModel.currentVideoIndex.value);
                                    } else {
                                      // 더 이상 영상이 없으면 빈 페이지
                                      bottomNavViewModel.alertVideoUrl.value = '';
                                      bottomNavViewModel.alertVideoType.value = '';
                                    }
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

              // ⭐ 페이지 넘김 UI (화재/비화재 버튼 아래)
                const SizedBox(height: 80),
              _buildVideoNavigationControls(),
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

  /// ⭐ 페이지 넘김 컨트롤 UI
  Widget _buildVideoNavigationControls() {
    final bottomNavViewModel = Get.find<BottomNavigatorViewModel>();

    return Obx(() {
      final totalCount = bottomNavViewModel.totalVideoCount;
      final currentIndex = bottomNavViewModel.currentVideoIndex.value;
      final hasPrevious = bottomNavViewModel.hasPreviousVideo;
      final hasNext = bottomNavViewModel.hasNextVideo;

      // 영상이 1개만 있으면 UI를 표시하지 않거나 비활성화
      if (totalCount <= 1) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Icon(Icons.arrow_back_ios, size: 36, color: Colors.grey),
            ),
            SizedBox(width: 16),
            Text(
              '1 / 1',
              style: f16w700Size().copyWith(color: Colors.grey),
            ),
            SizedBox(width: 16),
            Padding(
              padding: EdgeInsets.all(16),
              child: Icon(Icons.arrow_forward_ios, size: 36, color: Colors.grey),
            ),
          ],
        );
      }

      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 다음 영상 버튼 (더 오래된 영상, createDate 기준 왼쪽)
          GestureDetector(
            onTap: hasNext ? () {
              bottomNavViewModel.moveToNextVideo();
            } : null,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Icon(
                Icons.arrow_back_ios,
                size: 36,
                color: hasNext ? Color(0xff1955EE) : Colors.grey,
              ),
            ),
          ),

          SizedBox(width: 16),

          // 현재 위치 표시
          Text(
            '${currentIndex + 1} / $totalCount',
            style: f16w700Size().copyWith(
              color: Colors.black,
            ),
          ),

          SizedBox(width: 16),

          // 이전 영상 버튼 (더 최신 영상, createDate 기준 오른쪽)
          GestureDetector(
            onTap: hasPrevious ? () {
              bottomNavViewModel.moveToPreviousVideo();
            } : null,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Icon(
                Icons.arrow_forward_ios,
                size: 36,
                color: hasPrevious ? Color(0xff1955EE) : Colors.grey,
              ),
            ),
          ),
        ],
      );
    });
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
