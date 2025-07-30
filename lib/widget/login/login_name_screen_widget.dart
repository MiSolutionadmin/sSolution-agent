import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../utils/font/font.dart';

/// ✅ ID 입력창
Widget idInputField(TextEditingController idCon, FocusNode focusNode, FocusNode nextFocusNode, Function(String) onChanged) {
  return TextFormField(
    controller: idCon,
    focusNode: focusNode,
    onFieldSubmitted: (value) => FocusScope.of(Get.context!).requestFocus(nextFocusNode),
    onChanged: onChanged,
    decoration: InputDecoration(
      hintText: '이메일을 입력해주세요',
      hintStyle: hintf14w400Size(),
      contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 16),
      filled: true,
      fillColor: Color(0xFFF1F4F7),
      enabledBorder: UnderlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
      focusedBorder: UnderlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
    ),
  );
}

/// ✅ PW 입력창
Widget pwInputField(TextEditingController pwCon, FocusNode focusNode, FocusNode nextFocusNode, bool obscureText, VoidCallback toggleObscure) {
  return TextFormField(
    controller: pwCon,
    focusNode: focusNode,
    obscureText: obscureText,
    onFieldSubmitted: (value) => FocusScope.of(Get.context!).requestFocus(nextFocusNode),
    decoration: InputDecoration(
      hintText: '비밀번호를 입력해주세요',
      hintStyle: hintf14w400Size(),
      contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 16),
      filled: true,
      fillColor: Color(0xFFF1F4F7),
      enabledBorder: UnderlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
      focusedBorder: UnderlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
      suffixIcon: GestureDetector(
        onTap: toggleObscure,
        child: Icon(
          obscureText ? Icons.visibility_off : Icons.visibility,
          color: Color(0xff999FAF),
        ),
      ),
    ),
  );
}

/// ✅ 아이디 저장 체크박스
Widget saveIdCheckbox(bool isChecked, VoidCallback onTap) {
  return Row(
    children: [
      GestureDetector(
        onTap: onTap,
        child: SvgPicture.asset(
          isChecked ? 'assets/icon/check.svg' : 'assets/icon/uncheck.svg',
          width: 21,
          height: 21,
        ),
      ),
      SizedBox(width: 10),
      Text('아이디 저장', style: f14w700Size()),
    ],
  );
}
