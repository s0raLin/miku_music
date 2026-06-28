/// 歌单搜索结果条目（来自 /api/search?type=playlist）
class NeteasePlaylistItem {
  final String id;
  final String title;
  final String creator;
  final String pic;
  final int playCount;
  final int trackCount;
  final String source;

  const NeteasePlaylistItem({
    required this.id,
    required this.title,
    required this.creator,
    required this.pic,
    required this.playCount,
    required this.trackCount,
    required this.source,
  });

  factory NeteasePlaylistItem.fromJson(Map<String, dynamic> json) {
    // playCount/trackCount 从 JSON 解析出来可能是 num 类型，需要用 toInt() 转换
    return NeteasePlaylistItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '未知歌单',
      creator: json['creator'] as String? ?? '未知创建者',
      pic: (json['pic'] as String? ?? '').replaceFirst('http://', 'https://'),
      playCount: (json['playCount'] as num?)?.toInt() ?? 0,
      trackCount: (json['trackCount'] as num?)?.toInt() ?? 0,
      source: json['source'] as String? ?? 'netease',
    );
  }
}

/// 歌单详情中的单首歌曲（来自 /api/playlist?id=xxx）
class NeteasePlaylistSong {
  final String id;
  final String title;
  final String author;
  final String pic;
  final String url;
  final String source;

  const NeteasePlaylistSong({
    required this.id,
    required this.title,
    required this.author,
    required this.pic,
    required this.url,
    required this.source,
  });

  factory NeteasePlaylistSong.fromJson(Map<String, dynamic> json) {
    // 后端返回的 url 是相对路径如 "/api/url?id=xxx&source=netease"
    // 实际播放时通过 NeteaseApi.getRealUrl(id) 获取真实链接，这里只存 id
    return NeteasePlaylistSong(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '未知歌名',
      author: json['author'] as String? ?? '未知歌手',
      pic: (json['pic'] as String? ?? '').replaceFirst('http://', 'https://'),
      url: json['url'] as String? ?? '',
      source: json['source'] as String? ?? 'netease',
    );
  }
}

/// 歌单详情（来自 /api/playlist?id=xxx）
class NeteasePlaylistDetail {
  final String playlistName;
  final int count;
  final List<NeteasePlaylistSong> songs;

  const NeteasePlaylistDetail({
    required this.playlistName,
    required this.count,
    required this.songs,
  });
}
