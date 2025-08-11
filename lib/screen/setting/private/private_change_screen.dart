import 'dart:convert';
import 'package:bootpay/bootpay.dart';
import 'package:bootpay/model/extra.dart';
import 'package:bootpay/model/payload.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../components/dialog.dart';
import '../../../db/user_table.dart';
import '../../../provider/user_state.dart';
import '../../login/login_view.dart';
import '../../login/password_reset_view.dart';
import '../../../utils/bootpay.dart';
import '../../../utils/font/font.dart';
import '../../../base_config/config.dart';

class PrivateChange extends StatefulWidget {
  const PrivateChange({Key? key}) : super(key: key);
  static final String id = '/private';

  @override
  State<PrivateChange> createState() => _PrivateChangeState();
}

class _PrivateChangeState extends State<PrivateChange> {
  List<String> emails = ['test-1@test.com', 'test-2@test.com', 'test-3@test.com', 'test-4@test.com'];
  List _titleL = [
    '에이전트명',
    '등급',
    '근무시간',
    '이메일',
    '전화번호',
    '비밀번호',
  ];
  List _dataL = [];
  final us = Get.put(UserState());
  final config = AppConfig();
  String workTimeString = '로딩중...';
  
  static final storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

@override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    // 1. userData 다시 불러오기
    await _refreshUserData();
    
    // 2. workTime API 호출
    await _getWorkTime();
    
    // 3. userData에서 실제 데이터 가져오기
    final userData = us.userData.value;
    print("userData ${userData}");
    
