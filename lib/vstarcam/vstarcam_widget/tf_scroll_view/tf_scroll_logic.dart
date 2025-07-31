import 'package:get/get.dart';
import 'package:mms/vstarcam/tf_play/tf_play_state.dart';
import '../../../utils/super_put_controller.dart';


mixin TFScrollLogic on SuperPutController<TFPlayState> {
  @override
  void initPut() {
    // lazyPut<TFScrollLogic>(this);
    Get.put<TFScrollLogic>(this);
    super.initPut();
  }
}
