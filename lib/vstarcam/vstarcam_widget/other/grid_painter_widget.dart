import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../components/dialog.dart';
import '../../../components/switch.dart';
import '../../../provider/camera_state.dart';
import '../../../utils/font/font.dart';



class GridPainter extends StatefulWidget {
  final double width;
  final double height;
  final Function onSave;
  final List<List<int>> gridState;

  GridPainter(this.width, this.height, this.onSave, this.gridState);

  @override
  _GridPainterState createState() => _GridPainterState();
}

class _GridPainterState extends State<GridPainter> {
  bool checking = false;

  // late DragUpdateDetails initDetail;
  final cs = Get.find<CameraState>();

  @override
  void initState() {
    List convertL = jsonDecode(cs.cameraDetailList[0]['scanArea']);
    // RenderBox renderBox = context.findRenderObject() as RenderBox;
    // Offset localPosition =
    // renderBox.globalToLocal(initDetail.globalPosition);

    for (int j = 0; j < 17; j++) {
      for (int i = 0; i < 22; i++) {
        widget.gridState[j][i] = convertL[j][i];
      }
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // AppBar(
        //   title: Text(
        //     '카메라 상세',
        //     style: f16w700Size(),
        //   ),
        //   leading: BackButton(
        //     onPressed: () {
        //       Get.back();
        //     },
        //   ),
        //   actions: [
        //     GestureDetector(
        //       onTap: () async{
        //         print('진짜 저장');
        //
        //         widget.onSave(widget.gridState);
        //         showOnlyConfirmDialog(context, '저장되었습니다');
        //       },
        //       child: Padding(
        //           padding: const EdgeInsets.all(8.0),
        //           child: Text('저장',style: f14w700BlueSize(),)
        //       ),
        //     )
        //   ],
        // ),

        SizedBox(
          width: widget.width,
          height: widget.height,
          child: GestureDetector(
            onPanUpdate: (DragUpdateDetails details) {
              RenderBox renderBox = context.findRenderObject() as RenderBox;
              Offset localPosition = renderBox.globalToLocal(details.globalPosition);
              int row = (localPosition.dy / (widget.height / 18)).floor();
              int col = (localPosition.dx / (widget.width / 22)).floor();
              if (checking) {
                if (row >= 0 && col >= 0 && row < 18 && col < 22) {
                  setState(() {
                    widget.gridState[row][col] = 1;
                  });
                }
              } else {
                if (row >= 0 && col >= 0 && row < 18 && col < 22) {
                  setState(() {
                    widget.gridState[row][col] = 0;
                  });
                }
              }
            },
            child: CustomPaint(
              painter: GridPainterCustom(widget.gridState),
              size: Size.infinite,
            ),
          ),
        ),
        SizedBox(height: 20),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SwitchButton2(
                onTap: () async {
                  checking = false;
                  setState(() {});
                  widget.onSave(widget.gridState);
                },
                onTap2: () {
                  checking = true;

                  setState(() {});
                  widget.onSave(widget.gridState);
                },
                value: checking),
            const SizedBox(
              height: 20,
            ),

            /// 모두 지우기
            GestureDetector(
              onTap: () {
                showConfirmTapDialog(context, '감지 영역 설정을 초기화하시겠습니까?', () {
                  clearArea();
                  Get.back();
                  setState(() {});
                });
              },
              child: Container(
                height: 50,
                width: 200,
                // Increased width to accommodate the text
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  color: Color(0xff1955EE),
                ),
                child: Center(
                    child: Text(
                      '모두 지우기',
                      style: f16w700WhiteSize(),
                    )),
              ),
            ),
            const SizedBox(
              height: 40,
            ),

            /// 사용법
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: Get.width,
                height: null,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(25.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '모든 영역 감지(기본값)',
                        style: f20w700Size(),
                      ),
                      Text(
                        '감지가 없는 구역을 설정하면, 설정된 구역에 대해 더 이상 감지가 되지 않습니다.',
                        style: redf14w700(),
                      ),
                      const SizedBox(
                        height: 50,
                      ),
                      Text(
                        '설정 방법',
                        style: f20w700Size(),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              children: [
                                Image.asset(
                                  'assets/camera_icon/tap.png',
                                  width: 50,
                                  height: 50,
                                ),
                                const SizedBox(
                                  height: 5,
                                ),
                                Text(
                                  '클릭',
                                  style: f14w700Size(),
                                )
                              ],
                            ),
                            Column(
                              children: [
                                Image.asset(
                                  'assets/camera_icon/scrolling1.png',
                                  width: 50,
                                  height: 50,
                                ),
                                const SizedBox(
                                  height: 5,
                                ),
                                Text(
                                  '좌우 스크롤',
                                  style: f14w700Size(),
                                )
                              ],
                            ),
                            Column(
                              children: [
                                Image.asset(
                                  'assets/camera_icon/scrolling2.png',
                                  width: 50,
                                  height: 50,
                                ),
                                const SizedBox(
                                  height: 5,
                                ),
                                Text(
                                  '상하 슬라이드',
                                  style: f14w700Size(),
                                )
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          ],
        )
      ],
    );
  }

  Widget button(String name) {
    return Container(
        width: 100,
        height: 40,
        decoration: BoxDecoration(border: Border.all(color: Colors.grey, width: 1.0), borderRadius: BorderRadius.all(Radius.circular(8))),
        alignment: Alignment.center,
        child: Text(name));
  }

  void clearArea() {
    widget.gridState.forEach((row) {
      row.fillRange(0, row.length, 1);
    });
    setState(() {});
  }
}

class GridPainterCustom extends CustomPainter {
  final List<List<int>> gridState;

  GridPainterCustom(this.gridState);

  @override
  void paint(Canvas canvas, Size size) {
    // 绘制网格
    Paint gridPaint = Paint()
      ..color = Colors.grey
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    double cellWidth = size.width / 22;
    double cellHeight = size.height / 18;

    for (int i = 0; i <= 22; i++) {
      double dx = i * cellWidth;
      canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), gridPaint);
    }

    for (int i = 0; i <= 18; i++) {
      double dy = i * cellHeight;
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), gridPaint);
    }

    // 填充手指涂抹区域
    Paint fillPaint = Paint()..color = Colors.blue;
    for (int i = 0; i < gridState.length; i++) {
      for (int j = 0; j < gridState[i].length; j++) {
        if (gridState[i][j] == 0) {
          canvas.drawRect(Rect.fromLTWH(j * cellWidth, i * cellHeight, cellWidth, cellHeight), fillPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
