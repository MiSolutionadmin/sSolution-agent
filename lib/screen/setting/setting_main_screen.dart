import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:mms/screen/login/login_service.dart';
import 'package:mms/screen/setting/term/term_page.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../components/dialog.dart';
import '../../db/user_table.dart';
import '../../provider/user_state.dart';
import '../login/login_view.dart';
import '../../../utils/font/font.dart';
import 'admin/admin_setting_screen.dart';
import 'notification/setting_notification_screen.dart';
import 'private/private_change_screen.dart';

class SettingMain extends StatefulWidget {
  const SettingMain({Key? key}) : super(key: key);

  @override
  State<SettingMain> createState() => _SettingMainState();
}

class _SettingMainState extends State<SettingMain> {
  /// ✅ GetX
  final us = Get.put(UserState());
  
  /// ✅ 패키지 정보 관련
  PackageInfo? packageInfo;
  
  /// ✅ 전체로딩 관련
  bool _isLoading = true;
  
  /// ✅ 로컬스토리지 관련
  static final storage = new FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  /// ✅ 카메라 메모리카드 timeLine 관련 (왜 여기에 있는지 이유불명)
  String currentTime = '';

  /// ✅ 로그아웃 관련
  int firstClick = 0; // 로그아웃 첫클릭..?

  /// ✅ 안쓰는것
  // late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    fetchInit();
  }

  /// ✅ 세팅화면 init 함수
  void fetchInit () async {
    await checkDuplicateLogin(context);/// ✅ 중복로그인 체크

    packageInfo = await PackageInfo.fromPlatform();
    _isLoading = false;
    setState(() {});
  }
  
  /// ✅ 로그아웃 버튼 눌렀을때
  // void pressedLogOut() {
  //   showConfirmTapDialog(context, '로그아웃 하시겠습니까?', () async{
  //     firstClick++;
  //     if(firstClick==1){
  //       /// usertable에서 토큰 제거
  //       await tokenDelete();
  //       await storage.delete(key: 'pws');
  //       us.userList.clear();
  //       Get.offAll(()=>LoginView());
  //     }
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          /// ✅ 로그아웃 버튼
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: GestureDetector(
              onTap: () async {
                final loginService = LoginService();
                final savedToken = await loginService.getToken();
                print("저장된 토큰: ${savedToken}");
                
                // 실제 로그아웃 처리
                showConfirmTapDialog(context, '로그아웃 하시겠습니까?', () async {
                  await loginService.logout();
                  await loginService.clearSavedLoginInfo();
                  us.userList.clear();
                  Get.offAll(() => const LoginView());
                });
              },
              child: Text(
                '로그아웃',
                style: f16w700Blue(),
              ),
            ),
          )
        ],
      ),
      backgroundColor: Colors.white,
      body: _isLoading
          ? Container() /// ✅ 빈화면 로딩
          : Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// ✅ 개인정보 변경
            changeUserDataWidget(),
            const SizedBox(
              height: 20,
            ),
            /// ✅ 알림 설정
            alimSettingWidget(),
            const SizedBox(
              height: 20,
            ),
            /// ✅ 관리자 설정
            adminSettingWidget(),
            const SizedBox(
              height: 20,
            ),
            /// ✅ 글자 크기 설정
            settingFontSizeWidget(),

            const SizedBox(
              height: 20,
            ),
            /// ✅ 버전 정보
            versionInfoWidget(),
            Spacer(),
            /// 이용약관
            GestureDetector(
              onTap: () async {
                Get.to(TermPage());
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12,horizontal: 16),
                color: Colors.transparent,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                        "이용약관",
                        style: hintf14w700
                    )
                  ],
                ),
              ),
            ),
            /// ✅ 회사정보 Footer
            Text('(주) 에스솔루션',style: hintf14w700,),
            Text('대표자 김창국 | 사업자등록번호 774-87-00271',style: hintf10w400,),
            Text('충청남도 천안시 동남구 청수14로 102, 609호(청당동, 에이스법조타운)',style: hintf10w400,),
            Text('대표번호 041-622-6625 | 이메일 ssolution0622@gmail.com',style: hintf10w400,),
            const SizedBox(height: 10,)
          ],
        ),
      ),
    );
  }
  
  /// ✅ 개인정보 변경
  Widget changeUserDataWidget() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        Get.to(() => PrivateChange());
      },
      child: Row(
        children: [
          Text(
            '개인정보 변경',
            style: f18w700Size(),
          ),
          const Spacer(),
          SvgPicture.asset(
            'assets/icon/rightArrow.svg',
          ),
        ],
      ),
    );
  }
  
  /// ✅ 알림 설정
  Widget alimSettingWidget() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        Get.to(() => SettingNotificationScreen());
      },
      child: Row(
        children: [
          Text(
            '알림 설정',
            style: f18w700Size(),
          ),
          Spacer(),
          SvgPicture.asset(
            'assets/icon/rightArrow.svg',
          ),
        ],
      ),
    );
  }

  /// ✅ 관리자 설정
  Widget adminSettingWidget() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if(us.userList[0]['head']== 'true' && !us.userList[0]['email'].contains('test')){
          Get.to(()=>AdminSetting());
        }
      },
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '관리자 설정',
                style: f18w700Size(),
              ),
              Text(
                '(주관리자만 사용할 수 있습니다)',
                style: f13w500Grey(),
              ),
            ],
          ),
          Spacer(),
          SvgPicture.asset(
            'assets/icon/rightArrow.svg',
          ),
        ],
      ),
    );
  }

  /// ✅ 글자 크기
  Widget settingFontSizeWidget() {
    return Row(
      children: [
        Text(
          '글자 크기',
          style: f18w700Size(),
        ),
        Spacer(),
        SizedBox(
          width: 130,
          height: 40,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                  onTap: () async {
                    await storage.write(key: "fontSizes", value: '2');
                    us.userFont.value = 2;
                    setState(() {});
                  },
                  child: Text(
                    '소',
                    style: us.userFont.value == 2 ? f22w700 : f18w700BlurGrey,
                  )),
              GestureDetector(
                  onTap: () async {
                    await storage.write(key: "fontSizes", value: '1');
                    us.userFont.value = 1;
                    setState(() {});
                  },
                  child: Text(
                    '중',
                    style: us.userFont.value == 1 ? f24w700 : f24w700BlurGrey,
                  )),
              GestureDetector(
                  onTap: () async {
                    await storage.write(key: "fontSizes", value: '0');
                    us.userFont.value = 0;
                    setState(() {});
                  },
                  child: Text(
                    '대',
                    style: us.userFont.value == 0 ? f28w700 : f28w700BlurGrey,
                  )),
            ],
          ),
        )
      ],
    );
  }

  /// ✅ 버전 정보
  Widget versionInfoWidget() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {},
      child: GestureDetector(
        onTap: () async{
          String? token = await FirebaseMessaging.instance.getToken();

          print("✅ check token ?? : $token");
        },
        child: Row(
          children: [
            Text(
              '버전 정보',
              style: f18w700Size(),
            ),
            Spacer(),
            Text('v ${packageInfo?.version}',style: f18w700Size(),)
          ],
        ),
      ),
    );
  }
}
