import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../utils/font/font.dart';
import 'phone_verification_view_model.dart';

class PhoneVerificationView extends StatelessWidget {
  const PhoneVerificationView({super.key});

  @override
  Widget build(BuildContext context) {
    final PhoneVerificationViewModel viewModel = Get.put(PhoneVerificationViewModel(), tag: 'phone_verification');
    
    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) {
        if (!didPop) {
          viewModel.handleBackPress();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: _buildAppBar(viewModel),
        body: Obx(() => viewModel.isLoading.value 
          ? _buildLoadingBody() 
          : _buildMainBody(viewModel)
        ),
        bottomNavigationBar: _buildVerificationButton(context, viewModel),
      ),
    );
  }

  /// 앱바 생성
  PreferredSizeWidget _buildAppBar(PhoneVerificationViewModel viewModel) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
        onPressed: viewModel.handleBackPress,
      ),
      title: Text(
        '휴대폰 인증',
        style: f18w700Size(),
      ),
      centerTitle: true,
    );
  }

  /// 로딩 화면
  Widget _buildLoadingBody() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1955EE)),
      ),
    );
  }

  /// 메인 화면
  Widget _buildMainBody(PhoneVerificationViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          _buildUserInfoCard(viewModel),
          const SizedBox(height: 27),
          _buildInstructionText(),
        ],
      ),
    );
  }

  /// 사용자 정보 카드
  Widget _buildUserInfoCard(PhoneVerificationViewModel viewModel) {
    return Obx(() {
      final userInfo = viewModel.currentUserInfo;
      if (userInfo == null) {
        return _buildErrorCard('사용자 정보를 불러올 수 없습니다.');
      }

      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: const Color(0xff292E35),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
          child: Column(
            children: [
              _buildInfoRow('이름', userInfo.name),
              const SizedBox(height: 14),
              _buildInfoRow('전화번호', userInfo.formattedPhoneNumber),
            ],
          ),
        ),
      );
    });
  }

  /// 정보 행 생성
  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: f16w400WhiteSize()),
        Flexible(
          child: Text(
            value,
            style: f16w400WhiteSize(),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  /// 에러 카드
  Widget _buildErrorCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.red.shade100,
        border: Border.all(color: Colors.red.shade300),
      ),
      child: Text(
        message,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.red.shade700,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  /// 안내 텍스트
  Widget _buildInstructionText() {
    return Padding(
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
    );
  }

  /// 인증 버튼
  Widget _buildVerificationButton(BuildContext context, PhoneVerificationViewModel viewModel) {
    return Obx(() => GestureDetector(
      onTap: viewModel.isVerifying.value || !viewModel.canVerify
        ? null
        : () => viewModel.startPhoneVerification(context),
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          color: viewModel.isVerifying.value || !viewModel.canVerify
            ? Colors.grey.shade400
            : const Color(0xff1955EE),
        ),
        child: Center(
          child: viewModel.isVerifying.value
            ? const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 2.0,
              )
            : Text(
                '인증하기',
                style: f20Whitew700Size(),
              ),
        ),
      ),
    ));
  }
}