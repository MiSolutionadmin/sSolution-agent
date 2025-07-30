// import '../model/device_model.dart';
import 'package:get/get.dart';

class TFSettingsState {
  ///TF录像分辨率, 0 超高清，录像最短；1 高清，录像短；2 标清，录像长
  var tfResolution = 2.obs;

  var recordModel = 0.obs;
}
