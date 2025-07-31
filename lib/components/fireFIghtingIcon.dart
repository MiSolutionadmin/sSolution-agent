import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mms/provider/camera_state.dart';
import 'package:mms/provider/notification_state.dart';
import 'package:mms/utils/font/font.dart';
import 'package:get/get.dart';

class Firefightingicon extends StatefulWidget {
  final VoidCallback? onClick;

  const Firefightingicon({
    Key? key,
    this.onClick,
  }) : super(key: key);

  @override
  State<Firefightingicon> createState() => _FirefightingiconState();
}

class _FirefightingiconState extends State<Firefightingicon> with SingleTickerProviderStateMixin {
  /// GetX 관련
  final cs = Get.find<CameraState>();
  final ns = Get.put(NotificationState());

  /// 애니메이션 관련
  late AnimationController _animationController;
  final alwaysOne = AlwaysStoppedAnimation(1.0); // 애니메이션 안사용할때

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return
    Obx(() =>
        FadeTransition(
          opacity: cs.fireFightingData['fireFightingStatus'] == 1 ? _animationController : alwaysOne,
          child:
          ns.cameraNoti.value != true
              ?
          Container(
              margin: EdgeInsets.only(top: 14),
              padding: EdgeInsets.symmetric(vertical: 8,horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: cs.fireFightingData['fireFightingStatus'] == 1 ?
                Colors.deepOrange :
                Colors.grey,
              ),
              child:
              Text(
                cs.fireFightingData['fireFightingStatus'] == 1 ?
                "작동중":
                "작동완료",
                style: f14Whitew700Size(),
              )
          )
              :
              ElevatedButton.icon(
                onPressed: () {
                  /// ✅ 소화장치 함수
                  if (widget.onClick != null) {
                    widget.onClick!();
                  }
                },
                label: Text(
                  '소화장치 작동',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.black,
                  backgroundColor: cs.fireFightingData['fireFightingStatus'] == 2
                      ?
                  Colors.grey
                      :
                  Colors.deepOrange,
                  minimumSize: const Size(200, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              )
        )
    );
  }
}
