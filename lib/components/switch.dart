import 'package:flutter/material.dart';

import '../utils/color.dart';
import '../utils/font/font.dart';

class SwitchButton extends StatefulWidget {
  final bool value;
  final VoidCallback onTap;

  const SwitchButton({Key? key, required this.onTap, required this.value})
      : super(key: key);

  @override
  _SwitchButtonState createState() => _SwitchButtonState();
}

class _SwitchButtonState extends State<SwitchButton> {
  final animationDuration = Duration(milliseconds: 300);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Stack(
        children: [
          AnimatedContainer(
            height: 35,
            width: 68,
            // Increased width to accommodate the text
            duration: animationDuration,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              color: widget.value ? blueColor : Color(0xffE7E7E7),
            ),
            child: AnimatedAlign(
              duration: animationDuration,
              alignment:
              widget.value ? Alignment.centerRight : Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Material(
                      elevation: 2,
                      borderRadius: BorderRadius.circular(100),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          widget.value
              ? Positioned(left: 10,top: 10, child: Text('ON',style: f12Whitew700,))
              : Positioned(right: 6,top: 10, child: Text('OFF',style: f12Whitew700,))
        ],
      ),
    );
  }
}




class SwitchButton2 extends StatefulWidget {
  final bool value;
  final VoidCallback onTap;
  final VoidCallback onTap2;

  const SwitchButton2({Key? key, required this.onTap,required this.onTap2,  required this.value})
      : super(key: key);

  @override
  _SwitchButtonState2 createState() => _SwitchButtonState2();
}

class _SwitchButtonState2 extends State<SwitchButton2> {
  final animationDuration = Duration(milliseconds: 300);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AnimatedContainer(
          height: 50,
          width: 200,
          // Increased width to accommodate the text
          duration: animationDuration,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            color: Color(0xffE7E7E7),
          ),
          child: AnimatedAlign(
            duration: animationDuration,
            alignment: widget.value ? Alignment.centerRight : Alignment.centerLeft,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 100,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(30),
                  ),
                )
                // Material(
                //   elevation: 2,
                //   borderRadius: BorderRadius.circular(100),
                //   child: Container(
                //     width: 28,
                //     height: 28,
                //     decoration: BoxDecoration(
                //       shape: BoxShape.circle,
                //       color: Colors.white,
                //     ),
                //   ),
                // ),
              ],
            ),
          ),
        ),
        Positioned(left: 24,top: 15, child: GestureDetector(
            onTap: widget.onTap,
            child: Container(child: Text('설정하기',style: grf14w600(),)))),
        Positioned(right: 32,top: 15, child: GestureDetector(
            onTap: widget.onTap2,
            child: Text('지우기',style: grf14w600(),)))
      ],
    );
  }
}