    _dataL = [
      userData['name'] ?? '홍길동',                    // 에이전트명
      userData['grade'] ?? '새싹',                     // 등급
      workTimeString,                                  // 근무시간 (API에서 가져온 값)
      userData['email'] ?? 'honggildong@company.com',  // 이메일
      _maskPhoneNumber(userData['phone_number'] ?? '010-1234-5678'),  // 전화번호 (마스킹)
      '********',                                      // 비밀번호 (항상 마스킹)
    ];
    us.userInfoList.value = _dataL;
    setState(() {});
  }

  /// userData 새로고침
  Future<void> _refreshUserData() async {
    try {
      print("userData 새로고침 시작...");
      
      // 저장된 로그인 정보 가져오기
      String? username = await storage.read(key: "ids");
      String? password = await storage.read(key: "pws");
      
      if (username != null && password != null) {
        print("저장된 로그인 정보로 userData 새로고침: $username");
        
        final data = await getUser(username, password);
        
        if (data.isNotEmpty && data["user"] != null) {
          us.userData.value = data["user"];
          print("userData 새로고침 성공: ${us.userData.value}");
        } else {
          print("userData 새로고침 실패: 빈 응답");
        }
      } else {
        print("저장된 로그인 정보가 없음");
      }
    } catch (e) {
      print("userData 새로고침 오류: $e");
    }
  }

  Future<void> _getWorkTime() async {
    try {
      final url = '${config.baseUrl}/config/agent/date';
      print("workTime API 호출: $url");
      
      final response = await http.get(Uri.parse(url));
      print("workTime API 응답 상태: ${response.statusCode}");
      print("workTime API 응답 내용: ${response.body}");
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("workTime 파싱된 데이터: $data");
        
        if (data['message'] == '성공' && data['result'] != null) {
          final result = data['result'];
          final userData = us.userData.value;
          final controlType = userData['control_type'] ?? 1;
          
          print("control_type: $controlType");
          print("시간 데이터: $result");
          
          final dayStart = _formatTime(result['dayStart']);
          final dayEnd = _formatTime(result['dayEnd']);
          final nightStart = _formatTime(result['nightStart']);
          final nightEnd = _formatTime(result['nightEnd']);
          
          // control_type에 따른 시간 표시
          switch (controlType) {
            case 1: // 주간
              workTimeString = '주간($dayStart ~ $dayEnd)';
              break;
            case 2: // 야간
              workTimeString = '야간($nightStart ~ $nightEnd)';
              break;
            case 3: // 주+야간
              workTimeString = '주+야간($dayStart ~ $nightEnd)';
              break;
            default:
              workTimeString = '주간($dayStart ~ $dayEnd)'; // 기본값
              break;
          }
          
          print("최종 workTimeString: $workTimeString");
        } else {
          workTimeString = '시간 정보 파싱 실패';
        }
      } else {
        print("workTime API 호출 실패: ${response.statusCode}");
        workTimeString = '시간 정보 로드 실패';
      }
    } catch (e) {
      print("workTime API 오류: $e");
      workTimeString = '09:00 - 18:00'; // 기본값
    }
  }
  
  /// 시간 문자열을 HH:mm 형식으로 변환
  String _formatTime(String? timeString) {
    if (timeString == null) return '00:00';
    
    try {
      // "01:02:00" -> "01:02" 형식으로 변환
      final parts = timeString.split(':');
      if (parts.length >= 2) {
        return '${parts[0]}:${parts[1]}';
      }
      return timeString;
    } catch (e) {
      print("시간 포맷 오류: $e");
      return '00:00';
    }
  }

  /// 전화번호를 010-****-**** 형식으로 마스킹
  String _maskPhoneNumber(String? phoneNumber) {
    if (phoneNumber == null || phoneNumber.isEmpty) {
      return '010-****-****';
    }
    
    try {
      // 숫자만 추출
      String digits = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
      
      if (digits.length >= 11) {
        // 010-1234-5678 -> 010-****-****
        String prefix = digits.substring(0, 3);
        String suffix = digits.substring(digits.length - 4);
        return '$prefix-****-****';
      } else if (digits.length >= 8) {
        // 짧은 번호의 경우
        String prefix = digits.substring(0, 3);
        return '$prefix-****-****';
      } else {
        return '010-****-****';
      }
    } catch (e) {
      print("전화번호 마스킹 오류: $e");
      return '010-****-****';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('개인정보 변경',style: f16w900Size(),),
        centerTitle: true,
        shape: Border(
          bottom: BorderSide(
            color:  const Color(0xffEFF0F0),
            width: 1,
          ),
        ),
      ),
      backgroundColor: const Color(0xffF1F4F7),
      body: Obx(()=>SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Column(
            children: [
              Container(
                color: Colors.white,
                child: Column(
                  children: List.generate(_titleL.length, (index) {
                    return Column(
                      children: [
                        Container(
                          width: Get.width,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _titleL[index],
                                style: f16w400Size(),
                              ),
                              Row(
                                children: [
                                  Obx(() => Text(
                                    us.userInfoList.length > index ? us.userInfoList[index] : '...',
                                    style: f16w800GreySize(),
                                  )),
                                  if (index == 4 || index == 5)
                                    GestureDetector(
                                      onTap: () async {
                                        if (index == 4) {
                                          showConfirmTapDialog(context, '전화번호를 변경하시겠습니까?', () async {
                                            Get.back();
                                            goBootpayRequest(context, '', '','setting');
                                          });
                                        } else {
                                          Get.to(() => const PasswordResetView(setting: 'true'));
                                        }
                                      },
                                      child: Container(
                                        margin: const EdgeInsets.only(left: 8),
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          border: Border.all(color: const Color(0xff1955EE)),
                                          borderRadius: BorderRadius.circular(100),
                                        ),
                                        child: Text('변경', style: f13w400BlueSize()),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (index < _titleL.length - 1)
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: const Color(0xffEFF0F0),
                            indent: 20,
                            endIndent: 20,
                          ),
                      ],
                    );
                  }),
                ),
              ),
              // us.userList[0]['head']=='true'?const SizedBox():emails.contains(us.userList[0]['email'])?const SizedBox():GestureDetector(
              //   onTap: (){
              //     showConfirmTapDialog(context, '회원탈퇴하시겠습니까?', ()async{
              //       await deleteUser('${us.userList[0]['email']}');
              //       showOnlyConfirmTapDialog(context, '탈퇴가 완료되었습니다', () {
              //         Get.offAll(()=>LoginView());
              //       });
              //     });
              //   },
              //   child: Container(
              //     width: Get.width,
              //     padding: const EdgeInsets.symmetric(horizontal: 20,vertical: 16),
              //     color: Colors.white,
              //     child: Row(
              //       children: [
              //         Text('탈퇴하기',style: f16w400RedSize(),),
              //       ],
              //     ),
              //   ),
              // ),
            ],
          ),
        ),
      )),
    );
  }
}
