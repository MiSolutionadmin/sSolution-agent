import 'package:flutter/material.dart';

import '../login/terms_screen.dart';

class AdminConfirm extends StatefulWidget {
  const AdminConfirm({super.key});

  @override
  State<AdminConfirm> createState() => _AdminConfirmState();
}

class _AdminConfirmState extends State<AdminConfirm> {
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
            }
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('관리자명',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 26,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 20,),
            Text('가나다',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 22,
                fontWeight: FontWeight.w400,
              ),
            ),
            SizedBox(height: 20,),
            Text('소속',
              style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),),
            SizedBox(height: 20,),
            Text('김나다 아파트',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 22,
                fontWeight: FontWeight.w400,
              ),),
            SizedBox(height: 20,),
            Text('구분',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 26,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 20,),
            Text('주관리자',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 22,
                fontWeight: FontWeight.w400,
              ),),
            SizedBox(height: 20,),
            Text('전화번호',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 26,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 20,),
            Text('010-1234-1234',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 22,
                fontWeight: FontWeight.w400,
              ),),
            SizedBox(height: 60,),
            RichText(
              text: TextSpan(
                text: '가 맞습니까?\n',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 22,
                  fontWeight: FontWeight.w400,
                  color: Colors.black
                ),
                children: [
                  TextSpan(
                    text: '이상이 없을 경우 ',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 22,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  TextSpan(
                    text: "'인증하기'",
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(
                    text: '\n버튼을 눌러주시기 바랍니다.',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 22,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),

          ],

        ),
      ),
      bottomNavigationBar: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => Terms()),
          );
        },
        child: Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            color: Color(0xff00881E),
          ),
          child: Center(
            child: Text('인증하기',
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white
            ),),
          ),
        ),
      ),
    );
  }
}
