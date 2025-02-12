import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pod_player/pod_player.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String videoFilePath;

  const VideoPlayerScreen({Key? key, required this.videoFilePath})
      : super(key: key);

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late final PodPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PodPlayerController(
      playVideoFrom: PlayVideoFrom.file(File(widget.videoFilePath)),
    )..initialise();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Video Player'),
      ),
      body: PodVideoPlayer(controller: _controller),
    );
  }
}
