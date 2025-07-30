import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

import '../../../../utils/permission_handler/permission_handler.dart';
import '../../base_config/config.dart';
import '../../components/dialog.dart';
import '../../utils/loading.dart';
import '../bottom_navigator.dart';
import '../../utils/font/font.dart';


class QRViewExample extends StatefulWidget {
  const QRViewExample({Key? key}) : super(key: key);

  @override
  State<QRViewExample> createState() => _QRViewExampleState();
}

class _QRViewExampleState extends State<QRViewExample> {
  TextEditingController _ipcamCon = TextEditingController();
  final config = AppConfig();
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  Barcode? result;
  QRViewController? controller;
  bool _isLoading = true;
  List _dataL = [];
  List _qrList = [];
  String formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());

  @override
  void initState() {
    Future.delayed(Duration.zero, () async {
      // PermissionStatus status = await Permission.camera.status;
      requestCameraPermission(context);
      fetchData();
      setState(() {
        _isLoading = false;
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    _ipcamCon.dispose();
    controller?.dispose();
    super.dispose();
  }

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    } else if (Platform.isIOS) {
      controller!.resumeCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? LoadingScreen()
          : Column(
              children: <Widget>[
                Expanded(
                  flex: 5,
                  child: QRView(
                    overlay: QrScannerOverlayShape(),
                    key: qrKey,
                    onQRViewCreated: _onQRViewCreated,
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Center(
                    child: (result != null)
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                // 'Barcode Type: ${describeEnum(result!.format)}   Data: ${result!.code}',
                                '카메라 UID : ${_qrList[0]['ID']}',
                                style: f14w700Size(),
                              ),
                              const SizedBox(
                                height: 20,
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        result = null;
                                      });
                                    },
                                    behavior: HitTestBehavior.opaque,
                                    child: Center(
                                      child: Container(
                                        width: 84,
                                        height: 42,
                                        decoration: BoxDecoration(color: Color(0xffD3D8DE), borderRadius: BorderRadius.circular(8)),
                                        child: Center(
                                            child: Text(
                                          '재시도',
                                          style: f16w700Size(),
                                        )),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 10,
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      if (_dataL.any((camera) => camera["cameraUid"] == '${_qrList[0]['ID']}')) {
                                        showOnlyConfirmDialog(context, '이미 등록된 기기 입니다.');
                                      } else {
                                        showConfirmTapDialog(context, '카메라를 등록 하시겠습니까?', () async {
                                          showIpCamIdAddDialog(context, () async {
                                            if (_ipcamCon.text.trim().isEmpty) {
                                              showOnlyConfirmDialog(context, '올바른 정보를 입력해주세요');
                                            } else {
                                              final url = '${config.apiUrl}/cameraadd';
                                              final body = ({
                                                'uid': '${_qrList[0]['ID']}',
                                                'id': 'admin',
                                                'pw': '888888',
                                                'email':'${us.userList[0]['email']}',
                                                'createDate': '${formattedDate}',
                                                'ipCamId':'${_ipcamCon.text.trim()}',
                                                'group': '${us.userList[0]['group']}',
                                                'address' : '${us.userList[0]['address']}',
                                                'addressDetail': '${us.userList[0]['addressDetail']}',
                                                'sido' : '${us.userList[0]['sido']}',
                                                'sigungu' : '${us.userList[0]['sigungu']}',
                                                'chongPan': '${us.userList[0]['chongPan']}',
                                                'chongPanDocId': '${us.userList[0]['chongPanDocId']}',
                                                'branch': '${us.userList[0]['branch']}',
                                                'branchDocId' : '${us.userList[0]['branchDocId']}'
                                              });
                                              final response = await http.post(Uri.parse(url),body: body);
                                              showOnlyConfirmTapDialog(context, '카메라가 등록됐습니다', () async {
                                                setState(() {
                                                  _isLoading = true;
                                                });
                                                fetchData();
                                                setState(() {
                                                  _isLoading = false;
                                                });
                                                Get.back();
                                                Get.offAll(() => BottomNavigator());
                                              });
                                            }
                                          }, _ipcamCon);
                                        });
                                      }
                                    },
                                    behavior: HitTestBehavior.opaque,
                                    child: Center(
                                      child: Container(
                                        width: 84,
                                        height: 42,
                                        decoration: BoxDecoration(color: Color(0xff1955EE), borderRadius: BorderRadius.circular(8)),
                                        child: Center(
                                            child: Text(
                                          '등록',
                                          style: f16w700WhiteSize(),
                                        )),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          )
                        : Text(
                            'QR코드를 스캔해 주세요.',
                            style: f14w700Size(),
                          ),
                  ),
                )
              ],
            ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      setState(() {
        result = scanData;
        _qrList.add(json.decode('${result!.code}'));
        // print('rere ${_qrList[0]['ID']}');
      });
    });
  }

  /// 기기 중복 검사를 위한 패치 데이터
  Future<void> fetchData() async {
    final url = '${config.apiUrl}/getcamera?email=${us.userList[0]['email']}';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      _dataL.clear();
      List<dynamic> dataList = json.decode(response.body);
      _dataL = List.from(dataList);
      // print('test?? ${_dataL}');
    } else {
      print('something error');
    }
  }

  Future<bool> requestCameraPermission(BuildContext context) async {
    /// 권한 상태 확인
    PermissionStatus? value = await Permission.camera.request();
    PermissionStatus status = await Permission.camera.status;

    if (status.isPermanentlyDenied) {
      /// 사용자가 권한을 '영구적으로 거부'한 경우
      showOnlyConfirmTapDialog(context, '권한을 설정해주시기 바랍니다', () {
        openAppSettings();
        Get.back();
      });
      return false;
    } else if(status.isDenied){
      /// 사용자가 권한을 '영구적으로 거부'한 경우
      showOnlyConfirmTapDialog(context, '권한을 설정해주시기 바랍니다', () {
        openAppSettings();
        Get.back();
      });
      return false;
    } else if (!status.isGranted) {
      status = (await Permission.camera.request())!;
      return false;
    } else {
      /// 권한이 부여된 경우
      return true;
    }
  }
}
