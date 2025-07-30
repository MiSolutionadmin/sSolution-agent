import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'tf_settings_logic.dart';
import 'tf_settings_state.dart';
// import 'package:ssolution_mms/tf_settings/tf_settings_logic.dart';
// import 'package:ssolution_mms/tf_settings/tf_settings_state.dart';

class TFSettingsPage extends GetView<TFSettingsLogic> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('TF Settings'),
          leading: BackButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ),
        body: Container(
          padding: EdgeInsets.all(24),
          child: Column(
            children: [
              InkWell(
                onTap: () async {
                  var resolution = await showTFRecordResolutionDialog(
                      context, controller.state!);
                  if (resolution != null && resolution != "cancel") {
                    int value = int.parse(resolution);
                    controller.setTFRecordResolution(value);
                  }
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("录像时间"),
                    Text("  >>"),
                  ],
                ),
              ),
              // SizedBox(height: 10),
              // Divider(height: 1),
              // SizedBox(height: 10),
              // InkWell(
              //   onTap: () async {
              //     ///
              //   },
              //   child: Row(
              //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //     children: [
              //       Text("录像模式"),
              //       Text("  >>"),
              //     ],
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }

  ///录像分辨率
  Future<String?> showTFRecordResolutionDialog(
      BuildContext context, TFSettingsState state) {
    int selected = state.tfResolution.value;
    var hdName = '录像时间超短'.tr;
    var normalName = '录像时间短'.tr;
    var lowName = '录像时间长'.tr;
    return showCupertinoModalPopup(
        context: context,
        builder: (context) {
          return CupertinoActionSheet(
            actions: <Widget>[
              CupertinoActionSheetAction(
                child: Text(hdName),
                onPressed: () {
                  Navigator.of(context).pop("0");
                },
                isDestructiveAction: selected == 0,
              ),
              CupertinoActionSheetAction(
                child: Text(normalName),
                onPressed: () {
                  Navigator.of(context).pop("1");
                },
                isDestructiveAction: selected == 1,
              ),
              CupertinoActionSheetAction(
                child: Text(lowName),
                onPressed: () {
                  Navigator.of(context).pop("2");
                },
                isDestructiveAction: selected == 2,
              ),
            ],
            cancelButton: CupertinoActionSheetAction(
              child: Text(
                '取消'.tr,
                style: TextStyle(fontSize: 18, color: Colors.red),
              ),
              onPressed: () {
                Navigator.of(context).pop("cancel");
              },
            ),
          );
        });
  }

  ///录像模式
  void showRecordModelSheet() {
    showModalBottomSheet(
        context: Get.context!,
        builder: (BuildContext context) {
          return Container(
              height: 250,
              margin: EdgeInsets.only(left: 20),
              decoration: BoxDecoration(border: Border(top: BorderSide())),
              child: Column(
                children: [
                  SizedBox(height: 30),
                  recordModelItem("24小时录像", 0),
                  SizedBox(height: 20),
                  recordModelItem("计划录像", 1),
                  SizedBox(height: 20),
                  recordModelItem("运动侦测录像", 2),
                  SizedBox(height: 20),
                  recordModelItem("不录像", 3),
                ],
              ));
        });
  }

  Widget recordModelItem(String name, int index) {
    return InkWell(onTap: () {}, child: Text(name));
  }
}
