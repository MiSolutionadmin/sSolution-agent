import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

import '../utils/font/font.dart';
import 'switch.dart';


class TextContainer extends StatefulWidget {
  final bool value;
  final String name;
  final VoidCallback onTap;
  final String value2;
  const TextContainer({Key? key, required this.onTap, required this.value, required this.name, required this.value2})
      : super(key: key);

  @override
  _TextButtonState createState() => _TextButtonState();
}

class _TextButtonState extends State<TextContainer> {

  @override
  Widget build(BuildContext context) {
    return  Container(
      width: Get.width,
      height: 65,
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
            widget.value2 =='false'
                ?Text('미등록',style: f16w700Sizegrey(),)
                :Row(
              children: [
                GestureDetector(
                  onTap:widget.onTap,
                    child: Text('켜기',style: widget.value?f16w700Size():f16w600GreySize(),)),
                const SizedBox(width: 20,),
                GestureDetector(
                  onTap: widget.onTap,
                    child: Text('끄기',style: widget.value?f16w600GreySize():f16w700Size(),))
              ],
            )
          ],
        ),
      ),
    );
  }
}


class SwitchContainer extends StatefulWidget {
  final bool value;
  final String name;
  final VoidCallback onTap;
  const SwitchContainer({Key? key, required this.onTap, required this.value, required this.name})
      : super(key: key);

  @override
  _switchContainer createState() => _switchContainer();
}

class _switchContainer extends State<SwitchContainer> {

  @override
  Widget build(BuildContext context) {
    return Container(
      width: Get.width,
      height: 65,
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
            SwitchButton(
                onTap: widget.onTap, value: widget.value)
          ],
        ),
      ),
    );
  }
}

class CheckContainer extends StatefulWidget {
  final bool value;
  final String name;
  final VoidCallback onTap;
  const CheckContainer({Key? key, required this.onTap, required this.value, required this.name})
      : super(key: key);

  @override
  _checkContainer createState() => _checkContainer();
}

class _checkContainer extends State<CheckContainer> {

  @override
  Widget build(BuildContext context) {
    return Container(
      width: Get.width,
      height: 65,
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
            SwitchButton(
                onTap: widget.onTap, value: widget.value)
          ],
        ),
      ),
    );
  }
}