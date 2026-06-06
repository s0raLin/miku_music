class NeteaseSong {
  final String id;
  final String title;
  final String author;
  final String pic;
  final String url;
  final String source;

  const NeteaseSong({
    required this.id,
    required this.title,
    required this.author,
    required this.pic,
    required this.url,
    required this.source,
  });

  factory NeteaseSong.fromJson(Map<String, dynamic> json) {
    return NeteaseSong(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '未知歌名',
      author: json['author'] as String? ?? '未知歌手',
      pic: json['pic'] as String? ?? '',
      url: json['url'] as String? ?? '',
      source: json['source'] as String? ?? 'netease',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'pic': pic,
      'url': url,
      'source': source,
    };
  }
}
