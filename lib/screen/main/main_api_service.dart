import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../../base_config/config.dart';

class MainApiService {
  static final MainApiService _instance = MainApiService._internal();
  factory MainApiService() => _instance;
  MainApiService._internal();

  final AppConfig _config = AppConfig();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  /// JWT 토큰 가져오기
  Future<String?> _getToken() async {
    return await _secureStorage.read(key: "jwt_token");
  }

  /// 근무 날짜 제출 API
  Future<Map<String, dynamic>> submitWorkDates({
    required String agentId,
    required List<String> workDates,
    required int control_type,
    List<String>? deleteDates,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('로그인이 필요합니다.');
      }

      final body = {
        'agent_id': agentId,
        'work_dates': workDates,
        'control_type': control_type,
      };
      
      // 삭제할 날짜가 있으면 추가
      if (deleteDates != null && deleteDates.isNotEmpty) {
        body['delete_dates'] = deleteDates;
      }

      print('근무 날짜 제출 요청: $body');

      final response = await http
          .post(
            Uri.parse('${_config.baseUrl}/agents/$agentId/workDatas'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode(body),
          )
          .timeout(const Duration(seconds: 30));

      print('근무 날짜 제출 응답 상태: ${response.statusCode}');
      print('근무 날짜 제출 응답 내용: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'data': json.decode(response.body),
          'message': '근무 날짜가 성공적으로 등록되었습니다.',
        };
      } else {
        return {
          'success': false,
          'error': '서버 오류: ${response.statusCode}',
          'message': '근무 날짜 등록에 실패했습니다.',
        };
      }
    } catch (e) {
      print('근무 날짜 제출 오류: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': '네트워크 오류가 발생했습니다.',
      };
    }
  }

  /// 월별 통계 데이터 가져오기
  Future<Map<String, dynamic>> getMonthlyStats({
    required String agentId,
    required String year,
    required String month,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('로그인이 필요합니다.');
      }

      final response = await http.get(
        Uri.parse('${_config.baseUrl}/statis/agent/$agentId?date=$year-$month'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30));

      print('월별 통계 응답 상태: ${response.statusCode}');
      print('월별 통계 응답 내용: ${response.body}');

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': json.decode(response.body)['result'],
        };
      } else {
        return {
          'success': false,
          'error': '서버 오류: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('월별 통계 로드 오류: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// 이벤트 목록 가져오기
  Future<Map<String, dynamic>> getEventList({
    required String agentId,
    required String year,
    required String month,
    String? cursor, // cursor 파라미터 추가
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('로그인이 필요합니다.');
      }

      // URL에 cursor 파라미터 추가
      String url = '${_config.baseUrl}/agents/$agentId/works?targetMonth=$year-$month';
      if (cursor != null && cursor.isNotEmpty) {
        url += '&cursor=$cursor';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30));

      print('이벤트 목록 응답 상태: ${response.statusCode}');
      print('이벤트 목록 응답 내용: ${response.body}');

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': json.decode(response.body),
        };
      } else {
        return {
          'success': false,
          'error': '서버 오류: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('이벤트 목록 로드 오류: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// 등록된 근무 날짜 조회
  Future<Map<String, dynamic>> getWorkDates({
    required String agentId,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('로그인이 필요합니다.');
      }

      final response = await http.get(
        Uri.parse('${_config.baseUrl}/agents/$agentId/workDatas'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30));

      print('근무 날짜 조회 응답 상태: ${response.statusCode}');
      print('근무 날짜 조회 응답 내용: ${response.body}');

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': json.decode(response.body),
        };
      } else {
        return {
          'success': false,
          'error': '서버 오류: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('근무 날짜 조회 오류: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// 에이전트 관제 시간 조회
  Future<Map<String, dynamic>> getAgentDate() async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('로그인이 필요합니다.');
      }

      final response = await http.get(
        Uri.parse('${_config.baseUrl}/config/agent/date'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30));

      print('에이전트 관제 시간 조회 응답 상태: ${response.statusCode}');
      print('에이전트 관제 시간 조회 응답 내용: ${response.body}');

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': json.decode(response.body),
        };
      } else {
        return {
          'success': false,
          'error': '서버 오류: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('에이전트 관제 시간 조회 오류: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// 에이전트 정보 조회
  Future<Map<String, dynamic>> getAgentInfo({
    required String agentId,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('로그인이 필요합니다.');
      }

      final response = await http.get(
        Uri.parse('${_config.baseUrl}/agents/$agentId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30));

      print('에이전트 정보 조회 응답 상태: ${response.statusCode}');
      print('에이전트 정보 조회 응답 내용: ${response.body}');

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': json.decode(response.body),
        };
      } else {
        return {
          'success': false,
          'error': '서버 오류: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('에이전트 정보 조회 오류: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}
