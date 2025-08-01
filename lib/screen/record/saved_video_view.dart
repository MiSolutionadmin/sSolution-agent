import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'saved_video_view_model.dart';
import '../video/video_fullscreen_page.dart';

class SavedVideoView extends StatelessWidget {
  final String recordId;
  final String date;
  final String alertType;
  final String eventType;
  final String result;
  final String? videoUrl;

  const SavedVideoView({
    super.key,
    required this.recordId,
    required this.date,
    required this.alertType,
    required this.eventType,
    required this.result,
    this.videoUrl,
  });

  @override
  Widget build(BuildContext context) {
    final SavedVideoViewModel viewModel = Get.put(
      SavedVideoViewModel(
        recordId: recordId,
        date: date,
        alertType: alertType,
        eventType: eventType,
        result: result,
        videoUrl: videoUrl ?? 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4', // 임시 URL
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          '저장 영상 재생',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 상단 정보 섹션
          _buildInfoSection(viewModel),
          
          // 비디오 플레이어 섹션
          _buildVideoSection(viewModel),
          
          // 하단 결과 메시지 섹션
          _buildResultSection(viewModel),
          
          // 나머지 공간
          const Spacer(),
        ],
      ),
    );
  }

  /// 상단 정보 섹션
  Widget _buildInfoSection(SavedVideoViewModel viewModel) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey, width: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('날짜', viewModel.date),
          const SizedBox(height: 8),
          _buildInfoRow('알림', viewModel.alertType),
          const SizedBox(height: 8),
          _buildInfoRow('판단', viewModel.eventType),
          const SizedBox(height: 8),
          _buildInfoRow('결과', viewModel.result, 
            resultColor: viewModel.result == 'OK' ? Colors.blue : Colors.red),
        ],
      ),
    );
  }

  /// 정보 행 위젯
  Widget _buildInfoRow(String label, String value, {Color? resultColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 60,
          child: Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: resultColor ?? Colors.black,
              fontWeight: resultColor != null ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  /// 비디오 플레이어 섹션
  Widget _buildVideoSection(SavedVideoViewModel viewModel) {
    return Container(
      child: Obx(() {
        if (viewModel.isLoading.value) {
          return _buildLoadingWidget();
        }
        
        if (viewModel.hasError.value) {
          return _buildErrorWidget(viewModel);
        }
        
        if (viewModel.isReady.value && viewModel.controller != null) {
          return _buildVideoPlayer(viewModel);
        }
        
        return _buildLoadingWidget();
      }),
    );
  }

  /// 로딩 위젯
  Widget _buildLoadingWidget() {
    return Container(
      height: 250,
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  /// 에러 위젯
  Widget _buildErrorWidget(SavedVideoViewModel viewModel) {
    return Container(
      height: 250,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              '영상 재생 오류',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Obx(() => Text(
                viewModel.errorMessage.value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              )),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: viewModel.refreshVideo,
              icon: const Icon(Icons.refresh),
              label: const Text('다시 시도'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 비디오 플레이어 위젯
  Widget _buildVideoPlayer(SavedVideoViewModel viewModel) {
    return GestureDetector(
      onTap: viewModel.toggleControls,
      child: Stack(
        children: [
          // 비디오 화면
          AspectRatio(
            aspectRatio: viewModel.aspectRatio,
            child: VideoPlayer(viewModel.controller!),
          ),
          
          // 컨트롤 오버레이
          Obx(() => viewModel.showControls.value
              ? _buildControlsOverlay(viewModel)
              : const SizedBox()),
        ],
      ),
    );
  }

  /// 컨트롤 오버레이
  Widget _buildControlsOverlay(SavedVideoViewModel viewModel) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        color: Colors.black54,
        child: Row(
          children: [
            // 시작/중지 버튼
            IconButton(
              icon: Obx(() => Icon(
                viewModel.isPlaying.value ? Icons.stop : Icons.play_arrow,
                color: Colors.white,
              )),
              onPressed: viewModel.togglePlayPause,
            ),

            // 소리 버튼
            IconButton(
              icon: Obx(() => Icon(
                viewModel.isVolumeMuted.value ? Icons.volume_off : Icons.volume_up,
                color: Colors.white,
              )),
              onPressed: viewModel.toggleVolume,
            ),

            Flexible(
              flex: 1,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 슬라이더
                  Container(
                    height: 30,
                    child: Obx(() => Slider(
                      min: 0,
                      max: viewModel.duration.value,
                      value: viewModel.currentPosition.value,
                      activeColor: Colors.red,
                      inactiveColor: Colors.white30,
                      thumbColor: Colors.white,
                      onChanged: viewModel.seekTo,
                    )),
                  ),
                  // 시간 표시
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Obx(() => Text(
                          viewModel.currentPositionText.value,
                          style: const TextStyle(color: Colors.white, fontSize: 11),
                        )),
                        Obx(() => Text(
                          viewModel.durationText.value,
                          style: const TextStyle(color: Colors.white, fontSize: 11),
                        )),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 전체화면 버튼
            IconButton(
              icon: const Icon(Icons.fullscreen, color: Colors.white),
              onPressed: () => viewModel.goToFullscreen(),
            )
          ],
        ),
      ),
    );
  }

  /// 하단 결과 메시지 섹션
  Widget _buildResultSection(SavedVideoViewModel viewModel) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(50),
      child: Column(
        children: [
          const Icon(
            Icons.info_outline,
            color: Colors.blue,
            size: 24,
          ),
          const SizedBox(height: 8),
          const Text(
            '위 영상은 이벤트 발생 후 녹화된 1분 영상입니다.',
            style: TextStyle(
              color: Colors.blue,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}