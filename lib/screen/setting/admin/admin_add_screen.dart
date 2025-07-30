import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:mms/components/dialogManager.dart';
import '../../../base_config/config.dart';
import '../../../components/dialog.dart';
import '../../../provider/user_state.dart';
import 'package:http/http.dart' as http;

import '../../../utils/font/font.dart';

class AdminAddScreen extends StatefulWidget {
  const AdminAddScreen({Key? key}) : super(key: key);

  @override
  State<AdminAddScreen> createState() => _AdminAddScreenState();
}

class _AdminAddScreenState extends State<AdminAddScreen> {
  final config = AppConfig();
  List _titleL = [
    '이름',
    '이메일',
    '전화번호'
  ];

  List _hintL = [
    '이름을 입력해주세요',
    '이메일을 입력해주세요',
    '전화번호를 입력해주세요'
  ];

  List<TextEditingController> _textConL = [];
  bool emailChecking = false;
  int firstChecking = 0;
  @override
  void initState() {
    _textConL = List.generate(3, (index) => TextEditingController());

    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (){
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            '관리자 추가',
            style: f16w900Size(),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
        ),
        backgroundColor:   Colors.white,
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20,vertical: 10),
          child: ListView.builder(
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              itemCount: 3,
              itemBuilder: (_, index) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 10,),
                    Text(_titleL[index],
                      style: f16w700Size(),
                    ),
                    const SizedBox(height: 10,),
                    TextFormField(
                      controller: _textConL[index],
                      inputFormatters: index==2?
                          [
                            FilteringTextInputFormatter.digitsOnly,
                            MaskTextInputFormatter(mask: '###-####-####'),
                            LengthLimitingTextInputFormatter(13),
                          ]
                          : [
                        LengthLimitingTextInputFormatter(40),

                      ],
                      decoration: InputDecoration(
                        hintText: _hintL[index],
                        hintStyle: hintf14w400Size(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 15,vertical: 16),
                        filled: true,
                        fillColor: Color(0xFFF1F4F7),
                        enabledBorder: UnderlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                );
              }),
        ),
        bottomNavigationBar: GestureDetector(
          onTap: ()async{
            if(_textConL[0].text.trim().isEmpty ||_textConL[1].text.trim().isEmpty||_textConL[2].text.trim().isEmpty){
              showOnlyConfirmDialog(context, '빈칸을 확인해주세요');
            }else{
              if(isEmailValid(_textConL[1].text)){
                if(_textConL[2].text.length==13){
                  /// 이메일 중복 체크
                  await checkEmail();
                  if(emailChecking){
                    showConfirmTapDialog(context, '관리자명 : ${_textConL[0].text}\n\n'
                        '이메일 : ${_textConL[1].text}\n\n'
                        '전화번호 : ${formatPhoneNumber(_textConL[2].text)}\n\n 가 맞습니까?',()async{
                      firstChecking++;
                      if(firstChecking==1){
                        DialogManager.showLoading(context);
                        await addUserInfo().then((value) {
                          Get.back();
                          showOnlyConfirmTapDialog(context, '추가되었습니다', () {
                            Get.back();
                            Get.back();
                          });
                        });
                        DialogManager.hideLoading();
                      }
                    });
                  }else{
                    showOnlyConfirmDialog(context, '이메일이 중복입니다');
                  }
                }else{
                  showOnlyConfirmDialog(context, '올바른 번호를 입력해주세요');
                }
              }else{
                showOnlyConfirmDialog(context, '올바른 이메일을 입력해주세요');
              }
            }
          },
          child: Container(
            width: Get.width,
            height: 60,
            color:   const Color(0xff1955EE),
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(child: Text('추가',style: f18w700WhiteSize(),)),
          ),
        ),
      ),
    );
  }

  String formatPhoneNumber(String phoneNumber) {
    String cleanedNumber = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');

    if (cleanedNumber.length == 10) {
      return '${cleanedNumber.substring(0, 3)}-${cleanedNumber.substring(3, 6)}-${cleanedNumber.substring(6)}';
    } else if (cleanedNumber.length == 11) {
      return '${cleanedNumber.substring(0, 3)}-${cleanedNumber.substring(3, 7)}-${cleanedNumber.substring(7)}';
    } else {
      return phoneNumber;
    }
  }

  /// 관리자 추가
  Future<void> addUserInfo() async{
    final us= Get.put(UserState());

    /// camera
    final cameraUri = '${config.apiUrl}/getAdminCamera?email=${us.userList[0]['headDocId']}';
    final responses = await http.get(Uri.parse(cameraUri));
    List newList = List.from(json.decode(responses.body));
    final cameraUids = newList.map((cameraItem) => cameraItem['cameraUid']).toList();

    final url = '${config.apiUrl}/userInsert2';
    final body = ({
      'headDocId' : '${us.userList[0]['docId']}',
      'headEmail':'${us.userList[0]['email']}',
      'cameraList': jsonEncode(cameraUids),
      'adminEmail':'${_textConL[1].text}', /// 이메일
      'adminName' : '${_textConL[0].text}', /// 이름 넣는곳
      'adminPhone': '${_textConL[2].text.replaceAll('-', '')}',  /// 휴대폰 번호
      'group': '${us.userList[0]['group']}', /// 구분
      'agency':'${us.userList[0]['agency']}', /// 기관/소속
      'businessNumber':'${us.userList[0]['businessNumber']}', /// 사업자 번호
      'agencyNumber':'${us.userList[0]['agencyNumber']}',
      'address': '${us.userList[0]['address']}',
      'addressDetail' : '${us.userList[0]['addressDetail']}',
      'sido' : '${us.userList[0]['sido']}',
      'sigungu': '${us.userList[0]['sigungu']}',
      'setupDate' : '${us.userList[0]['setupDate']}', /// 설치일
      'contractDateRange' : '${us.userList[0]['contractDateRange']}', /// 계약기간
      'mms': '${us.userList[0]['mms']}',
      'ipcamId' : '${us.userList[0]['ipcamId']}',
      'chongPan': '${us.userList[0]['chongPan']}',
      'chongPanDocId': '${us.userList[0]['chongPanDocId']}',
      'branch' : '${us.userList[0]['branch']}',
      'branchDocId' : '${us.userList[0]['branchDocId']}',
      'contractPrice' : '${us.userList[0]['contractPrice']}',
      'montlyPrice' : '${us.userList[0]['montlyPrice']}',
      'first' : 'true',
      'head' : 'false'
    });
    final response = await http.post(Uri.parse(url), body: body);
    if (response.statusCode != 200) {
      print('에러에러');
      throw Exception('Failed to send email');
    }
  }
  /// 이메일 유효성 체크
  bool isEmailValid(String email) {
    // 이메일 주소의 유효성을 검사하는 정규식 패턴
    final pattern = r'^[\w-]+(\.[\w-]+)*@([a-zA-Z0-9-]+\.)+[a-zA-Z]{2,7}$';
    final regExp = RegExp(pattern);
    return regExp.hasMatch(email);
  }
  /// 아이디 중복 체크
  Future<void> checkEmail() async {
    final url = '${config.apiUrl}/checkEmailSetting?email=${_textConL[1].text}';
    final response = await http.get(Uri.parse(url));
    List<dynamic> dataList = json.decode(response.body);

    if(dataList.isEmpty){
      print('중복없음 가입가능');
      emailChecking = true;
    }else{
      emailChecking = false;
    }
    setState(() {});
    // List<dynamic> dataList = json.decode(response.body);
    if (response.statusCode != 200) {
      print('에러에러');
      throw Exception('Failed to send email');
    }
  }
}
