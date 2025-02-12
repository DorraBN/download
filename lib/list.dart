import 'package:flutter/material.dart';
import 'package:new_video_download/about.dart';
import 'package:new_video_download/download.dart';
import 'package:new_video_download/settings.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/foundation.dart'; 
import 'package:url_launcher/url_launcher.dart'; 

class VideoListPage extends StatefulWidget {
  @override
  _VideoListPageState createState() => _VideoListPageState();
}

class _VideoListPageState extends State<VideoListPage> {
  int _selectedIndex = 1;


  Future<List<FileSystemEntity>> _listDownloadedVideos() async {
    final directory = await getApplicationDocumentsDirectory();
    final videoDir = Directory('${directory.path}/videos');

    if (await videoDir.exists()) {
      return videoDir.listSync();
    } else {
      return [];
    }
  }

  String _getTimeElapsed(FileSystemEntity file) {
    final fileStat = file.statSync();
    final fileDate = fileStat.changed;
    final currentDate = DateTime.now();
    final difference = currentDate.difference(fileDate);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return '${difference.inSeconds}s ago';
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Downloaded Videos"),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Downloaded Videos:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: FutureBuilder<List<FileSystemEntity>>(
                future: _listDownloadedVideos(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No downloaded videos.'));
                  } else {
                    final files = snapshot.data!;
                    return ListView.builder(
                      itemCount: files.length,
                      itemBuilder: (context, index) {
                        final file = files[index];
                        return ListTile(
                          leading: file.path.endsWith('.mp4')
                              ? Icon(Icons.video_library)
                              : Icon(Icons.error),
                          title: Text(file.path.split('/').last),
                          subtitle: Text(_getTimeElapsed(file), style: TextStyle(fontSize: 12, color: Colors.grey)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                 
                                  _showDeleteDialog(file);
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.share, color: Colors.blue),
                                onPressed: () {
                                 
                                  _showShareMenu(file);
                                },
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => VideoPlayerPage(
                                  videoPath: file.path,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  }
                },
              ),
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


  void _deleteVideo(FileSystemEntity file) async {
    try {
      await file.delete();
      setState(() {});
    } catch (e) {
      print('Error deleting video: $e');
    }
  }

  void _shareVideoToPlatform(FileSystemEntity file, String platform) async {
    try {
      final xFile = XFile(file.path);

      
      await Share.shareXFiles([xFile], text: 'Check out this video on $platform!');
    } catch (e) {
      print('Error sharing video: $e');
    }
  }


  void _showShareMenu(FileSystemEntity file) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    _buildShareIcon('images/whatsapp.jpg', 'WhatsApp', file),
                    SizedBox(width: 16), 
                    _buildShareIcon('images/youtube.png', 'YouTube', file),
                    SizedBox(width: 16),
                    _buildShareIcon('images/instagram.jpg', 'Instagram', file),
                    SizedBox(width: 16),
                    _buildShareIcon('images/x.webp', 'X', file),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }


  Widget _buildShareIcon(String assetPath, String label, FileSystemEntity file) {
    return GestureDetector(
      onTap: () {
        _showShareConfirmationDialog(file, label); 
      },
      child: Column(
        children: [
          Image.asset(
            assetPath,
            width: 32, 
            height: 32,
          ),
          Text(label),
        ],
      ),
    );
  }


  void _showShareConfirmationDialog(FileSystemEntity file, String platform) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Are you sure?"),
          content: Text("Do you want to share this video via $platform?"),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); 
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                if (platform == 'Instagram') {
                  _shareVideoToInstagram(file);
                } else {
                  _shareVideoToPlatform(file, platform); 
                }
                Navigator.of(context).pop(); 
              },
              child: const Text("Yes"),
            ),
          ],
        );
      },
    );
  }

 
  void _shareVideoToInstagram(FileSystemEntity file) async {
    final filePath = file.path;
    final instagramUrl = 'https://www.instagram.com/';
    
    if (await canLaunch(instagramUrl)) {
      await launch(instagramUrl);
    } else {
      throw 'Could not open Instagram';
    }
  }

  void _showDeleteDialog(FileSystemEntity file) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Are you sure?"),
          content: const Text("Do you really want to delete this video?"),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                _deleteVideo(file); 
                Navigator.of(context).pop();
              },
              child: const Text("Yes"),
            ),
          ],
        );
      },
    );
  }
}
