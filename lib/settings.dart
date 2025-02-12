import 'package:flutter/material.dart';
import 'package:new_video_download/download.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:new_video_download/list.dart';
import 'package:new_video_download/about.dart';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettingsPage extends StatefulWidget {
  @override
  _AppSettingsPageState createState() => _AppSettingsPageState();
}

class _AppSettingsPageState extends State<AppSettingsPage> {
  String _downloadFolder = '/path/to/save/videos';
  bool _isDarkTheme = false;
  int _selectedIndex = 2; 
  String _selectedLanguage = 'English'; 

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }


  _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _downloadFolder = prefs.getString('downloadFolder') ?? '/path/to/save/videos';
      _isDarkTheme = prefs.getBool('isDarkTheme') ?? false;
      _selectedLanguage = prefs.getString('language') ?? 'English'; 
    });
  }

  
  _saveSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('downloadFolder', _downloadFolder);
    prefs.setBool('isDarkTheme', _isDarkTheme);
    prefs.setString('language', _selectedLanguage); 
  }


  _toggleTheme(bool value) {
    setState(() {
      _isDarkTheme = value;
    });
    _saveSettings();
  }


  _pickDownloadFolder() async {
    setState(() {
      _downloadFolder = '/new/path/to/save/videos';
    });
    _saveSettings();
  }


  _changeLanguage(String value) {
    setState(() {
      _selectedLanguage = value;
    });
    _saveSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("App Settings"),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
          
            ListTile(
              title: Text("Download Folder"),
              subtitle: Text(_downloadFolder),
              trailing: Icon(Icons.folder),
              onTap: _pickDownloadFolder,
            ),
            Divider(),
            
            SwitchListTile(
              title: Text("Dark Theme"),
              value: _isDarkTheme,
              onChanged: _toggleTheme,
            ),
            Divider(),
           
            ListTile(
              title: Text("Language"),
              subtitle: Text(_selectedLanguage),
              trailing: Icon(Icons.language),
              onTap: () {
           
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: Text("Select Language"),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            title: Text("English"),
                            onTap: () {
                              _changeLanguage('English');
                              Navigator.pop(context);
                            },
                          ),
                          ListTile(
                            title: Text("Français"),
                            onTap: () {
                              _changeLanguage('Français');
                              Navigator.pop(context);
                            },
                          ),
                          
                        ],
                      ),
                    );
                  },
                );
              },
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

