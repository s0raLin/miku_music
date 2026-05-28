import 'package:flutter/material.dart';

class MusicUploadPage extends StatefulWidget {
  const MusicUploadPage({super.key});

  @override
  State<MusicUploadPage> createState() => _MusicUploadState();
}

class _MusicUploadState extends State<MusicUploadPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("上传歌曲")),
      body: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [

        ],
      ),
    );
  }
}
