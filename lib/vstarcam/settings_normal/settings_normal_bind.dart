import 'package:get/get.dart';

import '../vstarcam_widget/voice_slider/voice_slider_logic.dart';
import 'settings_normal_logic.dart';
// import 'package:mms/settings_normal/settings_normal_logic.dart';
// import 'package:ssolution_mms/settings_normal/settings_normal_logic.dart';

// import '../widget/voice_slider/voice_slider_logic.dart';

class SettingsNormalBind implements Bindings {
  @override
  void dependencies() {
    Get.put<SettingsNormalLogic>(SettingsNormalLogic());
    SettingsNormalLogic normalLogic = Get.find<SettingsNormalLogic>();
    Get.put<VoiceSliderLogic>(VoiceSliderLogic(normalLogic.state!));
  }
}
