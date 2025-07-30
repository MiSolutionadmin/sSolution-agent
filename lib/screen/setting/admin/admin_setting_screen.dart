import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../base_config/config.dart';
import '../../../components/dialog.dart';
import '../../../provider/user_state.dart';
import '../../../utils/color.dart';
import '../../../utils/font/font.dart';
import '../../../utils/loading.dart';
import 'admin_add_screen.dart';
import 'package:http/http.dart' as http;

class AdminSetting extends StatefulWidget {
  const AdminSetting({Key? key}) : super(key: key);

  @override
  State<AdminSetting> createState() => _AdminSettingState();
}

class _AdminSettingState extends State<AdminSetting> {
  final config = AppConfig();
  List<bool> _clickL = [];
  bool updateH = false; /// head권한 넘겨주기
  bool isLoading = true;
  @override
  void initState() {
    Future.delayed(Duration.zero,()async{
      await getUserInfo(); /// 정보 가져오기
      _clickL = List.generate(us.userSettingData.length, (index) => false);
      isLoading = false;
      setState(() {});
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(
            '관리자 설정',
            style: f16w900Size(),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          actions: [
            us.userList[0]['head']=='true'?GestureDetector(
              onTap: (){
                Get.to(() => AdminAddScreen())?.then((value)async{
                  await getUserInfo(); /// 정보 가져오기
                  _clickL = List.generate(us.userSettingData.length, (index) => false);
                  setState(() {});
                });
              },
              child: Padding(
                padding: const EdgeInsets.only(right: 20),
                child: Text(
                  '추가',
                  style: f14w700BlueSize(),
                ),
              ),
            ):Container()
          ],
        ),
        backgroundColor: const Color(0xffF1F4F7),
        body: isLoading?LoadingScreen():ListView.builder(
            shrinkWrap: true,
            physics: const ClampingScrollPhysics(),
            itemCount: us.userSettingData.length,
            itemBuilder: (_, index) {
              return GestureDetector(
                onTap: (){
                  if(us.userList[0]['head']=='true'){
                    if(index != 0){
                      _clickL[index] =! _clickL[index];
                    }
                    setState(() {});
                  }
                  else{
                    print('주관리자만 가능');
                  }
                },
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _clickL[index] ? const Color(0xffE83B3B) : Colors.transparent
                    )
                  ),
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '${us.userSettingData[index]['name']}',
                                style: f18w700Size(),
                              ),
                              const SizedBox(
                                width: 8,
                              ),
                              index == 0 ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), border: Border.all(color: const Color(0xff1955EE))),
                                child: Text(
                                  '주관리자',
                                  style: f13w400BlueSize(),
                                ),
                              ) : GestureDetector(
                                onTap: (){
                                  // ///주관리자 일때만
                                  // if(us.userList[0]['head']=='true'){
                                  //   showConfirmTapDialog(context, '관리자를 넘겨주시겠습니까?', () async{
                                  //     await updateHead(us.userSettingData[index]['email']).then((value){
                                  //       Get.back();
                                  //       if(updateH){
                                  //         showOnlyConfirmTapDialog(context, '업데이트 완료했습니다', () async{
                                  //           await getUserInfo(); /// 정보 가져오기
                                  //           us.userList[0]['head'] = false; /// 넘겨주고 주관리자 -> 일반으로 바꾸가
                                  //           Get.back();
                                  //           setState(() {});
                                  //         });
                                  //       }
                                  //       else{
                                  //         showOnlyConfirmDialog(context, '권한을 넘기지 못했습니다');
                                  //       }
                                  //     });
                                  //   });
                                  // }
                                  // else{
                                  //   print('주관리자만 권한 넘기기 가능');
                                  // }
                                  },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), border: Border.all(color: const Color(0xffF08D19))),
                                  child: Text(
                                    '일반',
                                    style: f13w400OrangeSize(),
                                  ),
                                ),
                              ) ,
                            ],
                          ),
                          const SizedBox(height: 4,),
                          Text('${us.userSettingData[index]['phoneNumber']}',style: f18w400Size(),),
                          const SizedBox(height: 4,),
                          // Text('가입일 : ${DateFormat('y년 MM월 dd일').format(DateTime.parse('${us.userSettingData[index]['createdate']}'))}',style: f13w500Grey(),)
                          Text('이메일 : ${us.userSettingData[index]['email']}',style: f13w500Grey(),)
                        ],
                      ),
                      Spacer(),
                      index==0||us.userList[0]['head']!='true'?Container():GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: (){
                          if(us.userList[0]['head']=='true'){
                            showConfirmTapDialog(context, '관리자를 넘겨주시겠습니까?', () async{
                              await updateHead(
                                  us.userSettingData[index]['email'],
                                  us.userSettingData[index]['docId'],
                                  us.userSettingData[index]['mms'],

                              ).then((value){
                                Get.back();
                                if(updateH){
                                  showOnlyConfirmTapDialog(context, '업데이트 완료했습니다', () async{
                                    us.userList[0]['headDocId'] = us.userSettingData[index]['docId'];
                                    await getUserInfo(); /// 정보 가져오기
                                    us.userList[0]['head'] = false; /// 넘겨주고 주관리자 -> 일반으로 바꾸가
                                    Get.back();
                                    setState(() {});
                                  });
                                }
                                else{
                                  showOnlyConfirmDialog(context, '권한을 넘기지 못했습니다');
                                }
                              });
                            });
                          }
                          else{
                            print('주관리자만 권한 넘기기 가능');
                          }
                        },
                        child: Container(
                          width: 50,
                          height: 100,
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: blueColor
                              )
                          ),
                          child: Center(child: Text('변경')),),
                      )
                    ],
                  ),
                ),
              );
            }),
      bottomNavigationBar: GestureDetector(
        onTap: ()async{
          if( _clickL.every((element) => element== false)){
            showOnlyConfirmDialog(context, '관리자를 선택해주세요');
          }else{
            showConfirmTapDialog(context, '삭제하시겠습니까?', () async{
              if(us.userList[0]['head']=='true'){
                /// 선택된 거 찾아서 true인 거 인덱스 뽑아내기
                List<int> trueIndices = List.generate(_clickL.length, (index) => index)
                    .where((index) => _clickL[index])
                    .toList();
                /// 반복해서 지우기
                for(int i=0;i<trueIndices.length;i++){
                  await deleteUser('${us.userSettingData[trueIndices[i]]['email']}');
                }
                /// 지운거 리스트에서 인덱스 지우기
                for(int i = trueIndices.length -1; i>=0;i--){
                  us.userSettingData.removeAt(trueIndices[i]);
                }
                _clickL = List.generate(us.userSettingData.length, (index) => false);
                setState(() {});
                Get.back();
                showOnlyConfirmDialog(context, '삭제되었습니다.');
              }
              else{
                print('주관리자만 삭제 가능');
              }
            });
          }
        },
        child: Container(
          width: Get.width,
          height: 60,
          color: !_clickL.contains(true) ? const Color(0xffD3D8DE) : const Color(0xffE83B3B),
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Center(child: Text('삭제',style: f18w700WhiteSize(),)),
        ),
      ),
    );
  }

  /// 같은 mms 정보 가져오기
  Future<void> getUserInfo() async{
    final us= Get.put(UserState());
    final url = '${config.baseUrl}/selectSetting?id=${us.userList[0]['headDocId']}';
    final response = await http.get(Uri.parse(url));
    List<dynamic> dataList = json.decode(response.body);
    us.userSettingData.value = dataList;
    List a = [];
    for (int i = 0; i < us.userSettingData.length; i++) {
      if(!us.userSettingData[i]['email'].contains('test.com')){
        if (us.userSettingData[i]['head'] == 'true') {
          /// "head"가 "ok"인 항목을 찾으면 맨 앞으로 이동
          Map<String, dynamic> list = us.userSettingData.removeAt(i);
          us.userSettingData.insert(0, list);
          break; // 찾으면 반복문 중단
        }
      }
    }
    var filteredData = us.userSettingData.where((user) => !user['email'].contains('test.com')).toList();
    us.userSettingData.value = filteredData;

    if (response.statusCode != 200) {
      print('에러에러');
      throw Exception('Failed to send email');
    }
  }

  /// 선택된 관리자 삭제시키는 버튼
  Future<void> deleteUser(String email) async{
    final url = '${config.baseUrl}/deleteSetting?id=${email}';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      print('에러에러');
      throw Exception('Failed to send email');
    }
  }
  /// 주관리자가 일반에게 권한 넘겨주기
  Future<void> updateHead(String email, String docId, String mms) async{
    final url = '${config.baseUrl}/headUpdate?email=${email}&myEmail=${us.userList[0]['email']}&docId=${docId}&mms=${mms}&headDocId=${us.userList[0]['headDocId']}';
    final response = await http.get(Uri.parse(url));
    Map<String, dynamic> parsedJson = jsonDecode(response.body);
    updateH = parsedJson['success'] == 'true';

    if (response.statusCode != 200) {
      print('에러에러');
      throw Exception('Failed to send email');
    }
  }

}
