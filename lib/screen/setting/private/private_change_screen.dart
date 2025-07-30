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
import '../../login/login_name_screen.dart';
import '../../login/pw_change_screen.dart';
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
    '관리자명',
    '소속',
    '구분',
    '이메일',
    '전화번호',
    '비밀번호',
  ];
  List _dataL = [];
@override
  void initState() {
    _dataL = [
      '${us.userList[0]['name']}',
      '${us.userList[0]['agency']}',
      '${us.userList[0]['head'] == 'true'?'주관리자':'일반'}',
      '${us.userList[0]['email']}',
      '${us.userList[0]['phoneNumber']}',
      '',
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
              ListView.builder(
                  shrinkWrap: true,
                  itemCount: _titleL.length,
                  itemBuilder: (_,index){
                    return Column(
                      children: [
                        Container(
                          width: Get.width,
                          padding: const EdgeInsets.symmetric(horizontal: 20,vertical: 16),
                          color: Colors.white,
                          child: Row(
                            children: [
                              Text(_titleL[index],style: f16w400Size(),),
                              Spacer(),
                              Obx(()=>Text(us.userInfoList[index],style: f16w800GreySize())),
                              index == 4 || index == 5 ? GestureDetector(
                                onTap: ()async {
                                  if(index==4){
                                    showConfirmTapDialog(context, '전화번호를 변경하시겠습니까?', () async{
                                      Get.back();
                                      goBootpayRequest(context, '', 'setting');
                                    });
                                  }
                                  else {
                                    Get.to(() => PwChange(setting: 'true'));
                                  }
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 10,vertical: 4),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: const Color(0xff1955EE)),
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  child: Text('변경',style: f13w400BlueSize(),),
                                ),
                              ) : SizedBox()
                            ],
                          ),
                        ),
                        // const SizedBox(height: 1,)
                      ],
                    );
                  }
              ),
              us.userList[0]['head']=='true'?const SizedBox():emails.contains(us.userList[0]['email'])?const SizedBox():GestureDetector(
                onTap: (){
                  showConfirmTapDialog(context, '회원탈퇴하시겠습니까?', ()async{
                    await deleteUser('${us.userList[0]['email']}');
                    showOnlyConfirmTapDialog(context, '탈퇴가 완료되었습니다', () {
                      Get.offAll(()=>LoginName());
                    });
                  });
                },
                child: Container(
                  width: Get.width,
                  padding: const EdgeInsets.symmetric(horizontal: 20,vertical: 16),
                  color: Colors.white,
                  child: Row(
                    children: [
                      Text('탈퇴하기',style: f16w400RedSize(),),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      )),
    );
  }
}
