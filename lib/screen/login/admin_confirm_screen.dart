import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import '../../provider/user_state.dart';
import '../../utils/bootpay.dart';
import '../../utils/font/font.dart';

class AdminConfirm extends StatefulWidget {
  const AdminConfirm({super.key});

  @override
  State<AdminConfirm> createState() => _AdminConfirmState();
}

class _AdminConfirmState extends State<AdminConfirm> {
  final storage = new FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );
  final us = Get.put(UserState());
  String? fontSizes;

  /// 전화번호 포맷팅
  String formatPhoneNumber(String phoneNumber) {
    String cleanedPhoneNumber = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

    if (cleanedPhoneNumber.length < 11) {
      return phoneNumber;
    }
    String formattedPhoneNumber = '${cleanedPhoneNumber.substring(0, 3)}-${cleanedPhoneNumber.substring(3, 7)}-${cleanedPhoneNumber.substring(7)}';
    return formattedPhoneNumber;
  }

  /// 구분탭 밸류값에 따른 텍스트 표시
  String getGroupText(int groupValue) {
    switch (groupValue) {
      case 0:
        return '아파트';
      case 1:
        return '빌딩';
      case 2:
        return '학교';
      case 3:
        return '관공서';
      case 4:
        return '기타';
      default:
        return '없음';
    }
  }
  @override
  void initState() {
    Future.delayed(Duration.zero, () async {
      fontSizes = (await storage.read(key: "fontSizes"));
      switch (fontSizes) {
        case '2':
          us.userFont.value = 2;
          break;
        case '1':
          us.userFont.value = 1;
          break;
        case '0':
          us.userFont.value = 0;
          break;
      }
      setState(() {});
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        leading: IconButton(
            icon: Icon(Icons.arrow_back_ios),
            onPressed: () {
              Navigator.pop(context);
            }),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: Color(0xff292E35),
              ),
              child: Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '관리자명',
                          style: f16w400WhiteSize(),
                        ),
                        Text(
                          '${us.userList[0]['name']}',
                          style: f16w400WhiteSize(),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 14,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '소속',
                          style: f16w400WhiteSize(),
                        ),
                        Text(
                          '${us.userList[0]['agency']}',
                          style: f16w400WhiteSize(),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 14,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '구분',
                          style: f16w400WhiteSize(),
                        ),
                        Text(
                          getGroupText(int.parse(us.userList[0]['group'])),
                          style: f16w400WhiteSize(),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 14,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '전화번호',
                          style: f16w400WhiteSize(),
                        ),
                        Text(
                          '${formatPhoneNumber(us.userList[0]['phoneNumber'])}',
                          style: f16w400WhiteSize(),

                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: 27,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: RichText(
                text: TextSpan(
                  text: '위 정보가 맞습니까?\n',
                  style: f18w700Size(),
                  children: [
                    TextSpan(
                      text: '\n이상이 없을 경우 ',
                      style: hintf16w400Size(),
                    ),
                    TextSpan(
                      text: "'인증하기' ",
                      style: f16w700BlueSize(),
                    ),
                    TextSpan(
                      text: '버튼을 눌러주세요',
                      style: hintf16w400Size(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: GestureDetector(
        onTap: () {
          goBootpayRequest(context,us.userList[0]['pw'],'first');
        },
        child: Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            color: Color(0xff1955EE),
          ),
          child: Center(
            child: Text(
              '인증하기',
              style: f20Whitew700Size(),
            ),
          ),
        ),
      ),
    );
  }
}
