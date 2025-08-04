import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../../base_config/config.dart';
import '../../../components/dialog.dart';
import '../../../utils/bootpay.dart';
import '../../../utils/font/font.dart';
import 'find_pw_change_screen.dart';

class FindPw extends StatefulWidget {
  const FindPw({super.key});

  @override
  State<FindPw> createState() => _FindPwState();
}

class _FindPwState extends State<FindPw> {
  final config = AppConfig();
  final FocusNode _emailFocusNode  = FocusNode();
  final FocusNode _phoneNumFocusNode = FocusNode();
  final TextEditingController _emailCon = TextEditingController();
  final TextEditingController _phoneNumCon = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (){
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.white,
          leading: IconButton(
              icon: Icon(Icons.arrow_back_ios),
              onPressed: () {
                Get.back();
              }
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('이메일과 휴대폰번호를\n입력해주세요',
                style: f28w800Size(),
              ),
              SizedBox(height: 56,),

              /// 이메일 입력칸
              Text('아이디',
                style: f16w700Size(),),
              SizedBox(height: 8,),
              TextFormField(
                controller: _emailCon,
                onFieldSubmitted: (value) {
                  FocusScope.of(context).requestFocus(_phoneNumFocusNode);
                },
                focusNode: _emailFocusNode,
                onTap: () {
                  FocusScope.of(context).unfocus();
                },
                decoration: InputDecoration(
                  hintText: '이메일을 입력해주세요',
                  hintStyle: TextStyle(
                    fontSize: 12,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w400,
                    color: Color(0xffB5B5B5),
                  ),
                  contentPadding: EdgeInsets.fromLTRB(15, 18, 0, 18),
                  filled: true,
                  fillColor: Color(0xFFF5F6F7),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              SizedBox(height: 30,),

              /// 휴대폰 번호 입력칸
              Text('휴대폰 번호', style: f16w700Size(),),
              SizedBox(height: 8,),
              TextFormField(
                controller: _phoneNumCon,
                onFieldSubmitted: (value) {
                  _phoneNumFocusNode.unfocus();
                },
                focusNode: _phoneNumFocusNode,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(11)
                ],
                onTap: () {
                  FocusScope.of(context).unfocus();
                },
                decoration: InputDecoration(
                  hintText: '휴대폰 번호를 입력해주세요',
                  hintStyle: TextStyle(
                    fontSize: 12,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w400,
                    color: Color(0xffB5B5B5),
                  ),
                  contentPadding: EdgeInsets.fromLTRB(15, 18, 0, 18),
                  filled: true,
                  fillColor: Color(0xFFF5F6F7),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: GestureDetector(
            onTap: () async {
              if(_phoneNumCon.text.trim().length != 11 || _emailCon.text.trim().isEmpty) {
                showOnlyConfirmDialog(context, '입력하지 않은 값이 있습니다');
              } else {
                goBootpayRequest(context,_phoneNumCon.text,_emailCon.text,'pw');
              }
            },
            child: Container(
              width: Get.width,
              height: 60,
              color: const Color(0xff1955EE),
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(child: Text('인증하기',style: f18w700WhiteSize(),)),
            ),
          ),
        ),
      ),
    );
  }

  /// 아이디 찾기
  Future<String> findId(String phoneNum) async{
    final url = '${config.baseUrl}/findid?phoneNumber=$phoneNum';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('Failed');
    }
    return response.body;
  }
}
