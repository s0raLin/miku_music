import 'package:flutter/material.dart';
import 'package:myapp/api/Client/Music/index.dart';
import 'package:myapp/api/Model/Music/index.dart';
import 'package:myapp/components/Shared/index.dart';

class NetWorkPage extends StatefulWidget {
  const NetWorkPage({super.key});

  @override
  State<NetWorkPage> createState() => _NetWorkPageState();
}

class _NetWorkPageState extends State<NetWorkPage> {
  List<Music> musics = [];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(title: Text("网络")),
          SliverToBoxAdapter(
            child: Center(
              child: TextButton(
                onPressed: () async {
                  List<Music> result;
                  try {
                    result = await MusicApi.listMusic();
                  } catch (e) {
                    if (!mounted) return;
                    AppToast.error(
                      context,
                      message: e.toString(),
                      title: '同步失败',
                    );
                    return;
                  }
                  if (!mounted) return;
                  setState(() {
                    musics = result;
                  });
                  AppToast.success(
                    context,
                    message: '已加载 ${musics.length} 首歌曲',
                    title: '同步完成',
                  );
                },
                child: Text("获取"),
              ),
            ),
          ),
          SliverList.builder(
            itemCount: musics.length,
            itemBuilder: (context, index) {
              final music = musics[index];
              return ListTile(
                leading: music.coverUrl != null && music.coverUrl!.isNotEmpty
                    ? ImageIcon(NetworkImage(music.coverUrl!))
                    : Icon(Icons.music_note_rounded),
                title: Text(music.title),
                subtitle: Text("${music.artist}-${music.album}"),
              );
            },
          ),
        ],
      ),
    );
  }
}
