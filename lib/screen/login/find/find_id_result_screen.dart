import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

import '../../../utils/font/font.dart';
import '../login_view.dart';


class FindIdResult extends StatefulWidget {
  final String responseBody;

  const FindIdResult({super.key, required this.responseBody});


  @override
  State<FindIdResult> createState() => _FindIdResultState();
}

class _FindIdResultState extends State<FindIdResult> {
  String email = '';

  @override
  void initState() {
    super.initState();
    String emailBody = widget.responseBody;
    List<dynamic> data = jsonDecode(emailBody);
    List<Map<String, dynamic>> dataList = List<Map<String, dynamic>>.from(data);
    email = dataList.isNotEmpty ? dataList[0]["email"] : "";
  }

  @override
  void dispose() {
    super.dispose();
  }

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
              RichText(
                text: TextSpan(
                  text: '등록하신 아이디는\n',
                  style: f28w800Size(),
                  children: [
                    TextSpan(
                      text: '\n$email\n',
                      style: f28w800Size(),
                    ),
                    TextSpan(
                      text: "\n입니다",
                      style: f28w800Size(),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 56,),

            ],
          ),
        ),
        bottomNavigationBar: GestureDetector(
          onTap: () async {
            Get.offAll(()=> LoginView());
          },
          child: Container(
            width: Get.width,
            height: 60,
            color: const Color(0xff1955EE),
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(child: Text('로그인 페이지로',style: f18w700WhiteSize(),)),
          ),
        ),
      ),
    );
  }
}
