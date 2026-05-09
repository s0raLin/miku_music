import 'package:flutter/material.dart';
import 'package:myapp/views/Music/widgets/albums_tab.dart';
import 'package:myapp/views/Music/widgets/library_tab.dart';
import 'package:myapp/views/Music/widgets/playlist_tab.dart';
import 'package:myapp/views/Music/widgets/queue_tab.dart';

class MusicPage extends StatefulWidget {
  const MusicPage({super.key});

  @override
  State<MusicPage> createState() => _MusicPageState();
}

class _MusicPageState extends State<MusicPage> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 120.0, // 给一个展开高度，让标题有地方折叠
                floating: false, // 向上滚动时 AppBar 是否立即显现
                pinned: true, // 滚动后，bottom 部分（TabBar）是否固定在顶部
                flexibleSpace: const FlexibleSpaceBar(
                  title: Text("音乐库"),
                  titlePadding: EdgeInsetsDirectional.only(
                    // 调整标题位置避免重叠
                    start: 16,
                    bottom: 62,
                  ),
                ),
                bottom: const TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start, // 让 Tab 靠左对齐
                  tabs: [
                    Tab(text: "单曲"),
                    Tab(text: "专辑"),
                    Tab(text: "播放队列"),
                    Tab(text: "歌单"),
                  ],
                ),
              ),
            ];
          },
          body: TabBarView(
            children: [LibraryTab(), AlbumsTab(), QueueTab(), PlaylistTab()],
          ),
        ),
      ),
    );
  }
}
