import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import '../utils/color.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
        child:  LoadingAnimationWidget.discreteCircle(
          color: Colors.white,
          secondRingColor: blueColor,
          thirdRingColor: greenColor2,
          size: 50,
        ));
  }
}
