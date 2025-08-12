import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';

import '../../../provider/camera_state.dart';
import '../../../provider/user_state.dart';
import '../color.dart';
final storage = new FlutterSecureStorage(
  aOptions: AndroidOptions(
    encryptedSharedPreferences: true,
  ),
);
final us = Get.put(UserState());
final cs = Get.find<CameraState>();
///black 대 폰트
var f28w800Size = () => TextStyle(
  fontSize: 28 - (0.8 * double.parse('${us.userFont.value}')),
  color: blackColor,
  fontWeight: FontWeight.w800,
  fontFamily: 'Pretendard',
);
var f16w800Size = () => TextStyle(
  fontSize: 16 - (0.8 * double.parse('${us.userFont.value}')),
  color: Colors.black,
  fontWeight: FontWeight.w800,
  fontFamily: 'Pretendard',
);

var f34w700Size = () => TextStyle(
  fontSize: 34 - (0.8 * double.parse('${us.userFont.value}')),
  color: Colors.black,
  fontWeight: FontWeight.w700,
  fontFamily: 'Pretendard',
);
var f28w700Size = () => TextStyle(
  fontSize: 28 - (0.8 * double.parse('${us.userFont.value}')),
  color: blackColor,
  fontWeight: FontWeight.w700,
  fontFamily: 'Pretendard',
);
const TextStyle f28w700 = TextStyle(
    fontSize: 28,
    color: blackColor,
    fontWeight: FontWeight.w700,
    fontFamily: 'Pretendard');
final f24w700Size = () => TextStyle(
  fontSize: 24 - (0.8 * double.parse('${us.userFont.value}')),
  color: blackColor,
  fontWeight: FontWeight.w700,
  fontFamily: 'Pretendard',
);
const TextStyle f24w700 = TextStyle(
    fontSize: 24,
    color: blackColor,
    fontWeight: FontWeight.w700,
    fontFamily: 'Pretendard');

const TextStyle f22w700 = TextStyle(
    fontSize: 22,
    color: blackColor,
    fontWeight: FontWeight.w700,
    fontFamily: 'Pretendard');

var f20w700Size = () => TextStyle(
  fontSize: 20 - (0.8 * double.parse('${us.userFont.value}')),
  color: blackColor,
  fontWeight: FontWeight.w700,
  fontFamily: 'Pretendard',
);

var f20w700SizeScale = () => TextStyle(
  fontSize: 20/cs.cameraDetailScale.value,
  color: blackColor,
  fontWeight: FontWeight.w700,
  fontFamily: 'Pretendard',
);
var f20w700SizeScale2 = () => TextStyle(
  fontSize: 20/cs.tfCameraDetailScale.value,
  color: blackColor,
  fontWeight: FontWeight.w700,
  fontFamily: 'Pretendard',
);
const TextStyle f20w700 = TextStyle(
    fontSize: 20,
    color: blackColor,
    fontWeight: FontWeight.w700,
    fontFamily: 'Pretendard');
var f18w700Size = () => TextStyle(
  fontSize: 18 - (0.8 * double.parse('${us.userFont.value}')),
  color: blackColor,
  fontWeight: FontWeight.w700,
  fontFamily: 'Pretendard',
);

var f16w700Size = () => TextStyle(
  fontSize: 16 - (0.8 * double.parse('${us.userFont.value}')),
  color: blackColor,
  fontWeight: FontWeight.w700,
  fontFamily: 'Pretendard',
);
const TextStyle f16w700 = TextStyle(
    fontSize: 16,
    color: blackColor,
    fontWeight: FontWeight.w700,
    fontFamily: 'Pretendard');
const TextStyle f20w700White = TextStyle(
    fontSize: 20,
    color: whiteColor,
    fontWeight: FontWeight.w700,
    fontFamily: 'Pretendard');
var f14w700Size = () => TextStyle(
  fontSize: 14 - (0.8 * double.parse('${us.userFont.value}')),
  color: blackColor,
  fontWeight: FontWeight.w700,
  fontFamily: 'Pretendard',
);

var f12w700Size = () => TextStyle(
  fontSize: 12 - (0.8 * double.parse('${us.userFont.value}')),
  color: blackColor,
  fontWeight: FontWeight.w700,
  fontFamily: 'Pretendard',
);

const TextStyle f14w700 = TextStyle(
    fontSize: 14,
    color: blackColor,
    fontWeight: FontWeight.w700,
    fontFamily: 'Pretendard');
