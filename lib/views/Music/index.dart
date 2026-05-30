import 'package:flutter/material.dart';
import 'package:myapp/components/Header/index.dart';
import 'package:myapp/model/Music/index.dart';
import 'package:myapp/providers/MusicProvider/index.dart';
import 'package:myapp/views/Music/tabs/library_tab.dart';
import 'package:myapp/views/Music/tabs/playlist_tab.dart';
import 'package:provider/provider.dart';

// 抽取排序枚举到两边都能访问到的地方
enum MusicSortType { defaultOrder, name }

class MusicPage extends StatefulWidget {
  const MusicPage({super.key});

  @override
  State<MusicPage> createState() => _MusicPageState();
}

class _MusicPageState extends State<MusicPage> {
  // 创建一个通知器，用来监听和传递排序状态
  final ValueNotifier<MusicSortType> _sortNotifier = ValueNotifier(
    MusicSortType.defaultOrder,
  );

  @override
  void dispose() {
    _sortNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 获取歌曲数据供给搜索使用
    final library = context.select<MusicProvider, List<Music>>(
      (p) => p.library,
    );

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              Header(
                expandedHeight: 120.0,
                floating: false,
                pinned: true,
                flexibleSpace: const FlexibleSpaceBar(
                  title: const Text("我的音乐"),
                  titlePadding: const EdgeInsetsDirectional.only(
                    start: 16,
                    bottom: 62,
                  ),
                ),
                // ✨ 核心改动：把按钮加到外层统一的 Header actions 中
                actions: [
                  // 1. 弹出式搜索
                  IconButton(
                    icon: const Icon(Icons.search_rounded),
                    onPressed: () {
                      showSearch(
                        context: context,
                        delegate: MusicSearchDelegate(library: library),
                      );
                    },
                  ),

                  // 2. 排序弹出菜单
                  ValueListenableBuilder<MusicSortType>(
                    valueListenable: _sortNotifier,
                    builder: (context, currentSort, _) {
                      return PopupMenuButton<MusicSortType>(
                        icon: const Icon(Icons.sort_rounded),
                        onSelected: (MusicSortType type) {
                          _sortNotifier.value = type; // 改变排序状态，通知子页面
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: MusicSortType.defaultOrder,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.history,
                                  size: 20,
                                  color:
                                      currentSort == MusicSortType.defaultOrder
                                      ? Theme.of(context).primaryColor
                                      : null,
                                ),
                                const SizedBox(width: 8),
                                const Text('默认排序'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: MusicSortType.name,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.sort_by_alpha,
                                  size: 20,
                                  color: currentSort == MusicSortType.name
                                      ? Theme.of(context).primaryColor
                                      : null,
                                ),
                                const SizedBox(width: 8),
                                const Text('按名称排序'),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(width: 4),
                ],
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
          // ✨ 将排序通知器传给 LibraryTab
          body: TabBarView(
            children: [
              LibraryTab(sortNotifier: _sortNotifier),
              const PlaylistTab(),
            ],
          ),
        ),
      ),
    );
  }
}
