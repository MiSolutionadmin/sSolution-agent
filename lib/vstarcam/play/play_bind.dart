// import 'package:get/get.dart';
// import 'package:mms/play/play_logic.dart';
//
// import 'package:ssolution_mms/play/play_logic.dart';
// import 'package:ssolution_mms/settings_main/settings_main_logic.dart';
// import '../settings_alarm/Settings_logic.dart';
// import '../settings_main/ptz/ptz_logic.dart';
// import '../settings_main/settings_main_logic.dart';
// import '../widget/slider_widget/slider_logic.dart';

import 'package:get/get.dart';
import 'package:mms/vstarcam/play/play_logic.dart';

import '../settings_alarm/Settings_logic.dart';
import '../settings_main/ptz/ptz_logic.dart';
import '../settings_main/settings_main_logic.dart';
import '../vstarcam_widget/slider_widget/slider_logic.dart';

class PlayBind implements Bindings {
  @override
  void dependencies() {
    Get.put<PlayLogic>(PlayLogic());
    Get.put<SettingsMainLogic>(SettingsMainLogic());
    Get.put<SettingsLogic>(SettingsLogic());
    SettingsLogic settingsLogic = Get.find<SettingsLogic>();
    Get.put<SliderLogic>(SliderLogic(settingsLogic.state!));
    SettingsMainLogic mainLogic = Get.find<SettingsMainLogic>();
    Get.put<PTZLogic>(PTZLogic(mainLogic.state!));
  }


  void dispose() {
    Get.delete<PlayLogic>();
    Get.delete<SettingsMainLogic>();
    // Get.delete<SettingsLogic>();
  }
}
