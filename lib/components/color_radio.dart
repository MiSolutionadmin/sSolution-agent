import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../utils/color.dart';

Widget BlueRadio(){
  return Stack(
    children: [
      Positioned(
        child: Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xff1955EE)
          ),
        ),
      ),
      Positioned(
        top: 5,
        right: 0.0,
        left: 0.0,
        child: Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xff89AAFF)
          ),
        ),
      )
    ],
  );
}
Widget RedRadio(){
  return Stack(
    children: [
      Positioned(
        child: Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xff921322)
          ),
        ),
      ),
      Positioned(
        top: 5,
        right: 0.0,
        left: 0.0,
        child: Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xffF42038)
          ),
        ),
      )
    ],
  );
}

Widget BlackRadio(){
  return Stack(
    children: [
      Positioned(
        child: Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: blackColor
          ),
        ),
      ),
      Positioned(
        top: 5,
        right: 0.0,
        left: 0.0,
        child: Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: blackColor
          ),
        ),
      )
    ],
  );
}