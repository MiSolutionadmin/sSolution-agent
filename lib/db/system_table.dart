import 'package:get/get.dart';
import 'package:mms/provider/system_state.dart';
import 'package:http/http.dart';

import '../base_config/config.dart';

final config = AppConfig();

/// 버전 정보 가져오기
// Future<String,Dynamic> getSystem() async {
//   final sys = Get.put(SystemState());
//   final url = '${config.apiUrl}/getVersion';
//   print('url : $url');
//   final response = await get(Uri.parse(url));
//
//
// }
