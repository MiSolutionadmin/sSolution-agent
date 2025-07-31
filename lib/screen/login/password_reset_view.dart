import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../utils/font/font.dart';
import 'password_reset_view_model.dart';

class PasswordResetView extends StatelessWidget {
  final String? setting;
  
  const PasswordResetView({super.key, this.setting});

  @override
  Widget build(BuildContext context) {
    final PasswordResetViewModel viewModel = Get.put(PasswordResetViewModel(), tag: 'password_reset');
    
    // 페이지 타입 설정
    viewModel.setPageType(setting == 'true' ? 'setting' : 'initial');
    
    return GestureDetector(
      onTap: viewModel.unfocusAll,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: _buildAppBar(viewModel),
        body: _buildBody(viewModel),
        bottomNavigationBar: _buildSubmitButton(context, viewModel),
      ),
    );
  }

  /// 앱바 생성
  PreferredSizeWidget _buildAppBar(PasswordResetViewModel viewModel) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
        onPressed: viewModel.handleBackPress,
      ),
    );
  }

  /// 메인 화면 생성
  Widget _buildBody(PasswordResetViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitle(viewModel),
          const SizedBox(height: 56),
          _buildPasswordField(viewModel),
          const SizedBox(height: 30),
          _buildConfirmPasswordField(viewModel),
        ],
      ),
    );
  }

  /// 제목 생성
  Widget _buildTitle(PasswordResetViewModel viewModel) {
    return Obx(() => Text(
      viewModel.pageType.value == 'setting'
          ? '새로운\n비밀번호를\n입력해주세요'
          : '첫 로그인 시 비밀번호를\n안전하게 변경해주세요',
      style: f28w800Size(),
    ));
  }

  /// 비밀번호 입력 필드
  Widget _buildPasswordField(PasswordResetViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('비밀번호', style: f16w700Size()),
        const SizedBox(height: 8),
        Obx(() => TextFormField(
          controller: viewModel.passwordController,
          focusNode: viewModel.passwordFocusNode,
          onFieldSubmitted: (value) => viewModel.moveToConfirmPasswordField(),
          obscuringCharacter: "*",
          obscureText: viewModel.obscurePassword.value,
          inputFormatters: [LengthLimitingTextInputFormatter(20)],
          onTap: viewModel.unfocusAll,
          decoration: InputDecoration(
            hintText: '9자리 이상,숫자,영문,특수문자 중 3 가지 조합으로 적어주세요',
            hintStyle: const TextStyle(
              fontSize: 12,
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w400,
              color: Color(0xffB5B5B5),
            ),
            contentPadding: const EdgeInsets.fromLTRB(15, 18, 0, 18),
            filled: true,
            fillColor: const Color(0xFFF5F6F7),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide.none,
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide.none,
            ),
            errorBorder: const UnderlineInputBorder(
              borderSide: BorderSide.none,
            ),
            focusedErrorBorder: const UnderlineInputBorder(
              borderSide: BorderSide.none,
            ),
            suffixIcon: GestureDetector(
              onTap: viewModel.togglePasswordVisibility,
              child: Icon(
                viewModel.obscurePassword.value 
                  ? Icons.visibility_off 
                  : Icons.visibility,
                color: const Color(0xff999FAF),
              ),
            ),
          ),
        )),
        Obx(() => viewModel.passwordError.value.isNotEmpty
          ? Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                viewModel.passwordError.value,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.red,
                  fontFamily: 'Pretendard',
                ),
              ),
            )
          : const SizedBox.shrink()
        ),
      ],
    );
  }

  /// 비밀번호 확인 입력 필드
  Widget _buildConfirmPasswordField(PasswordResetViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('비밀번호 (확인)', style: f16w700Size()),
        const SizedBox(height: 8),
        Obx(() => TextFormField(
          controller: viewModel.confirmPasswordController,
          focusNode: viewModel.confirmPasswordFocusNode,
          onFieldSubmitted: (value) => viewModel.unfocusAll(),
          obscuringCharacter: "*",
          obscureText: viewModel.obscureConfirmPassword.value,
          inputFormatters: [LengthLimitingTextInputFormatter(20)],
          onTap: viewModel.unfocusAll,
          decoration: InputDecoration(
            hintText: '9자리 이상,숫자,영문,특수문자 중 3 가지 조합으로 적어주세요',
            hintStyle: const TextStyle(
              fontSize: 12,
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w400,
              color: Color(0xffB5B5B5),
            ),
            contentPadding: const EdgeInsets.fromLTRB(15, 18, 0, 18),
            filled: true,
            fillColor: const Color(0xFFF5F6F7),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide.none,
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide.none,
            ),
            errorBorder: const UnderlineInputBorder(
              borderSide: BorderSide.none,
            ),
            focusedErrorBorder: const UnderlineInputBorder(
              borderSide: BorderSide.none,
            ),
            suffixIcon: GestureDetector(
              onTap: viewModel.toggleConfirmPasswordVisibility,
              child: Icon(
                viewModel.obscureConfirmPassword.value 
                  ? Icons.visibility_off 
                  : Icons.visibility,
                color: const Color(0xff999FAF),
              ),
            ),
          ),
        )),
        Obx(() => viewModel.confirmPasswordError.value.isNotEmpty
          ? Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                viewModel.confirmPasswordError.value,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.red,
                  fontFamily: 'Pretendard',
                ),
              ),
            )
          : const SizedBox.shrink()
        ),
      ],
    );
  }

  /// 제출 버튼
  Widget _buildSubmitButton(BuildContext context, PasswordResetViewModel viewModel) {
    return Obx(() => GestureDetector(
      onTap: viewModel.isLoading.value 
        ? null 
        : () => viewModel.changePassword(context),
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          color: viewModel.isLoading.value || !viewModel.isFormValid.value
            ? Colors.grey.shade400
            : const Color(0xff1955EE),
        ),
        child: Center(
          child: viewModel.isLoading.value
            ? const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 2.0,
              )
            : Text(
                viewModel.pageType.value == 'setting' ? '변경하기' : '메인화면으로 이동',
                style: const TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
        ),
      ),
    ));
  }
}