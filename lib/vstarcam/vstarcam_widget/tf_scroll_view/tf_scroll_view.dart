import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mms/vstarcam/tf_play/tf_play_logic.dart';
import 'package:mms/vstarcam/tf_play/tf_play_state.dart';

import '../../../components/dialog.dart';
import '../../../provider/camera_state.dart';
import '../../model/record_file_model.dart';
import 'package:get/get.dart';

import 'tf_scroll_logic.dart';

class TFScrollView<S> extends StatefulWidget {
  TFScrollView({Key? key}) : super(key: key);

  @override
  State<TFScrollView<S>> createState() => _TFScrollViewState<S>();
}

class _TFScrollViewState<S> extends State<TFScrollView<S>> {
  final cs = Get.find<CameraState>();

  @override
  void initState() {
    cs.tfcardIndex.value = 0;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    TFScrollLogic logic = Get.find<TFScrollLogic>();
    TFPlayState state = logic.state!;
    final TFPlayLogic tfPlayLogic = Get.find<TFPlayLogic>();

    return Expanded(
      child: Obx(() {
        final tfcardIndex = cs.tfcardIndex.value;
        final records = state.recordFileModels.value;
        if (records.isEmpty) {
          return Center(child: Text("해당 날짜에는 데이터가 없습니다"));
        }
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 16),
          shrinkWrap: true,
          itemCount: records.length,
          itemBuilder: (context, index) {
            final model = records[index];
            final isSelected = index == tfcardIndex;
            return GestureDetector(
              onTap: () async{
                await _onTapHandler(cs, model, state, index, tfPlayLogic);
                _onTapHandler(cs, model, state, index, tfPlayLogic);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                height: 50,
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey, width: 1.0),
                  borderRadius: BorderRadius.circular(10.0),
                  color: isSelected ? Colors.blue[100] : Colors.white,
                ),
                child: _buildRowContent(model, context),
              ),
            );
          },
        );
      }),
    );
  }

  Future<void> _onTapHandler(CameraState cs, RecordFileModel model, TFPlayState state, int index, TFPlayLogic tf) async {
    try{
      print('?? 선택한? ${model.recordName}');
      await tf.stopVideo();
      DateTime currentTime = model.recordTime;
      int currentHour = currentTime.hour - 2;
      int currentMinute = currentTime.minute;
      double minuteRatio = currentMinute / 60;
      double pixelValue = currentHour + minuteRatio;
      pixelValue = double.parse(pixelValue.toStringAsFixed(1));

      cs.timeCon.value.animateTo(
        pixelValue * Get.width * 0.25,
        duration: Duration(milliseconds: 1),
        curve: Curves.easeInOut,
      );

      state.playModel.value = model;
      state.selectModel.value = model;
      print('화면에서 보낸 모델 : ${state.playModel.value!.recordSize}');

      cs.tfcardIndex.value = index;
      cs.addTime.value = 0;

      await tf.startVideo();
    }catch(e){
      print('erororo?? ${e}');
    }
    // if (model.recordName != _pastRecordName) {
    // }


    // _pastRecordName = model.recordName;
    // } finally {
    //   _isHandlingTap = false;
    // }
  }

  Widget _buildRowContent(RecordFileModel model, BuildContext context) {
    String formattedDateTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(model.recordTime);

    return Row(
      children: [
        if (model.recordAlarm == 2) Text(" 모션 감지 ：") else if (model.recordAlarm == 3) Text(" 불꽃 감지 ：") else if(model.recordAlarm==4) Text(" 연기 감지 ：")else Text("실시간 : "),
        Text(
          '$formattedDateTime',
        ),
        Spacer(),
        GestureDetector(
          onTap: () {
            showConfirmTapDialog(
              context,
              '해당 녹화본을 삭제하시겠습니까?',
              () {
                TFPlayLogic tfPlayLogic = Get.find<TFPlayLogic>();
                tfPlayLogic.deleteRecordFile(model, false);
                Get.back();
              },
            );
          },
          child: Text("  삭제  "),
        ),
      ],
    );
  }
}
