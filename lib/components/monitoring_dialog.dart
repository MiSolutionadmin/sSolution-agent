import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

import '../provider/user_state.dart';
import '../utils/font/font.dart';
import '../utils/loading.dart';

/// 로그인 로딩
showLoadingDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        contentPadding: const EdgeInsets.only(top: 35, bottom: 35),
        content: Container(
          width: Get.width,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text(
                "로그인 중...",
                style: f16w700Size(),
              ),
            ],
          ),
        ),
      );
    },
  );
}

showLoading(BuildContext context) {
  showDialog(
    barrierDismissible: false,
    builder: (ctx) {
      return Center(child: WillPopScope(
          onWillPop: () async => false,
          child: LoadingScreen()));
    },
    context: context,
  );
}
showConfirmTapDialog(BuildContext context, String title,VoidCallback onTap) {
  showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          contentPadding: const EdgeInsets.only(top: 35, bottom: 35),
          content: Container(
            width: Get.width,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              '${title}',
              style: f16w700Size(),
              textAlign: TextAlign.center,
            ),
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Get.back();
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Center(
                      child: Container(
                        width: Get.width,
                        height: 42,
                        decoration: BoxDecoration(color: Color(0xffD3D8DE), borderRadius: BorderRadius.circular(8)),
                        child: Center(
                            child: Text(
                              '취소',
                              style: f16w700Size(),
                            )),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8,),
                Expanded(
                  child: GestureDetector(
                    onTap: onTap,
                    behavior: HitTestBehavior.opaque,
                    child: Center(
                      child: Container(
                        width: Get.width,
                        height: 42,
                        decoration: BoxDecoration(color: Color(0xff1955EE), borderRadius: BorderRadius.circular(8)),
                        child: Center(
                            child: Text(
                              '확인',
                              style: f16w700WhiteSize(),
                            )),
                      ),
                    ),
                  ),
                ),
              ],
            )
          ],
        );
      });
}



showOnlyConfirmDialog(BuildContext context, String title) {
  showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          contentPadding: const EdgeInsets.only(top: 35, bottom: 35),
          content: Container(
            width: Get.width,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              '${title}',
              style: f16w700Size(),
              textAlign: TextAlign.center,
            ),
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Get.back();
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Center(
                      child: Container(
                        width: Get.width,
                        height: 42,
                        decoration: BoxDecoration(color: Color(0xff1955EE), borderRadius: BorderRadius.circular(8)),
                        child: Center(
                            child: Text(
                              '확인',
                              style: f16w700WhiteSize(),
                            )),
                      ),
                    ),
                  ),
                ),
              ],
            )
          ],
        );
      });
}


showOnlyConfirmTapDialog(BuildContext context, String title,VoidCallback ontap) {
  showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          contentPadding: const EdgeInsets.only(top: 35, bottom: 35),
          content: Container(
            width: Get.width,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              '${title}',
              style: f16w700Size(),
              textAlign: TextAlign.center,
            ),
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: ontap,
                    behavior: HitTestBehavior.opaque,
                    child: Center(
                      child: Container(
                        width: Get.width,
                        height: 42,
                        decoration: BoxDecoration(color: Color(0xff1955EE), borderRadius: BorderRadius.circular(8)),
                        child: Center(
                            child: Text(
                              '확인',
                              style: f16w700WhiteSize(),
                            )),
                      ),
                    ),
                  ),
                ),
              ],
            )
          ],
        );
      });
}

