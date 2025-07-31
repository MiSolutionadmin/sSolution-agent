import 'package:flutter/material.dart';
import 'package:volume_control/volume_control.dart';

class TfPauseIcon extends StatefulWidget {
  const TfPauseIcon({super.key});

  @override
  State<TfPauseIcon> createState() => _TfPauseIconState();
}


class _TfPauseIconState extends State<TfPauseIcon> {
  bool isMuted = true;

  @override
  void initState() {
    super.initState();
    VolumeControl.setVolume(0.0);
  }

  @override
  void dispose() {
    super.dispose();
  }

  void toggleMute() async {
    if (isMuted) {
      await VolumeControl.setVolume(0.5);
    } else {
      await VolumeControl.setVolume(0.0);
    }
    setState(() {
      isMuted = !isMuted;
    });
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(isMuted ? Icons.volume_off : Icons.volume_up),
      color: Colors.white,
      onPressed: toggleMute,
    );
  }
}
