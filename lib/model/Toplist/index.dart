class ToplistItem {
  final String id;
  final String title;
  final String author;
  final String pic;
  final String url;
  final String source;

  const ToplistItem({
    required this.id,
    required this.title,
    required this.author,
    required this.pic,
    required this.url,
    required this.source,
  });

  factory ToplistItem.fromJson(Map<String, dynamic> json) {
    return ToplistItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      author: json['author']?.toString() ?? '',
      pic: json['pic']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
      source: json['source']?.toString() ?? 'netease',
    );
  }
}

class ToplistInfo {
  final String title;
  final String description;
  final String cover;
  final int count;
  final List<ToplistItem> items;

  const ToplistInfo({
    required this.title,
    required this.description,
    required this.cover,
    required this.count,
    required this.items,
  });

  factory ToplistInfo.fromJson(Map<String, dynamic> json) {
    final dataList = json['data'] as List<dynamic>? ?? [];
    return ToplistInfo(
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      cover: json['cover']?.toString() ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
      items: dataList.map((e) => ToplistItem.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}
