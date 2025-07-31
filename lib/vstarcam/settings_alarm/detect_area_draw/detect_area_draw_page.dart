import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vsdk/app_player.dart';

// import '../../ssolution/lib/components/monitoring_dialog.dart';
// import '../../ssolution/lib/components/switch.dart';
// import '../../ssolution/lib/db/camera_table.dart';
// import '../../ssolution/lib/provider/camera_state.dart';
// import '../../ssolution/lib/screen/util/font/font.dart';
// import '../../utils/device_manager.dart';
// import '../../utils/manager.dart';
// import '../../widget/other/grid_painter_widget.dart';
// import '../../widget/virtual_three_view.dart';
import '../../../components/monitoring_dialog.dart';
import '../../../db/camera_table.dart';
import '../../../provider/camera_state.dart';
import '../../../utils/font/font.dart';
import '../../../utils/device_manager.dart';
import '../../vstarcam_widget/other/grid_painter_widget.dart';
import '../Settings_logic.dart';
import 'detect_area_draw_logic.dart';

class DetectAreaDrawPage extends GetView<DetectAreaDrawLogic> {
  @override
  Widget build(BuildContext context) {
    DetectAreaDrawLogic logic = Get.find<DetectAreaDrawLogic>();
    SettingsLogic settingsLogic = Get.find<SettingsLogic>();
    double aWidth = MediaQuery.of(context).size.width;
    double aHeight = aWidth * 9 / 16;
    final cs = Get.find<CameraState>();
    return Scaffold(
        appBar: AppBar(
          title: Text(
            '감지 영역 설정',
            style: f16w700Size(),
          ),
          leading: BackButton(
            onPressed: () {
              Get.back();
            },
          ),
          actions: [
            GestureDetector(
              onTap: () async {
                settingsLogic.state!.motionPushEnable.value = 1;
                // controller.save(controller.state!.gridState.value);

                /// 서버에 저장
                final updatedCameraDetailList = [...cs.cameraDetailList];
                cs.cameraDetailList[0]['scanArea'] = '${controller.state!.gridState.value}';
                cs.cameraDetailList.assignAll(updatedCameraDetailList);

                /// cgi
                DetectAreaDrawLogic dLogic = Get.find<DetectAreaDrawLogic>();
                var result = dLogic.getAreaRecords(controller.state!.gridState.value);
                String resultJoin = result.join(',');
                await cameraScanResult(cs.cameraUID.value,'scanArea', '${controller.state!.gridState.value}',resultJoin);
                cs.cameraDetailList[0]['scanResult'] = resultJoin;
                await DeviceManager.getInstance().mDevice!.writeCgi(
                    "trans_cmd_string.cgi?cmd=2123&command=0&"
                        "md_reign0=${result[0]}&"
                        "md_reign1=${result[1]}&"
                        "md_reign2=${result[2]}&"
                        "md_reign3=${result[3]}&"
                        "md_reign4=${result[4]}&"
                        "md_reign5=${result[5]}&"
                        "md_reign6=${result[6]}&"
                        "md_reign7=${result[7]}&"
                        "md_reign8=${result[8]}&"
                        "md_reign9=${result[9]}&"
                        "md_reign10=${result[10]}&"
                        "md_reign11=${result[11]}&"
                        "md_reign12=${result[12]}&"
                        "md_reign13=${result[13]}&"
                        "md_reign14=${result[14]}&"
                        "md_reign15=${result[15]}&"
                        "md_reign16=${result[16]}&"
                        "md_reign17=${result[17]}&",
                    timeout: 5);


                showOnlyConfirmDialog(context, '저장되었습니다');
              },
              child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text('저장',style: f14w700BlueSize(),)
              ),
            )
          ],
        ),
        body: Column(
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9, //横纵比 长宽比 16 : 9
                  child: AppPlayerView(
                    controller: DeviceManager.getInstance().controller!,
                  ),
                ),
                Obx(() {
                  return GridPainter(aWidth, aHeight, (data) {
                    /// 데이터 저장
                    controller.save(data);
                    logic.getAreaData();
                  }, controller.state!.gridState.value);
                })
              ],
            ),


          ],
        )
    );
  }
}