showSettingValueDialog(BuildContext context,  TextEditingController _con1,VoidCallback onTap) {
  showDialog(
      context: context,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            contentPadding: const EdgeInsets.only(top: 35, bottom: 35),
            content: Container(
                width: Get.width,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '계량기 세팅 값을 입력해주세요',
                      style: f16w700Size(),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10,),
                    TextFormField(
                      // obscuringCharacter: "*",
                      controller: _con1,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(20)
                      ],
                      decoration: InputDecoration(
                        hintText: '값 입력',
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
                )
            ),
            actions: [
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Get.back();
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: Container(
                          width: Get.width,
                          height: 42,
                          decoration: BoxDecoration(color: Color(0xffD3D8DE), borderRadius: BorderRadius.circular(8)),
                          child: Center(
                              child: Text(
                                '취소',
                                style: f16w700Size(),
                              )),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8,),
                  Expanded(
                    child: GestureDetector(
                      onTap: onTap,
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: Container(
                          width: Get.width,
                          height: 42,
                          decoration: BoxDecoration(color: Color(0xff1955EE), borderRadius: BorderRadius.circular(8)),
                          child: Center(
                              child: Text(
                                '확인',
                                style: f16w700WhiteSize(),
                              )),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        );
      });
}

showCameraAddDialog(BuildContext context,VoidCallback onTap,TextEditingController _con1, TextEditingController _con2, TextEditingController _con3) {
  showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          contentPadding: const EdgeInsets.only(top: 35, bottom: 35),
          content: Container(
              width: Get.width,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '카메라 모델명과 카메라이름 그리고 비밀번호를 입력해주세요',
                    style: f16w700Size(),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10,),
                  TextFormField(
                    // obscuringCharacter: "*",
                    controller: _con1,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(20)
                    ],
                    decoration: InputDecoration(
                      hintText: '카메라 uid 입력',
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
                  const SizedBox(height: 10,),
                  TextFormField(
                    controller: _con2,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(20)
                    ],
                    decoration: InputDecoration(
                      hintText: '카메라 id 입력',
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
                  const SizedBox(height: 10,),
                  TextFormField(
                    controller: _con3,
                    obscuringCharacter: "*",
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(20)
                    ],
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: '카메라 비밀번호 입력',
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
              )
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Get.back();
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Center(
                      child: Container(
                        width: Get.width,
                        height: 42,
                        decoration: BoxDecoration(color: Color(0xffD3D8DE), borderRadius: BorderRadius.circular(8)),
                        child: Center(
                            child: Text(
                              '취소',
                              style: f16w700Size(),
                            )),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8,),
                Expanded(
                  child: GestureDetector(
                    onTap: onTap,
                    behavior: HitTestBehavior.opaque,
                    child: Center(
                      child: Container(
                        width: Get.width,
                        height: 42,
                        decoration: BoxDecoration(color: Color(0xff1955EE), borderRadius: BorderRadius.circular(8)),
                        child: Center(
                            child: Text(
                              '등록',
                              style: f16w700WhiteSize(),
                            )),
                      ),
                    ),
                  ),
                ),
              ],
            )
          ],
        );
      });
}

showValveTapDialog(BuildContext context, String title,VoidCallback onTap) {
  showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          contentPadding: const EdgeInsets.only(top: 35, bottom: 35),
          content: Container(
            width: Get.width,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              '${title}',
              style: f16w700Size(),
              textAlign: TextAlign.center,
            ),
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Get.back();
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Center(
                      child: Container(
                        width: Get.width,
                        height: 42,
                        decoration: BoxDecoration(color: Color(0xffD3D8DE), borderRadius: BorderRadius.circular(8)),
                        child: Center(
                            child: Text(
                              '아니오',
                              style: f16w700Size(),
                            )),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8,),
                Expanded(
                  child: GestureDetector(
                    onTap: onTap,
                    behavior: HitTestBehavior.opaque,
                    child: Center(
                      child: Container(
                        width: Get.width,
                        height: 42,
                        decoration: BoxDecoration(color: Color(0xff1955EE), borderRadius: BorderRadius.circular(8)),
                        child: Center(
                            child: Text(
                              '네',
                              style: f16w700WhiteSize(),
                            )),
                      ),
                    ),
                  ),
                ),
              ],
            )
          ],
        );
      });
}


class CustomAlertDialog extends StatefulWidget {
  final String title;
  final VoidCallback? onTap;

  const CustomAlertDialog({Key? key, required this.title, this.onTap}) : super(key: key);

  @override
  _CustomAlertDialogState createState() => _CustomAlertDialogState();
}

class _CustomAlertDialogState extends State<CustomAlertDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      contentPadding: const EdgeInsets.only(top: 35, bottom: 35),
      content: Container(
        height: 130,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            SvgPicture.asset('assets/icon/alert.svg'),
            const SizedBox(height: 10,),
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: f24w700Size(),
            ),
          ],
        ),
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: widget.onTap ?? () {},
                behavior: HitTestBehavior.opaque,
                child: Center(
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(color: Color(0xff1955EE), borderRadius: BorderRadius.circular(8)),
                    child: Center(
                      child: Text(
                        '확인',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        )
      ],
    );
  }
}