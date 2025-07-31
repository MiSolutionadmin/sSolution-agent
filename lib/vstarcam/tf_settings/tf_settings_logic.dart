// import 'package:ssolution_mms/tf_settings/tf_settings_state.dart';
// import 'package:ssolution_mms/utils/device_manager.dart';

import '../../utils/device_manager.dart';
import '../../utils/super_put_controller.dart';
// import '../utils/device_manager.dart';
// import '../utils/super_put_controller.dart';
import 'tf_settings_state.dart';

class TFSettingsLogic extends SuperPutController<TFSettingsState> {
  TFSettingsLogic() {
    value = TFSettingsState();
  }

  @override
  void onInit() {
    getResolution();
    super.onInit();
  }

  ///获取录像时间
  void getResolution() async {
    bool bl = await DeviceManager.getInstance()
            .mDevice!
            .recordResolutionCommand
            ?.getRecordResolutionState() ??
        false;
    if (bl == true) {
      state!.tfResolution.value = DeviceManager.getInstance()
              .mDevice!
              .recordResolutionCommand
              ?.recordResolut ??
          2;
    }
  }

  ///设置录像时间
  void setTFRecordResolution(int resolution) async {
    bool bl = await DeviceManager.getInstance()
            .mDevice!
            .recordResolutionCommand
            ?.controlRecordResolution(resolution) ??
        false;
    print("----setTFRecordResolution--$bl--resolution-$resolution-");
    if (bl) {
      state!.tfResolution.value = resolution;
    }
  }

  ///设置全天录制
  void setRecordDay(int enable) async {
    bool bl =
        await DeviceManager.getInstance().mDevice!.setRecordParams(enable);
    if (bl) {}
  }

  @override
  void onHidden() {
    // TODO: implement onHidden
  }
}
