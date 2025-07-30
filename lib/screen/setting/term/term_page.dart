// TermPage.dart 변경된 버전 (flutter_html 사용)
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:get/get.dart';
import 'package:mms/utils/loading.dart';
import '../../../provider/term_state.dart';
import '../../../utils/font/font.dart';

class TermPage extends StatefulWidget {
  const TermPage({Key? key}) : super(key: key);

  @override
  State<TermPage> createState() => _TermPageState();
}

class _TermPageState extends State<TermPage> {
  TermState ts = Get.find<TermState>();
  bool isPrivateSelect = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () async {
      await ts.getTermList(isPrivateSelect ? "private" : "policy");
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('MMS 서비스 이용약관', style: f16w900Size()),
        centerTitle: true,
        shape: const Border(
          bottom: BorderSide(color: Color(0xffEFF0F0), width: 1),
        ),
      ),
      backgroundColor: const Color(0xffffffff),
      body: Builder(
        builder: (BuildContext innerContext) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          await ts.getTermList("private");
                          setState(() {
                            isPrivateSelect = true;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isPrivateSelect ? Colors.lightBlue : Colors.grey,
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              "개인정보처리방침",
                              style: TextStyle(
                                color: isPrivateSelect ? Colors.lightBlue : Colors.grey,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          await ts.getTermList("policy");
                          setState(() {
                            isPrivateSelect = false;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: !isPrivateSelect ? Colors.lightBlue : Colors.grey,
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              "이용약관안내",
                              style: TextStyle(
                                color: !isPrivateSelect ? Colors.lightBlue : Colors.grey,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: innerContext,
                    barrierColor: Colors.black.withOpacity(0.5),
                    builder: (BuildContext context) {
                      return Container(
                        height: 300,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.white,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    "MMS 서비스 이용약관 선택",
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  const Spacer(),
                                  GestureDetector(
                                    onTap: () => Navigator.pop(context),
                                    child: SvgPicture.asset('assets/icon/close.svg'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Expanded(
                                child: ListView.builder(
                                  itemCount: ts.termDateList.length,
                                  itemBuilder: (context, index) {
                                    final formatted = ts.formatTermDate(ts.termDateList[index], index);
                                    return GestureDetector(
                                      onTap: () {
                                        ts.termSelect.value = formatted;
                                        ts.getTermHtmlByDate(ts.termDateList[index], isPrivateSelect ? "private" : "policy");
                                        Navigator.pop(context);
                                        setState(() {});
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                        margin: const EdgeInsets.symmetric(vertical: 4),
                                        decoration: BoxDecoration(
                                          color: ts.termSelect.value == formatted ? Colors.blue.withOpacity(0.2) : Colors.white,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          formatted,
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: ts.termSelect.value == formatted ? Colors.blue : Colors.black,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        ts.termSelect.value,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey),
                      ),
                      const SizedBox(width: 4),
                      SvgPicture.asset('assets/icon/downArrow.svg'),
                    ],
                  ),
                ),
              ),
              Obx(() =>
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: ts.privateContext.value == ""
                          ?
                      LoadingScreen()
                          :
                      Html(
                          data: ts.privateContext.value,
                      ),
                    ),
                  )
              ),
            ],
          );
        },
      ),
    );
  }
}
