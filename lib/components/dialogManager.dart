
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mms/utils/loading.dart';
import '../provider/camera_state.dart';
import '../utils/font/font.dart';

class DialogManager  {
  // 로딩 다이얼로그용 OverlayEntry (하나만 존재)
  static OverlayEntry? _loadingEntry;

  // 알림 다이얼로그들을 담는 리스트 (여러개 가능)
  static List<OverlayEntry> _alertEntries = [];


  /// 로딩 다이얼로그 표시
  /// 이미 로딩이 표시 중이면 무시
  static showLoading(BuildContext context) {
    // 이미 로딩 다이얼로그가 있으면 중복 생성 방지
    if (_loadingEntry != null) return;
    // OverlayEntry 생성 - 화면에 띄울 위젯을 정의
    _loadingEntry = OverlayEntry(
      builder: (context) => PopScope(
        canPop: false, // 뒤로가기 막기
        child: Material(
          color: Colors.black54, // 반투명 배경
          child: Center(
            child: LoadingScreen(), // 실제 로딩 위젯
          ),
        ),
      ),
    );

    // 현재 화면의 Overlay에 로딩 다이얼로그 삽입
    Overlay.of(context).insert(_loadingEntry!);
  }


  /// 로딩 다이얼로그 숨기기
  /// 로딩이 있을 때만 제거
  static hideLoading() {
    // 로딩 다이얼로그가 있으면 제거
    _loadingEntry?.remove();
    // 참조 초기화
    _loadingEntry = null;
  }

  /// 카메라 로그인 로딩
  static showLoginLoading(BuildContext context) {
    if (_loadingEntry != null) return;
    final cs = Get.find<CameraState>();
    _loadingEntry = OverlayEntry(
      builder: (context) {
        return Material(
          color: Colors.black54, // 반투명 배경
          child: Center(
            child: PopScope(
              canPop: false,
              onPopInvoked: (bool pop) async {
                if (pop) {
                  return;
                }
                cs.cancelableOperation.value?.cancel();
              },
              child: AlertDialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                contentPadding: const EdgeInsets.only(top: 35, bottom: 35),
                content: Container(
                  width: Get.width,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 20),
                      Text(
                        "로그인 중...",
                        style: f16w700Size(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
    // 현재 화면의 Overlay에 로딩 다이얼로그 삽입
    Overlay.of(context).insert(_loadingEntry!);
  }


/// 알림 다이얼로그 표시
  /// 여러개 동시에 표시 가능 ( 지우지 마세요 주석 처리된 부분은 나중에 필요할 때 사용 )
  // static showAlert(Widget alert) {
  //   // 새로운 알림용 OverlayEntry 생성
  //   final entry = OverlayEntry(
  //     builder: (context) => Material(
  //       color: Colors.black26, // 살짝 어두운 배경
  //       child: Center(
  //         child: alert, // 전달받은 알림 위젯
  //       ),
  //     ),
  //   );
  //
  //   // 알림 리스트에 추가
  //   _alertEntries.add(entry);
  //
  //   // 화면에 표시
  //   Overlay.of(Get.context!).insert(entry);
  // }
  //
  // /// 가장 최근에 표시된 알림 다이얼로그 하나만 제거
  // static hideLastAlert() {
  //   // 표시된 알림이 있는지 확인
  //   if (_alertEntries.isNotEmpty) {
  //     // 리스트에서 마지막(최신) 알림을 제거하고 화면에서도 제거
  //     _alertEntries.removeLast().remove();
  //   }
  // }
  //
  // /// 모든 알림 다이얼로그 제거
  // static hideAllAlerts() {
  //   // 모든 알림 엔트리를 화면에서 제거
  //   for (var entry in _alertEntries) {
  //     entry.remove();
  //   }
  //   // 리스트 초기화
  //   _alertEntries.clear();
  // }
  //
  // /// 현재 로딩 상태 확인
  // static bool get isLoadingShown => _loadingEntry != null;
  //
  // /// 현재 표시된 알림 개수
  // static int get alertCount => _alertEntries.length;
  //
  // /// 모든 다이얼로그 제거 (로딩 + 알림 모두)
  // static hideAll() {
  //   hideLoading();
  //   hideAllAlerts();
  // }
}