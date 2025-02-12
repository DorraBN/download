import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:new_video_download/about.dart';
import 'package:new_video_download/list.dart';
import 'package:new_video_download/settings.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:pod_player/pod_player.dart';

class VideoDownloadPage extends StatefulWidget {
  @override
  _VideoDownloadPageState createState() => _VideoDownloadPageState();
}

class _VideoDownloadPageState extends State<VideoDownloadPage> {
  final TextEditingController _urlController = TextEditingController();
  double _progress = 0.0;
  Dio _dio = Dio();
  CancelToken _cancelToken = CancelToken();
  bool _isDownloading = false;
  bool _isPaused = false;
  int _selectedIndex = 0;
  int _downloadedBytes = 0;  // Track downloaded bytes

  // Get the path to save the video
  Future<String> _getSavePath() async {
    final directory = await getApplicationDocumentsDirectory();
    final videoDir = Directory('${directory.path}/videos');

    if (!await videoDir.exists()) {
      await videoDir.create(recursive: true);
    }

    return '${videoDir.path}/video_${DateTime.now().millisecondsSinceEpoch}.mp4';
  }

  // Download the video from the URL
  void _downloadVideo() async {
    String videoUrl = _urlController.text.trim();

    if (videoUrl.isEmpty) {
      _showMessage("Please enter a URL.");
      return;
    }

    String savePath = await _getSavePath();

    try {
      setState(() {
        _isDownloading = true;
      });

      await _dio.download(
        videoUrl,
        savePath,
        cancelToken: _cancelToken,
        options: Options(
          headers: {
            HttpHeaders.rangeHeader: "bytes=$_downloadedBytes-",  // Add range header to resume
          },
        ),
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              _downloadedBytes = received;  // Update the downloaded bytes
              _progress = received / total;
            });
          }
        },
      );

      setState(() {
        _isDownloading = false;
      });

      _showDownloadCompleteDialog(savePath);
    } catch (e) {
      setState(() {
        _isDownloading = false;
      });
      _showMessage("Download failed: $e");
    }
  }

  // Pauses the download
  void _pauseDownload() {
    if (_isDownloading) {
      _cancelToken.cancel("Download Paused");
      setState(() {
        _isPaused = true;
        _isDownloading = false;
      });
    }
  }

  // Resumes the download
  void _resumeDownload() {
    if (_isPaused) {
      _downloadVideo();  
      setState(() {
        _isPaused = false;
      });
    }
  }

  // Cancel the download
  void _cancelDownload() {
    if (_isDownloading) {
      _cancelToken.cancel("Download Canceled");
      setState(() {
        _isDownloading = false;
      });
      _showMessage("Download canceled.");
    }
  }


  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showDownloadCompleteDialog(String savePath) {
    String videoName = 'video_${DateTime.now().millisecondsSinceEpoch}.mp4'; 
    TextEditingController _nameController = TextEditingController(text: videoName);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Download Complete"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text("Your video has been successfully downloaded!"),
              SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: "Enter video name",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context);  
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                String newVideoName = _nameController.text.trim();
                if (newVideoName.isNotEmpty) {
                
                  String newSavePath = '${savePath.substring(0, savePath.lastIndexOf('/'))}/$newVideoName';
                  File(savePath).renameSync(newSavePath);  
                  Navigator.pop(context); 

                 
                  _showViewVideoDialog(newSavePath);
                } else {
                  _showMessage("Please enter a valid name.");
                }
              },
              child: Text("Save"),
            ),
          ],
        );
      },
    );
  }

  void _showViewVideoDialog(String videoPath) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("View Video"),
          content: Text("Do you want to watch the video?"),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context); 
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);  
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VideoPlayerPage(videoPath: videoPath),
                  ),
                );
              },
              child: Text("Watch Video"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Video Downloader"),
        backgroundColor: Colors.deepPurpleAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
                labelText: "Enter video URL",
                prefixIcon: Icon(Icons.link),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isDownloading ? null : _downloadVideo,
              child: Text("Download", style: TextStyle(fontSize: 18.0)),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 32.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                backgroundColor: Colors.deepPurpleAccent,
              ),
            ),
            SizedBox(height: 20),
            LinearProgressIndicator(
              value: _progress,
              backgroundColor: Colors.grey[300],
              color: Colors.deepPurpleAccent,
              minHeight: 8.0,
            ),
            SizedBox(height: 16),
            Text(
              "${(_progress * 100).toStringAsFixed(0)}% Downloaded",
              style: TextStyle(fontSize: 16.0, color: Colors.black),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _isDownloading ? _pauseDownload : null,
                  child: Icon(Icons.pause),
                  style: ElevatedButton.styleFrom(
                    shape: CircleBorder(), backgroundColor: Colors.orange,
                    padding: EdgeInsets.all(16.0),
                  ),
                ),
                SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _isPaused ? _resumeDownload : null,
                  child: Icon(Icons.play_arrow),
                  style: ElevatedButton.styleFrom(
                    shape: CircleBorder(), backgroundColor: Colors.green,
                    padding: EdgeInsets.all(16.0),
                  ),
                ),
                SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _isDownloading || _isPaused ? _cancelDownload : null,
                  child: Icon(Icons.cancel),
                  style: ElevatedButton.styleFrom(
                    shape: CircleBorder(), backgroundColor: Colors.red,
                    padding: EdgeInsets.all(16.0),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
       bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex, 
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.download),
            label: 'Download',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'List',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.info_outline),
            label: 'About',
          ),
        ],
        selectedItemColor: Colors.deepPurpleAccent,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });

          switch (index) {
            case 0:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => VideoDownloadPage()),
              );
              break;
            case 1:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => VideoListPage()),
              );
              break;
            case 2:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AppSettingsPage()),
              );
              break;
            case 3:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AboutPage()),
              );
              break;
          }
        },
      ),
    );
  }
}


class VideoPlayerPage extends StatefulWidget {
  final String videoPath;

  const VideoPlayerPage({Key? key, required this.videoPath}) : super(key: key);

  @override
  _VideoPlayerPageState createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late PodPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PodPlayerController(
      playVideoFrom: PlayVideoFrom.file(File(widget.videoPath)),
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
        title: Text("Play Video"),
      ),
      body: Center(
        child: PodVideoPlayer(controller: _controller),
      ),
    );
  }
}
