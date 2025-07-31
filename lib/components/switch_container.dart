import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

import '../utils/font/font.dart';
import 'switch.dart';


class SwitchContainer extends StatefulWidget {
  final bool value;
  final String name;
  final VoidCallback onTap;
  final String value2;
  const SwitchContainer({Key? key, required this.onTap, required this.value, required this.name, required this.value2})
      : super(key: key);

  @override
  _SwitchButtonState createState() => _SwitchButtonState();
}

class _SwitchButtonState extends State<SwitchContainer> {

  @override
  Widget build(BuildContext context) {
    return  Container(
      width: Get.width,
      height: 75,
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20)
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 20,right: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${widget.name}',style: f18w700Size(),),
            widget.value2 =='0'
                ?Text('미등록',style: f16w700Sizegrey(),)
                :SwitchButton(onTap: widget.onTap, value: widget.value)
          ],
        ),
      ),
    );
  }
}