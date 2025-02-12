import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:new_video_download/vid.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pod_player/pod_player.dart';

class PlayVideoFromVimeo extends StatefulWidget {
  const PlayVideoFromVimeo({Key? key}) : super(key: key);

  @override
  State<PlayVideoFromVimeo> createState() => _PlayVideoFromVimeoState();
}

class _PlayVideoFromVimeoState extends State<PlayVideoFromVimeo> {
  late final Dio dio;
  double _progress = 0.0;
  String? _videoFilePath;
  TextEditingController _urlController = TextEditingController();  // Controller for URL input

  @override
  void initState() {
    super.initState();
    dio = Dio();
  }

  Future<void> _downloadAndSaveVideo() async {
    String url = _urlController.text; // Use the input URL

    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a video URL'),
        ),
      );
      return;
    }

    try {
      Directory appDocDir = await getApplicationDocumentsDirectory();
      String savePath = appDocDir.path + '/video.mp4';

      await dio.download(
        url,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            double progress = (received / total * 100);
            setState(() {
              _progress = progress;
            });
          }
        },
      );
      print('File downloaded to: $savePath');
      setState(() {
        _videoFilePath = savePath;
      });

      // Save the file path to Hive
      final box = await Hive.openBox<String>('videos');
      box.put('video_path', savePath);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Video downloaded and saved successfully'),
        ),
      );
    } catch (e) {
      print('Error downloading file: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error downloading and saving video'),
        ),
      );
    }
  }

  Future<void> _playVideoFromHive() async {
    final box = await Hive.openBox<String>('videos');
    String? videoPath = box.get('video_path');

    if (videoPath != null) {
      setState(() {
        _videoFilePath = videoPath;
      });
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoPlayerScreen(
            videoFilePath: _videoFilePath!,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Video not found in Hive database'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Download and Play Video'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // URL input field
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _urlController,
                decoration: InputDecoration(
                  labelText: 'Enter video URL',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            if (_progress > 0 && _progress < 100)
              LinearProgressIndicator(
                value: _progress / 100,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _downloadAndSaveVideo,
              child: Text("Download and Save Video"),
            ),
            ElevatedButton(
              onPressed: _playVideoFromHive,
              child: Text("Play Video from Hive"),
            ),
          ],
        ),
      ),
    );
  }
}
