import 'package:get/get.dart';

import 'tf_play_logic.dart';
// import 'package:ssolution_mms/tf_play/tf_play_logic.dart';

class TFPlayBind implements Bindings {
  @override
  void dependencies() {
    Get.put<TFPlayLogic>(TFPlayLogic());
  }

  void dispose() {
    Get.delete<TFPlayLogic>();
  }
}
