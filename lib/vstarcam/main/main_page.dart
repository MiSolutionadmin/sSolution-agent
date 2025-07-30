import 'package:flutter/material.dart';
import 'package:vsdk/camera_device/camera_device.dart';
import 'package:get/get.dart';
import '../../routes/app_routes.dart';
import '../../utils/device_manager.dart';
import 'main_logic.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class MainPage extends GetView<MainLogic> {
  @override
  Widget build(BuildContext context) {
    final contro = controller;
    final state = controller.state;
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('veepai demo')),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 50),
            Center(
              child: ElevatedButton(
                onPressed: () async {
                  print("state?.connectState ${state?.connectState}");
                  // Get.toNamed(AppRoutes.play);
                  if (state?.connectState == CameraConnectState.connected) {
                    print('연결 됐습니다--------');
                    Get.toNamed(AppRoutes.play);
                  } else if (state?.connectState == CameraConnectState.password) {
                    // EasyLoading.showToast("密码错误，请使用正确的密码");
                    EasyLoading.showToast("비밀번호 틀렸을때 나오는 코드");
                  } else if (state?.connectState == CameraConnectState.none || state?.connectState == CameraConnectState.timeout) {
                    ///初始化失败
                   print('타임아웃입니다--------');
                   print('connect state: ${state?.connectState}');
                    // Get.tryFind<MainLogic>(tag: '').init();
                  } else if (state?.connectState == CameraConnectState.offline) {
                    ///初始化失败
                    EasyLoading.showToast("设备已离线，请唤醒设备重试");
                    print('오프라인 상태--------');
                  } else if (state?.connectState == CameraConnectState.disconnect) {
                    ///重新连接
                    EasyLoading.showToast("设备连接断开，正在重新连接，请稍等");
                    bool bl = await controller.connectDevice(DeviceManager.getInstance().mDevice!);
                    if (bl) {
                      Get.toNamed(AppRoutes.play);
                    } else {
                      EasyLoading.showToast("连接失败，请重试！");
                    }
                    print('연결 끊김--------');

                  }
                },
                child: Text("들어가기"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
