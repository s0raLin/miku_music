import 'dart:typed_data';

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/api/Client/index.dart';
import 'package:myapp/model/Playlist/index.dart';
import 'package:myapp/model/Music/index.dart';
import 'package:myapp/providers/MusicProvider/index.dart';
import 'package:provider/provider.dart';

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
        appBar: AppBar(
          title: const Text("音乐库"),
          bottom: const TabBar(
            tabs: [
              Tab(text: "单曲"),
              Tab(text: "专辑"),
              Tab(text: "播放队列"),
              Tab(text: "歌单"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildLibraryTab(),
            _buildAlbumsTab(),
            _buildQueueTab(),
            _buildPlaylistsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? action,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
          if (action != null) ...[const SizedBox(height: 16), action],
        ],
      ),
    );
  }

  Widget _buildLibraryTab() {
    final musicProvider = context.watch<MusicProvider>();
    final library = musicProvider.library;

    return RefreshIndicator(
      onRefresh: () async {},
      child: library.isEmpty
          ? _buildEmptyState(
              icon: Icons.music_note_rounded,
              title: "还没有歌曲",
              subtitle: "点击下方按钮上传歌曲开始使用",
              action: FilledButton.icon(
                onPressed: () => MusicApi.pickAndUploadMusic(),
                icon: const Icon(Icons.upload_rounded),
                label: const Text("上传歌曲"),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: library.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final music = library[index];
                return _SongTile(
                  music: music,
                  isCurrent: music.id == musicProvider.currentMusic?.id,
                  onTap: () {
                    musicProvider.playFromLibrary(music);
                    context.push("/music-detail", extra: music);
                  },
                );
              },
            ),
    );
  }

  Widget _buildAlbumsTab() {
    final musicProvider = context.watch<MusicProvider>();
    final library = musicProvider.library;

    // Group songs by album
    final albumsMap = <String, List<MusicInfo>>{};
    for (final song in library) {
      final albumName = song.album ?? "未知专辑";
      albumsMap.putIfAbsent(albumName, () => []).add(song);
    }

    final albums = albumsMap.entries.toList();

    return RefreshIndicator(
      onRefresh: () async {},
      child: albums.isEmpty
          ? _buildEmptyState(
              icon: Icons.album_rounded,
              title: "还没有专辑",
              subtitle: "上传歌曲后会自动归类到专辑",
            )
          : GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.9,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: albums.length,
              itemBuilder: (context, index) {
                final entry = albums[index];
                final albumName = entry.key;
                final songs = entry.value;
                final cover = songs
                    .firstWhere(
                      (s) => s.coverBytes != null && s.coverBytes!.isNotEmpty,
                      orElse: () => songs.first,
                    )
                    .coverBytes;

                return _AlbumCard(
                  albumName: albumName,
                  songCount: songs.length,
                  coverBytes: cover,
                  onTap: () {
                    context.push(
                      "/user/files/album-detail",
                      extra: {'albumName': albumName, 'songs': songs},
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildQueueTab() {
    final musicProvider = context.watch<MusicProvider>();
    final queue = musicProvider.queue;

    return RefreshIndicator(
      onRefresh: () async {},
      child: queue.isEmpty
          ? _buildEmptyState(
              icon: Icons.queue_music_rounded,
              title: "播放队列为空",
              subtitle: "从歌曲库或歌单中添加歌曲到队列",
            )
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: queue.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final music = queue[index];
                final isCurrent = music.id == musicProvider.currentMusic?.id;
                return Card(
                  color: isCurrent
                      ? Theme.of(context).colorScheme.secondaryContainer
                      : null,
                  child: ListTile(
                    selected: isCurrent,
                    onTap: () {
                      musicProvider.playFromLibrary(music);
                      context.push("/music-detail", extra: music);
                    },
                    leading: Container(
                      width: 50,
                      height: 50,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: music.coverBytes != null
                          ? Image.memory(music.coverBytes!, fit: BoxFit.cover)
                          : const Icon(Icons.music_note_rounded),
                    ),
                    title: Text(
                      music.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: isCurrent
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(
                      music.artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      onPressed: () {
                        context.read<MusicProvider>().removeFromQueue(index);
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildPlaylistsTab() {
    final musicProvider = context.watch<MusicProvider>();
    final userPlaylists = musicProvider.userPlaylists;
    final favorites = musicProvider.favoritesPlaylist;

    return RefreshIndicator(
      onRefresh: () async {},
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (favorites != null)
              _PlaylistCard(
                playlist: favorites,
                songCount: musicProvider.favList.length,
                onTap: () => context.push("/favorites"),
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "我的歌单",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                TextButton.icon(
                  onPressed: () => _showCreatePlaylistDialog(context),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text("新建"),
                ),
              ],
            ),
            const SizedBox(height: 8),
            userPlaylists.isEmpty
                ? _buildEmptyState(
                    icon: Icons.playlist_play_rounded,
                    title: "还没有歌单",
                    subtitle: "创建自己的歌单来整理喜欢的歌曲",
                  )
                : Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: userPlaylists
                        .map(
                          (playlist) => _PlaylistCard(
                            playlist: playlist,
                            songCount: playlist.songIds.length,
                            onTap: () =>
                                context.push("/playlist/${playlist.id}"),
                          ),
                        )
                        .toList(),
                  ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCreatePlaylistDialog(BuildContext context) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("新建歌单"),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: "歌单名称"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("取消"),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text("创建"),
          ),
        ],
      ),
    );

    if (name != null && name.isNotEmpty) {
      context.read<MusicProvider>().createPlaylist(name);
    }
  }
}

// Song list tile
class _SongTile extends StatelessWidget {
  final MusicInfo music;
  final bool isCurrent;
  final VoidCallback onTap;

  const _SongTile({
    required this.music,
    required this.isCurrent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      color: isCurrent ? colorScheme.secondaryContainer : null,
      child: ListTile(
        selected: isCurrent,
        onTap: onTap,
        leading: Container(
          width: 50,
          height: 50,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
          child: music.coverBytes != null && music.coverBytes!.isNotEmpty
              ? Image.memory(music.coverBytes!, fit: BoxFit.cover)
              : Icon(Icons.music_note_rounded, color: colorScheme.primary),
        ),
        title: Text(
          music.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          music.artist,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

// Album card
class _AlbumCard extends StatelessWidget {
  final String albumName;
  final int songCount;
  final Uint8List? coverBytes;
  final VoidCallback onTap;

  const _AlbumCard({
    required this.albumName,
    required this.songCount,
    this.coverBytes,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                color: colorScheme.surfaceContainerHighest,
                child: Center(
                  child: coverBytes != null && coverBytes!.isNotEmpty
                      ? Image.memory(coverBytes!, fit: BoxFit.cover)
                      : Icon(
                          Icons.album_rounded,
                          size: 48,
                          color: colorScheme.primary,
                        ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    albumName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "$songCount 首",
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Playlist card (existing)
class _PlaylistCard extends StatelessWidget {
  final Playlist playlist;
  final int songCount;
  final VoidCallback onTap;

  const _PlaylistCard({
    required this.playlist,
    required this.songCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 140,
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 140,
                width: double.infinity,
                color: colorScheme.surfaceContainerHighest,
                child: Center(
                  child:
                      playlist.coverBytes != null &&
                          playlist.coverBytes!.isNotEmpty
                      ? Image.memory(playlist.coverBytes!, fit: BoxFit.cover)
                      : Icon(
                          Icons.playlist_play_rounded,
                          size: 48,
                          color: colorScheme.primary,
                        ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      playlist.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "$songCount 首",
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