const TextStyle f12w700 = TextStyle(
    fontSize: 12,
    color: blackColor,
    fontWeight: FontWeight.w700,
    fontFamily: 'Pretendard');
/// w500
var f24w500Size = () => TextStyle(
  fontSize: 24 - (0.8 * double.parse('${us.userFont.value}')),
  color: blackColor,
  fontWeight: FontWeight.w500,
  fontFamily: 'Pretendard',
);
var f14w500Size = () => TextStyle(
  fontSize: 14 - (0.8 * double.parse('${us.userFont.value}')),
  color: blackColor,
  fontWeight: FontWeight.w500,
  fontFamily: 'Pretendard',
);
const TextStyle f24w500 = TextStyle(
    fontSize: 24,
    color: blackColor,
    fontWeight: FontWeight.w500,
    fontFamily: 'Pretendard');
const TextStyle f12w500 = TextStyle(
    fontSize: 12,
    color: blackColor,
    fontWeight: FontWeight.w500,
    fontFamily: 'Pretendard');
const TextStyle f22w500 = TextStyle(
    fontSize: 22,
    color: blackColor,
    fontWeight: FontWeight.w500,
    fontFamily: 'Pretendard');
var f20w500Size = () => TextStyle(
  fontSize: 20 - (0.8 * double.parse('${us.userFont.value}')),
  color: blackColor,
  fontWeight: FontWeight.w500,
  fontFamily: 'Pretendard',
);
const TextStyle f20w500 = TextStyle(
    fontSize: 20,
    color: blackColor,
    fontWeight: FontWeight.w500,
    fontFamily: 'Pretendard');
const TextStyle f18w500 = TextStyle(
    fontSize: 18,
    color: blackColor,
    fontWeight: FontWeight.w500,
    fontFamily: 'Pretendard');

var f18w500Size = () => TextStyle(
  fontSize: 18 - (0.8 * double.parse('${us.userFont.value}')),
  color: blackColor,
  fontWeight: FontWeight.w500,
  fontFamily: 'Pretendard',
);

var f16w500Size = () => TextStyle(
  fontSize: 16 - (0.8 * double.parse('${us.userFont.value}')),
  color: blackColor,
  fontWeight: FontWeight.w500,
  fontFamily: 'Pretendard',
);

/// w400
var f24w400Size = () => TextStyle(
  fontSize: 24 - (0.8 * double.parse('${us.userFont.value}')),
  color: blackColor,
  fontWeight: FontWeight.w400,
  fontFamily: 'Pretendard',
);
const TextStyle f24w400 = TextStyle(
    fontSize: 24,
    color: blackColor,
    fontWeight: FontWeight.w400,
    fontFamily: 'Pretendard');
var f18w400Size = () => TextStyle(
  fontSize: 18 - (0.8 * double.parse('${us.userFont.value}')),
  color: blackColor,
  fontWeight: FontWeight.w400,
  fontFamily: 'Pretendard',
);

var f14w400Size = () => TextStyle(
  fontSize: 14 - (0.8 * double.parse('${us.userFont.value}')),
  color: blackColor,
  fontWeight: FontWeight.w400,
  fontFamily: 'Pretendard',
);

var f12w400Size = () => TextStyle(
  fontSize: 12 - (0.8 * double.parse('${us.userFont.value}')),
  color: blackColor,
  fontWeight: FontWeight.w400,
  fontFamily: 'Pretendard',
);

/// white
const TextStyle f12Whitew700 = TextStyle(
    fontSize: 12,
    color: whiteColor,
    fontWeight: FontWeight.w700,
    fontFamily: 'Pretendard');
var f14Whitew700Size = () => TextStyle(
  fontSize: 14 - (0.8 * double.parse('${us.userFont.value}')),
  color: whiteColor,
  fontWeight: FontWeight.w700,
  fontFamily: 'Pretendard',
);
var f20Whitew700Size = () => TextStyle(
  fontSize: 20 - (0.8 * double.parse('${us.userFont.value}')),
  color: whiteColor,
  fontWeight: FontWeight.w700,
  fontFamily: 'Pretendard',
);

const TextStyle f20Whitew700 = TextStyle(
    fontSize: 20,
    color: whiteColor,
    fontWeight: FontWeight.w700,
    fontFamily: 'Pretendard');

