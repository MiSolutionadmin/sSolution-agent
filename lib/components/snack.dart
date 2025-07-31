import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomSnackbar {
  static show(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        width: Get.width,
        content: Text(message),
        duration: Duration(seconds: 3), // 스낵바가 자동으로 사라지는 시간 설정
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 10),
        padding: const EdgeInsets.all(16),

        // snackPosition: SnackPosition.TOP, // 스낵바가 화면 상단에 표시됨
      ),
    );
  }
}