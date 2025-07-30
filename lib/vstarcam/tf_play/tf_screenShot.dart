import 'dart:io';

import 'package:flutter/material.dart';

class ImagePreviewScreen extends StatelessWidget {
  final String filePath;

  const ImagePreviewScreen({Key? key, required this.filePath}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('이미지 미리보기'),
      ),
      body: Center(
        child: Image.file(File(filePath)),
      ),
    );
  }
}