///hint
var hintf24w400Size = () => TextStyle(
  fontSize: 24 - (0.8 * double.parse('${us.userFont.value}')),
  color: hintColor,
  fontWeight: FontWeight.w400,
  fontFamily: 'Pretendard',
);
const TextStyle hintf24w400 = TextStyle(
    fontSize: 24,
    color: hintColor,
    fontWeight: FontWeight.w400,
    fontFamily: 'Pretendard');
const TextStyle hintf14w700 = TextStyle(
    fontSize: 14,
    color: hintColor,
    fontWeight: FontWeight.w700,
    fontFamily: 'Pretendard');
const TextStyle hintf10w400 = TextStyle(
    fontSize: 10,
    color: hintColor,
    fontWeight: FontWeight.w400,
    fontFamily: 'Pretendard');
var hintf18w400Size = () => TextStyle(
  fontSize: 18 - (0.8 * double.parse('${us.userFont.value}')),
  color: hintColor,
  fontWeight: FontWeight.w400,
  fontFamily: 'Pretendard',
);
const TextStyle hintf18w400 = TextStyle(
    fontSize: 18,
    color: hintColor,
    fontWeight: FontWeight.w400,
    fontFamily: 'Pretendard');

/// redColor
final redf18w700= () => TextStyle(
  fontSize: 18 - (0.8 * double.parse('${us.userFont.value}')),
  color: redColor,
  fontWeight: FontWeight.w700,
  fontFamily: 'Pretendard',
);

/// blueColor
final bluef18w700= () => TextStyle(
  fontSize: 18 - (0.8 * double.parse('${us.userFont.value}')),
  color: blueColor,
  fontWeight: FontWeight.w700,
  fontFamily: 'Pretendard',
);
///
final grf14w600= () => TextStyle(
  fontSize: 14 - (0.8 * double.parse('${us.userFont.value}')),
  color: Color(0xff393A3A),
  fontWeight: FontWeight.w600,
  fontFamily: 'Pretendard',
);

final f15w600Blue = () => TextStyle(
  fontSize: 15 - (0.8 * double.parse('${us.userFont.value}')),
  color: Color(0xff1955ee),
  fontWeight: FontWeight.w600,
  fontFamily: 'Pretendard',
);

final f16w700Blue = () => TextStyle(
  fontSize: 16 - (0.8 * double.parse('${us.userFont.value}')),
  color: Color(0xff1955ee),
  fontWeight: FontWeight.w700,
  fontFamily: 'Pretendard',
);

final f15w600Grey = () => TextStyle(
  fontSize: 15 - (0.8 * double.parse('${us.userFont.value}')),
  color: Color(0xffAEB1B9),
  fontWeight: FontWeight.w600,
  fontFamily: 'Pretendard',
);

final f13w500Grey = () => TextStyle(
  fontSize: 13 - (0.8 * double.parse('${us.userFont.value}')),
  color: Color(0xffAEB1B9),
  fontWeight: FontWeight.w500,
  fontFamily: 'Pretendard',
);

const TextStyle f14w700Black = TextStyle(
    fontSize: 14,
    color: blackColor,
    fontWeight: FontWeight.w700,
    fontFamily: 'Pretendard');
const TextStyle f18w700 = TextStyle(
    fontSize: 18,
    color: blackColor,
    fontWeight: FontWeight.w700,
    fontFamily: 'Pretendard');

const TextStyle f18w700BlurGrey = TextStyle(
    fontSize: 18,
    color: Colors.grey,
    fontWeight: FontWeight.w700,
    fontFamily: 'Pretendard');

const TextStyle f24w700BlurGrey = TextStyle(
    fontSize: 24,
    color: Colors.grey,
    fontWeight: FontWeight.w500,
    fontFamily: 'Pretendard');
const TextStyle f28w700BlurGrey = TextStyle(
    fontSize: 28,
    color: Colors.grey,
    fontWeight: FontWeight.w500,
    fontFamily: 'Pretendard');
const TextStyle f10w700BlurGrey = TextStyle(
    fontSize: 10,
    color: Colors.grey,
    fontWeight: FontWeight.w700,
    fontFamily: 'Pretendard');
const TextStyle f12w700BlurGrey = TextStyle(
    fontSize: 12,
    color: Colors.grey,
    fontWeight: FontWeight.w700,
    fontFamily: 'Pretendard');

const TextStyle f14w700BlurGrey = TextStyle(
    fontSize: 14,
    color: Colors.grey,
    fontWeight: FontWeight.w700,
    fontFamily: 'Pretendard');
