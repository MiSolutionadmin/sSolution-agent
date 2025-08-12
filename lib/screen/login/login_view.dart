import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import '../../utils/font/font.dart';
import '../../utils/loading.dart';
import 'find/find_id_screen.dart';
import 'find/find_pw_screen.dart';
import 'login_view_model.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  late final LoginViewModel viewModel;

  @override
  void initState() {
    super.initState();
    viewModel = Get.put(LoginViewModel(), tag: 'login');
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: WillPopScope(
        onWillPop: () => viewModel.handleWillPop(context),
        child: Scaffold(
          backgroundColor: Colors.white,
          body: Obx(() {
            if (viewModel.isLoading.value) {
              return LoadingScreen();
            }
            return _buildLoginBody(viewModel);
          }),
        ),
      ),
    );
  }

  Widget _buildLoginBody(LoginViewModel viewModel) {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Container(
        height: Get.height,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLogo(),
            const SizedBox(height: 60),
            _buildIdInputSection(viewModel),
            const SizedBox(height: 20),
            _buildPasswordInputSection(viewModel),
            const SizedBox(height: 20),
            _buildSaveIdCheckbox(viewModel),
            const SizedBox(height: 30),
            _buildLoginButton(viewModel),
            const SizedBox(height: 20),
            _buildBottomLinks(),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Image.asset(
          'assets/icon/logo.png', 
          width: Get.width * 0.5, 
          fit: BoxFit.contain
        ),
        const SizedBox(height: 10),
        const Text(
          '에이전트',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildIdInputSection(LoginViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('아이디', style: f16w700Size()),
        const SizedBox(height: 10),
        _buildIdInputField(viewModel),
      ],
    );
  }

  Widget _buildPasswordInputSection(LoginViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('비밀번호', style: f16w700Size()),
        const SizedBox(height: 10),
        _buildPasswordInputField(viewModel),
      ],
    );
  }

  Widget _buildIdInputField(LoginViewModel viewModel) {
    return TextFormField(
      controller: viewModel.idController,
      focusNode: viewModel.emailFocusNode,
      onFieldSubmitted: (value) => 
        FocusScope.of(Get.context!).requestFocus(viewModel.passwordFocusNode),
      onChanged: (value) => viewModel.onIdChanged(),
      decoration: InputDecoration(
        hintText: '이메일을 입력해주세요',
        hintStyle: hintf14w400Size(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 16),
        filled: true,
        fillColor: const Color(0xFFF1F4F7),
        enabledBorder: UnderlineInputBorder(
          borderRadius: BorderRadius.circular(4), 
          borderSide: BorderSide.none
        ),
        focusedBorder: UnderlineInputBorder(
          borderRadius: BorderRadius.circular(4), 
          borderSide: BorderSide.none
        ),
      ),
    );
  }

  Widget _buildPasswordInputField(LoginViewModel viewModel) {
    return Obx(() => TextFormField(
      controller: viewModel.passwordController,
      focusNode: viewModel.passwordFocusNode,
      obscureText: viewModel.obscurePassword.value,
      onFieldSubmitted: (value) => 
        FocusScope.of(Get.context!).requestFocus(viewModel.loginButtonFocusNode),
      decoration: InputDecoration(
        hintText: '비밀번호를 입력해주세요',
        hintStyle: hintf14w400Size(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 16),
        filled: true,
        fillColor: const Color(0xFFF1F4F7),
        enabledBorder: UnderlineInputBorder(
          borderRadius: BorderRadius.circular(4), 
          borderSide: BorderSide.none
        ),
        focusedBorder: UnderlineInputBorder(
          borderRadius: BorderRadius.circular(4), 
          borderSide: BorderSide.none
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
    ));
  }

  Widget _buildSaveIdCheckbox(LoginViewModel viewModel) {
    return Obx(() => Row(
      children: [
        GestureDetector(
          onTap: viewModel.toggleSaveId,
          child: SvgPicture.asset(
            viewModel.isChecked.value 
              ? 'assets/icon/check.svg' 
              : 'assets/icon/uncheck.svg',
            width: 21,
            height: 21,
          ),
        ),
        const SizedBox(width: 10),
        Text('아이디 저장', style: f14w700Size()),
      ],
    ));
  }

  Widget _buildLoginButton(LoginViewModel viewModel) {
    return Center(
      child: ElevatedButton(
        focusNode: viewModel.loginButtonFocusNode,
        style: ButtonStyle(
          shape: WidgetStateProperty.all<RoundedRectangleBorder>(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))
          ),
          minimumSize: WidgetStateProperty.all(const Size(double.infinity, 52)),
          backgroundColor: WidgetStateProperty.all(const Color(0xFF1955EE)),
        ),
        onPressed: viewModel.loginAction,
        child: Text('로그인', style: f16w700WhiteSize()),
      ),
    );
  }

  Widget _buildBottomLinks() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () => Get.to(() => FindId()),
          child: Text('아이디 찾기', style: hintf14w400Size()),
        ),
        const SizedBox(width: 42),
        Text('|', style: hintf14w400Size()),
        const SizedBox(width: 42),
        GestureDetector(
          onTap: () => Get.to(() => FindPw()),
          child: Text('비밀번호 찾기', style: hintf14w400Size()),
        ),
      ],
    );
  }
}