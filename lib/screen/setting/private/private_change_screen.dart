import 'dart:convert';
import 'package:bootpay/bootpay.dart';
import 'package:bootpay/model/extra.dart';
import 'package:bootpay/model/payload.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../../../components/dialog.dart';
import '../../../db/user_table.dart';
import '../../../provider/user_state.dart';
import '../../login/login_view.dart';
import '../../login/password_reset_view.dart';
import '../../../utils/bootpay.dart';
import '../../../utils/font/font.dart';

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
@override
  void initState() {
    _dataL = [
      '김태성',
      '시니어',
      '09:00 - 18:00',
      'taesungkim@company.com',
      '010-1234-5678',
      '********',
    ];
    us.userInfoList.value = _dataL;
    setState(() {});
    super.initState();
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
                                    us.userInfoList[index],
                                    style: f16w800GreySize(),
                                  )),
                                  if (index == 4 || index == 5)
                                    GestureDetector(
                                      onTap: () async {
                                        if (index == 4) {
                                          showConfirmTapDialog(context, '전화번호를 변경하시겠습니까?', () async {
                                            Get.back();
                                            goBootpayRequest(context, '', 'setting');
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