var f16w700Sizegrey = () => TextStyle(
  fontSize: 16 - (0.8 * double.parse('${us.userFont.value}')),
  color: Color(0xffAEB1B9),
  fontWeight: FontWeight.w700,
  fontFamily: 'Pretendard',
);
var hintf16w400Size = () => TextStyle(
  fontSize: 16 - (0.8 * double.parse('${us.userFont.value}')),
  color: hintColor,
  fontWeight: FontWeight.w400,
  fontFamily: 'Pretendard',
);
var hintf14w400Size = () => TextStyle(
  fontSize: 14 - (0.8 * double.parse('${us.userFont.value}')),
  color: Color(0xff9298A2),
  fontWeight: FontWeight.w400,
  fontFamily: 'Pretendard',
);
var f16w400WhiteSize = () => TextStyle(
  fontSize: 16 - (0.8 * double.parse('${us.userFont.value}')),
  color: whiteColor,
  fontWeight: FontWeight.w400,
  fontFamily: 'Pretendard',
);
var f12w700WhiteSize = () => TextStyle(
  fontSize: 12 - (0.8 * double.parse('${us.userFont.value}')),
  color: Colors.white,
  fontWeight: FontWeight.w700,
  fontFamily: 'Pretendard',
);
var f16w700WhiteSize = () => TextStyle(
  fontSize: 16 - (0.8 * double.parse('${us.userFont.value}')),
  color: Colors.white,
  fontWeight: FontWeight.w700,
  fontFamily: 'Pretendard',
);
var f16w700BlueSize = () => TextStyle(
  fontSize: 16 - (0.8 * double.parse('${us.userFont.value}')),
  color: Color(0xff1955EE),
  fontWeight: FontWeight.w900,
  fontFamily: 'Pretendard',
);

var f16w900Size = () => TextStyle(
  fontSize: 16 - (0.8 * double.parse('${us.userFont.value}')),
  color: Colors.black,
  fontWeight: FontWeight.w900,
  fontFamily: 'Pretendard',
);

var f16w400Size = () => TextStyle(
  fontSize: 16 - (0.8 * double.parse('${us.userFont.value}')),
  color: Colors.black,
  fontWeight: FontWeight.w400,
  fontFamily: 'Pretendard',
);

var f16w800GreySize = () => TextStyle(
  fontSize: 16 - (0.8 * double.parse('${us.userFont.value}')),
  color: Color(0xffaeb1b9),
  fontWeight: FontWeight.w800,
  fontFamily: 'Pretendard',
);

var f13w400BlueSize = () => TextStyle(
  fontSize: 13 - (0.8 * double.parse('${us.userFont.value}')),
  color: Color(0xff1955EE),
  fontWeight: FontWeight.w400,
  fontFamily: 'Pretendard',
);

var f16w400RedSize = () => TextStyle(
  fontSize: 16 - (0.8 * double.parse('${us.userFont.value}')),
  color: Color(0xffE83B3B),
  fontWeight: FontWeight.w400,
  fontFamily: 'Pretendard',
);

var f34w700RedSize = () => TextStyle(
  fontSize: 34 - (0.8 * double.parse('${us.userFont.value}')),
  color: Color(0xffE83B3B),
  fontWeight: FontWeight.w700,
  fontFamily: 'Pretendard',
);

var f14w700CameraBlueSize = () => TextStyle(
  fontSize: 14 - (0.8 * double.parse('${us.userFont.value}')),
  color: Colors.blue,
  fontWeight: FontWeight.w700,
  fontFamily: 'Pretendard',
);



var f14w700BlueSize = () => TextStyle(
  fontSize: 14 - (0.8 * double.parse('${us.userFont.value}')),
  color: Color(0xff1955EE),
  fontWeight: FontWeight.w700,
  fontFamily: 'Pretendard',
);

var f13w400OrangeSize = () => TextStyle(
  fontSize: 13 - (0.8 * double.parse('${us.userFont.value}')),
  color: Color(0xffF08D19),
  fontWeight: FontWeight.w400,
  fontFamily: 'Pretendard',
);

var f18w700WhiteSize = () => TextStyle(
  fontSize: 18 - (0.8 * double.parse('${us.userFont.value}')),
  color: Colors.white,
  fontWeight: FontWeight.w700,
  fontFamily: 'Pretendard',
);

