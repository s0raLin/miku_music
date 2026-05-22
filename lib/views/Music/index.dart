import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/views/Music/widgets/library_tab.dart'; // 整合后的乐库
import 'package:myapp/views/Music/widgets/playlist_tab.dart';

class MusicPage extends StatefulWidget {
  const MusicPage({super.key});

  @override
  State<MusicPage> createState() => _MusicPageState();
}

class _MusicPageState extends State<MusicPage> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // 从 4 个缩减到 2 个
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 120.0,
                floating: false,
                pinned: true,
                flexibleSpace: const FlexibleSpaceBar(
                  title: Text("我的音乐"),
                  titlePadding: EdgeInsetsDirectional.only(
                    start: 16,
                    bottom: 62,
                  ),
                ),
                bottom: const TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  tabs: [
                    Tab(text: "乐库"), // 包含原单曲和专辑
                    Tab(text: "歌单"), // 包含原歌单和收藏
                  ],
                ),
                actions: [
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) {
                      if (value == "edit") {
                        context.push("/user/edit-profile");
                      }
                    },
                    itemBuilder: (BuildContext context) => [
                      const PopupMenuItem(
                        value: "share",
                        child: ListTile(
                          leading: Icon(Icons.share_outlined),
                          title: Text('分享'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit),
                          title: Text('编辑'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ];
          },
          body: const TabBarView(
            children: [
              LibraryTab(),
              PlaylistTab(), 
            ],
          ),
        ),
      ),
    );
  }
}
