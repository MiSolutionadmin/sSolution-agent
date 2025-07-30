import 'package:get/get.dart';

import 'tf_settings_logic.dart';
// import 'package:ssolution_mms/tf_settings/tf_settings_logic.dart';

class TFSettingsBind implements Bindings {
  @override
  void dependencies() {
    Get.put<TFSettingsLogic>(TFSettingsLogic());
  }
}
