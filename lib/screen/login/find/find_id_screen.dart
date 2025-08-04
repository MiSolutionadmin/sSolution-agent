import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../../../base_config/config.dart';
import '../../../components/dialog.dart';
import '../../../utils/bootpay.dart';
import '../../../utils/font/font.dart';
import 'find_id_result_screen.dart';

class FindId extends StatefulWidget {
  const FindId({super.key});

  @override
  State<FindId> createState() => _FindIdState();
}

class _FindIdState extends State<FindId> {
  final config = AppConfig();
  final FocusNode _phoneNumFocusNode = FocusNode();
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
              Text('찾으실 이메일에\n등록된 휴대폰 번호를\n입력해주세요',
                style: f28w800Size(),
              ),
              SizedBox(height: 56,),

              /// 휴대폰 번호 입력칸
              Text('휴대폰 번호', style: f16w700Size(),),
              SizedBox(height: 8,),
              TextFormField(
                controller: _phoneNumCon,
                onFieldSubmitted: (value) {
                  _phoneNumFocusNode.unfocus();
                },
                focusNode: _phoneNumFocusNode,
                keyboardType: TextInputType.number,
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
              if(_phoneNumCon.text.trim().length != 11) {
                showOnlyConfirmDialog(context, '(-)을 제외한 올바른 번호를 입력해주세요.');
              } else {
                goBootpayRequest(context,_phoneNumCon.text,"",'id');
                // if (responseBody != '[]') {
                //   Get.to(() => FindIdResult(responseBody : responseBody));
                // } else {
                //   showOnlyConfirmDialog(context, '일치하는 사용자가 없습니다.');
                // }
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
