import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MainViewModel extends GetxController {
  // 로딩 상태
  final RxBool isLoading = false.obs;
  
  // 메인 화면 데이터
  final RxString title = '메인'.obs;
  final RxList<String> statusItems = <String>[].obs;
  
  @override
  void onInit() {
    super.onInit();
    _initializeData();
  }
  
  @override
  void onClose() {
    super.onClose();
  }
  
  /// 데이터 초기화
  void _initializeData() {
    isLoading.value = true;
    
    try {
      // 메인 화면 초기 데이터 설정
      statusItems.addAll([
        '시스템 상태: 정상',
        '연결된 장치: 5개',
        '최근 경보: 없음',
      ]);
    } catch (e) {
      print('메인 데이터 초기화 오류: $e');
    } finally {
      isLoading.value = false;
    }
  }
  
  /// 새로고침
  void refresh() {
    _initializeData();
  }
  
  /// 상태 아이템 추가
  void addStatusItem(String item) {
    statusItems.add(item);
  }
  
  /// 상태 아이템 제거
  void removeStatusItem(int index) {
    if (index >= 0 && index < statusItems.length) {
      statusItems.removeAt(index);
    }
  }
}