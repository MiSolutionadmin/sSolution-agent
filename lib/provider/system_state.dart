import 'package:get/get.dart';

class SystemState extends GetxController{
  /// ✅ 시스템 상태 관련
  final systemMaintenance = ''.obs; // 시스템 점검 상태 (정상, 점검중 등)
  final systemMessage = ''.obs; // 시스템 메시지 (에러 메시지 등)

}