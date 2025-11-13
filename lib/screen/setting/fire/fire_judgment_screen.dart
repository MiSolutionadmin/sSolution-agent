import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../utils/font/font.dart';

class FireJudgmentScreen extends StatelessWidget {
  const FireJudgmentScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '화재 판단',
          style: f16w900Size(),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        shape: Border(
          bottom: BorderSide(
            color: const Color(0xffEFF0F0),
            width: 1,
          ),
        ),
      ),
      backgroundColor: const Color(0xffF1F4F7),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Container(
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 화재 판단 섹션
                _buildFireSection(),
                
                // 구분선
                Divider(
                  height: 1,
                  thickness: 1,
                  color: const Color(0xffEFF0F0),
                ),
                
                // 비화재 판단 섹션
                _buildNonFireSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFireSection() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '화재 판단 기준',
            style: f18w700Size(),
          ),
          const SizedBox(height: 12),
          Text(
            '- 실제 불꽃과 연기로 인해 알림이 울린 경우',
            style: f16w400Size(),
          ),
          const SizedBox(height: 16),
          _buildFireItem('① 아크 용접 또는 절단에 의한 불꽃'),
          const SizedBox(height: 8),
          _buildFireItem('② 화로에 불을 피운 불꽃'),
          const SizedBox(height: 8),
          _buildFireItem('③ 담배 연기에 의한 연기'),
        ],
      ),
    );
  }

  Widget _buildNonFireSection() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '비화재 판단',
            style: f18w700Size(),
          ),
          const SizedBox(height: 12),
          Text(
            '- 실제 불꽃과 연기가 아닌 경우의 알림',
            style: f16w400Size(),
          ),
          const SizedBox(height: 16),
          _buildNonFireItem('① 차량 라이트 등 불빛에 의한 경우'),
          const SizedBox(height: 8),
          _buildNonFireItem('② 반사되는 태양광에 의한 경우'),
        ],
      ),
    );
  }

  Widget _buildFireItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Text(
        text,
        style: f14w500Size(),
      ),
    );
  }

  Widget _buildNonFireItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Text(
        text,
        style: f14w500Size(),
      ),
    );
  }
}