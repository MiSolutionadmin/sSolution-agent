import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../../base_config/config.dart';
import '../../utils/font/font.dart';
import '../navigation/bottom_navigator_view.dart';
import '../../components/dialog.dart';
import '../../provider/user_state.dart';
import '../../utils/encryption.dart';

class PwChange extends StatefulWidget {
  final String? setting;
  const PwChange({super.key, this.setting});

  @override
  State<PwChange> createState() => _PwChangeState();
}

class _PwChangeState extends State<PwChange> {
  final config = AppConfig();
  final FocusNode _pwFocusNode  = FocusNode();
  final FocusNode _pwCheckFocusNode = FocusNode();
  final TextEditingController _pwCon = TextEditingController();
  final TextEditingController _pwCon2 = TextEditingController();
  bool _obscurePassword = true;
  bool _obscurePassword2 = true;

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
              widget.setting=='true'
                  ? Text('새로운\n비밀번호를\n입력해주세요', style: f28w800Size(),)
                  : Text('첫 로그인 시 비밀번호를\n안전하게 변경해주세요' ,style: f28w800Size(),),
              const SizedBox(height: 56,),
              Text('비밀번호',
                style: f16w700Size(),),

              const SizedBox(height: 8,),
              ///비밀번호 입력칸
              TextFormField(
                controller: _pwCon,
                onFieldSubmitted: (value) {
                  FocusScope.of(context).requestFocus(_pwCheckFocusNode);
                },
                obscuringCharacter: "*",
                focusNode: _pwFocusNode,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(20)
                ],
                obscureText: _obscurePassword,
                onTap: () {
                  FocusScope.of(context).unfocus();
                },
                decoration: InputDecoration(
                  hintText: '9자리 이상,숫자,영문,특수문자 중 3 가지 조합으로 적어주세요',
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
                  suffixIcon: GestureDetector(
                    onTap: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                    child: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: Color(0xff999FAF),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 30,),

              Text('비밀번호 (확인)', style: f16w700Size(),),
              SizedBox(height: 8,),
              /// 비밀번호(확인) 입력칸
              TextFormField(
                controller: _pwCon2,
                onFieldSubmitted: (value) {
                  _pwCheckFocusNode.unfocus();
                },
                focusNode: _pwCheckFocusNode,
                obscuringCharacter: "*",
                inputFormatters: [
                  LengthLimitingTextInputFormatter(20)
                ],
                obscureText: _obscurePassword2,
                onTap: () {
                  FocusScope.of(context).unfocus();
                },
                decoration: InputDecoration(
                  hintText: '9자리 이상,숫자,영문,특수문자 중 3 가지 조합으로 적어주세요',
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
                  suffixIcon: GestureDetector(
                    onTap: () {
                      setState(() {
                        _obscurePassword2 = !_obscurePassword2;
                      });
                    },
                    child: Icon(
                      _obscurePassword2 ? Icons.visibility_off : Icons.visibility,
                      color: Color(0xff999FAF),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: GestureDetector(
          onTap: () async {
            if (_pwCon.text.trim() != _pwCon2.text.trim()) {
              showOnlyConfirmDialog(context, '비밀번호가 일치하지 않습니다');
            } else if(!isValidPassword(_pwCon.text.trim())){
              showOnlyConfirmDialog(context, '올바른 비밀번호를 입력해주세요');
            }
            else if (_pwCon2.text.trim().isNotEmpty) {
              await changePw(_pwCon2.text.trim());
              showOnlyConfirmTapDialogWillpop(context, '비밀번호가 변경되었습니다', () {Get.offAll(() => BottomNavigatorView());});
            } else {
              showOnlyConfirmDialog(context, '입력되지 않은 값이 있습니다');
            }
          },
          child: Container(
            width: double.infinity,
            height: 60,
            decoration: BoxDecoration(
              color: Color(0xff1955EE),
            ),
            child: Center(
              child: Text(widget.setting=='true'?'변경하기':'메인화면으로 이동',
                style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white
                ),),
            ),
          ),
        ),
      ),
    );
  }
  /// 비밀번호 유효성 체크
  bool isValidPassword(String password) {
    if (password.length < 9) return false; // 최소 9자리

    // 각 조건을 만족하는지 확인하기 위한 플래그
    bool hasUpperCase = false;
    bool hasLowerCase = false;
    bool hasDigits = false;
    bool hasSpecialCharacters = false;

    // 특수문자 리스트
    final specialCharacters = RegExp(r'[!@#$%^&*()]+');

    for (int i = 0; i < password.length; i++) {
      if (password[i].contains(RegExp(r'[A-Z]'))) {
        hasUpperCase = true;
      } else if (password[i].contains(RegExp(r'[a-z]'))) {
        hasLowerCase = true;
      } else if (password[i].contains(RegExp(r'[0-9]'))) {
        hasDigits = true;
      } else if (specialCharacters.hasMatch(password[i])) {
        hasSpecialCharacters = true;
      }
    }

    // 3가지 조건을 만족하는지 확인
    int criteriaMet = 0;
    if (hasUpperCase) criteriaMet++;
    if (hasLowerCase) criteriaMet++;
    if (hasDigits) criteriaMet++;
    if (hasSpecialCharacters) criteriaMet++;

    return criteriaMet >= 3; // 3가지 조합 이상 필요
  }
  /// 비밀번호 변경
  Future<void> changePw(String pw) async{
    final us= Get.put(UserState());
    // final url = '${config.apiUrl}/changepw?id=${us.userList[0]['email']}&pw=${pw}';
    // final response = await http.get(Uri.parse(url));

    /// 25-05-19 get방식에서 비밀번호에 #포함시 오류발생 => post로 변경
    final body = {
      'id' : us.userList[0]['email'],
      'pw' : pw,
    };

    final response = await http.post(
        Uri.parse('${config.baseUrl}/changepw'),
        body: body
    );

    us.userList[0]['pw'] = pw;
    await storage.write(key: "pws", value: pw);
    if (response.statusCode != 200) {
      print('에러에러');
      throw Exception('Failed to send email');
    }
  }
}
