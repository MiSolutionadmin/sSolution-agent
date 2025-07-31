import '../model/device_model.dart';
import 'package:get/get.dart';

class SettingsNormalState {
  ///功耗模式
  var lowMode = Rx<LowMode?>(null);

  ///智能省电模式（微功耗）
  var smartElecSwitch = RxBool(false);

  ///指示灯隐藏
  var ledHidden = RxBool(false);

  ///麦克风音量
  var microphoneVoice = RxDouble(0);

  ///喇叭音量
  var hornVoice = RxDouble(0);

  ///联动校正开关
  var linkableSwitch = RxBool(false);
}
