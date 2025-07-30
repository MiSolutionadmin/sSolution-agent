import 'package:get/get.dart';
import 'package:vsdk/camera_device/camera_device.dart';

class MainState {
  late CameraDevice mDevice;
  late int clientPtr;
  CameraConnectState connectState = CameraConnectState.none;
}
