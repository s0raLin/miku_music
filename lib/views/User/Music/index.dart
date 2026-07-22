import 'package:flutter/material.dart';

import 'package:myapp/views/User/Music/tabs/library_tab.dart'; // 整合后的乐库
import 'package:myapp/views/User/Music/tabs/playlist_tab.dart';

class MusicPage extends StatefulWidget {
  const MusicPage({super.key});

  @override
  State<MusicPage> createState() => _MusicPageState();
}

class _MusicPageState extends State<MusicPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DefaultTabController(
        length: 2,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                title: const Text("音乐库"),
                pinned: true,
                bottom: const TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  tabs: [
                    Tab(text: "乐库"),
                    Tab(text: "歌单"),
                  ],
                ),
              ),
            ];
          },
          body: const TabBarView(
            children: [
              LibraryTab(), // 乐库
              PlaylistTab(), // 歌单
            ],
          ),
        ),
      ),
    );
  }
}
