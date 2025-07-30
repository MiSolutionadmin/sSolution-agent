import 'dart:convert';
import 'dart:io';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
// import 'package:webview_flutter/webview_flutter.dart';
import '../db/camera_table.dart';
import 'package:http/http.dart' as http;

class TermState extends GetxController{
  final userList = [].obs;
  final userFirst = true.obs; /// 알림 셋팅 한번만 해줄려고 하는 코드
  RxString privateContext = ''.obs; /// html url
  RxList termDateList = [].obs; /// term date List ex) 2025.01.28
  RxString termSelect = "".obs;

  /// term
  Future<void> getTermHtmlByDate(String date, String type) async {
    privateContext.value = "";

    try {
      final url = '${config.baseUrl}/getTermHtmlByDate?date=$date&type=$type';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        privateContext.value = response.body
        // <style> 제거
            .replaceAll(RegExp(r'<style[^>]*>[\s\S]*?</style>', caseSensitive: false), '')
        // <script> 제거
            .replaceAll(RegExp(r'<script[^>]*>[\s\S]*?</script>', caseSensitive: false), '')
        // <img> 제거 (self-closing 및 닫힘 없는 형식 대응)
             .replaceAll(RegExp(r'<img[^>]*>', caseSensitive: false), '');
      } else {
        privateContext.value = "<p>약관을 불러오는 데 실패했습니다.</p>";
      }
    } catch (e) {
      print('getTermHtmlByDate error: $e');
      privateContext.value = "<p>오류가 발생했습니다.</p>";
    }
  }

  /// term list
  Future<void> getTermList(String type) async {
    termDateList.clear();

    try {
      final url = '${config.baseUrl}/ssolutionTermList?type=$type';
      final response = await http.get(Uri.parse(url));
      List<dynamic> termList = jsonDecode(response.body);
      termDateList.addAll(termList);

      termSelect.value = formatTermDate(termList[0], 0);
      await getTermHtmlByDate(termList[0], type);
    } catch (e) {
      print('getTermList error: $e');
    }
  }

  /// 2025.02.18 => [현행] 2025년 2월18일 시행안
  String formatTermDate(String dateStr, int index) {
    try {
      // "2025.02.18" 형식을 DateTime으로 변환
      List<String> parts = dateStr.split('.');
      if (parts.length != 3) throw FormatException("Invalid date format");

      int year = int.parse(parts[0]);
      int month = int.parse(parts[1]);
      int day = int.parse(parts[2]);

      // 변환된 날짜 포맷
      String formattedDate = "${year}년 ${month}월 ${day}일 시행안";

      // index가 0이면 "[현행] "을 추가
      return index == 0 ? "[현행] $formattedDate" : formattedDate;
    } catch (e) {
      print("Error formatting date: $e");
      return dateStr; // 오류 발생 시 원본 반환
    }
  }
}