import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../components/color_radio.dart';
import '../../../components/switch.dart';
import '../../../components/switch_container.dart';
import '../../../utils/font/font.dart';

class FireSetting2Screen extends StatefulWidget {
  const FireSetting2Screen({Key? key}) : super(key: key);

  @override
  State<FireSetting2Screen> createState() => _FireSettingScreenState();
}

class _FireSettingScreenState extends State<FireSetting2Screen> {
  List item = ['알림발송','주경종','지구경종','사이렌','부저'];
  List field = ['alim','mainjong','subjong','siren','buzzer'];
  List alimCheck = [];

  // late Socket socket;
  bool _isLoading = true;

  @override
  void initState() {
    alimCheck = List.generate(5, (index) => false);
    super.initState();
  }
  @override
  void dispose() {
    // socket.close();
    // socket.destroy();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(
            '소방수신기 상태',
            style: f16w800Size(),
          ),
          titleSpacing: -15,
          centerTitle: true,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right:12),
              child: Row(
                children: [
                  RedRadio(),
                  const SizedBox(width: 6,),
                  Text('불량',style: redf18w700(),),
                ],
              ),
            )
          ],
          shape: Border(
            bottom: BorderSide(
              color: Color(0xffEFF0F0),
              width: 1,
            ),
          ),
        ),
        body:  Container(
          height: Get.height,
          color: Color(0xffF1F4F7),
          child: ListView.builder(
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              itemCount: item.length,
              itemBuilder: (_, index) {
                return Padding(
                  padding: const EdgeInsets.only(left: 20,right: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      index ==0?SizedBox(height: 10,):SizedBox(),
                      SwitchContainer(
                          onTap: ()async{
                            alimCheck[index] = !alimCheck[index];
                            setState(() {});
                          },
                          value: alimCheck[index],
                          name: '${item[index]}',
                          value2:''),
                      // Row(
                      //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      //   children: [
                      //     Text('${item[index]}',style: f24w700Size(),),
                      //     dataList[0][field[index]] =='0'
                      //         ?Text('미등록',style: f24w700Size(),)
                      //         :SwitchButton(onTap: ()async{
                      //           alimCheck[index] = bool.parse(dataList[0][field[index]]);
                      //           alimCheck[index] = !alimCheck[index];
                      //           print('필드 :: ${field[index]} 값 ${alimCheck[index]}');
                      //          await updateButton(field[index], alimCheck[index]);
                      //     }, value: bool.parse(dataList[0][field[index]]))
                      //   ],
                      // ),
                      const SizedBox(height: 10,)
                    ],
                  ),
                );
              }),
        )
    );
  }
  // Future<void> updateButton(String field,bool value) async {
  //   socket.writeln('updateFire test1 ${field} ${value} ');
  // }
}