var f12w600Size = () => TextStyle(
  fontSize: 12 - (0.8 * double.parse('${us.userFont.value}')),
  color: Color(0xff393A3A),
  fontWeight: FontWeight.w600,
  fontFamily: 'Pretendard',
);
var f14w600Size = () => TextStyle(
  fontSize: 14 - (0.8 * double.parse('${us.userFont.value}')),
  color: Color(0xff393A3A),
  fontWeight: FontWeight.w600,
  fontFamily: 'Pretendard',
);
var f16w600Size = () => TextStyle(
  fontSize: 14 - (0.8 * double.parse('${us.userFont.value}')),
  color: Color(0xff393A3A),
  fontWeight: FontWeight.w600,
  fontFamily: 'Pretendard',
);
var f16w600GreySize = () => TextStyle(
  fontSize: 14 - (0.8 * double.parse('${us.userFont.value}')),
  color: Color(0xff999FAF),
  fontWeight: FontWeight.w600,
  fontFamily: 'Pretendard',
);
var f21w700Size = () => TextStyle(
  fontSize: 21 - (0.8 * double.parse('${us.userFont.value}')),
  color: blackColor,
  fontWeight: FontWeight.w700,
  fontFamily: 'Pretendard',
);

// var f20w500Size = () => TextStyle(
//   fontSize: 21 - (0.8 * double.parse('${us.userFont.value}')),
//   color: blackColor,
//   fontWeight: FontWeight.w700,
//   fontFamily: 'Pretendard',
// );

var f16w500HintSize = () => TextStyle(
  fontSize: 16 - (0.8 * double.parse('${us.userFont.value}')),
  color: Colors.red,
  fontWeight: FontWeight.w500,
  fontFamily: 'Pretendard',
);

var f28w700RedSize = () => TextStyle(
  fontSize: 28 - (0.8 * double.parse('${us.userFont.value}')),
  color: Color(0xffE83B3B),
  fontWeight: FontWeight.w700,
  fontFamily: 'Pretendard',
);

var f21wRed700Size = () => TextStyle(
  fontSize: 21 - (0.8 * double.parse('${us.userFont.value}')),
  color: Color(0xffE83B3B),
  fontWeight: FontWeight.w800,
  fontFamily: 'Pretendard',
);
final redf14w700= () => TextStyle(
  fontSize: 14 - (0.8 * double.parse('${us.userFont.value}')),
  color: redColor,
  fontWeight: FontWeight.w700,
  fontFamily: 'Pretendard',
);
final redf12w700= () => TextStyle(
  fontSize: 12 - (0.8 * double.parse('${us.userFont.value}')),
  color: redColor,
  fontWeight: FontWeight.w700,
  fontFamily: 'Pretendard',
);
var f16w700BrownSize = () => TextStyle(
  fontSize: 16 - (0.8 * double.parse('${us.userFont.value}')),
  color: Colors.brown,
  fontWeight: FontWeight.w700,
  fontFamily: 'Pretendard',
);
var f28wBlue700Size = () => TextStyle(
  fontSize: 28 - (0.8 * double.parse('${us.userFont.value}')),
  color: Color(0xff1955EE),
  fontWeight: FontWeight.w700,
  fontFamily: 'Pretendard',
);

var f14wSky700Size = () => TextStyle(
  fontSize: 14 - (0.8 * double.parse('${us.userFont.value}')),
  color: Color(0xff87CEFA),
  fontWeight: FontWeight.w500,
  fontFamily: 'Pretendard',
);
final f12w500Blue = () => TextStyle(
  fontSize: 12 - (0.8 * double.parse('${us.userFont.value}')),
  color: Color(0xff1955ee),
  fontWeight: FontWeight.w500,
  fontFamily: 'Pretendard',
);

var f22w700RedSize = () => TextStyle(
  fontSize: 22 - (0.8 * double.parse('${us.userFont.value}')),
  color: Color(0xffE83B3B),
  fontWeight: FontWeight.w700,
  fontFamily: 'Pretendard',
);

const TextStyle f14RedColorw700 = TextStyle(
    fontSize: 14,
    color: Color(0xffE83B3B),
    fontWeight: FontWeight.w700,
    fontFamily: 'Pretendard');

final f18greyW700 = () => TextStyle(
  fontSize: 18,
  color: Colors.grey,
  fontWeight: FontWeight.w700,
  fontFamily: 'Pretendard',
);

var f14blackW600 = () => TextStyle(
  fontSize: 14,
  color: Color(0xff000000),
  fontWeight: FontWeight.w600,
  fontFamily: 'Pretendard',
);

var f30blackW700 = () => TextStyle(
  fontSize: 30,
  color: blackColor,
  fontWeight: FontWeight.w700,
  fontFamily: 'Pretendard',
);