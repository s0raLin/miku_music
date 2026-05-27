import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/model/Music/index.dart';
import 'package:myapp/providers/MusicProvider/index.dart';
import 'package:provider/provider.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  // 🌟 核心控制器：控制输入框的文本、焦点以及主动赋值
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  String _searchQuery = "";

  // 💡 系统推荐的搜索建议标签列表
  final List<String> _suggestedTags = [
    "初音ミク",
    "VOCALOID",
    "八王子P",
    "Mitchie M",
    "DECO*27",
    "电音",
    "经典",
    "单曲循环",
  ];

  @override
  void initState() {
    super.initState();
    // 监听输入框文本变化，实时过滤内容
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// 🌟 联动核心：点击标签后，将文本塞入输入框，并聚焦
  void _handleTagTap(String tag) {
    setState(() {
      _searchController.text = tag;
      _searchQuery = tag;
    });
    // 让输入框重新获得焦点（唤起键盘）
    FocusScope.of(context).requestFocus(_focusNode);
  }

  @override
  Widget build(BuildContext context) {
    // 监听全局乐库，用于本地搜索过滤
    final musicProvider = context.watch<MusicProvider>();
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // 🔍 核心过滤逻辑：同时匹配歌名、艺术家、专辑名
    final filteredSongs = musicProvider.library.where((song) {
      if (_searchQuery.isEmpty) return false;
      final query = _searchQuery.toLowerCase();
      return song.title.toLowerCase().contains(query) ||
          song.artist.toLowerCase().contains(query) ||
          (song.album?.toLowerCase().contains(query) ?? false);
    }).toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. M3 标准 SearchBar 区域
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: SearchBar(
                controller: _searchController,
                focusNode: _focusNode,
                hintText: "搜索歌曲、歌手、专辑...",
                leading: const Icon(Icons.search_rounded),
                trailing: [
                  if (_searchQuery.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        _searchController.clear();
                      },
                    ),
                ],
                elevation: WidgetStateProperty.all(0),
                backgroundColor: WidgetStateProperty.all(
                  cs.surfaceContainerHigh,
                ),
                padding: WidgetStateProperty.all<EdgeInsetsGeometry>(
                  EdgeInsets.symmetric(horizontal: 16),
                ),
                shape: WidgetStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
              ),
            ),

            // 2. 动态内容区：未输入时显示“搜索建议”，输入后显示“搜索结果”
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _searchQuery.isEmpty
                    ? _buildSuggestionsSection(textTheme, cs)
                    : _buildResultsSection(
                        filteredSongs,
                        musicProvider,
                        cs,
                        textTheme,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 建议标签布局组件
  Widget _buildSuggestionsSection(TextTheme textTheme, ColorScheme cs) {
    return ListView(
      key: const ValueKey("suggestions"),
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          "推荐搜索",
          style: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: cs.primary,
          ),
        ),
        const SizedBox(height: 12),
        // 🌟 流式标签布局，自动换行
        Wrap(
          spacing: 8.0, // 左右间距
          runSpacing: 4.0, // 上下行间距
          children: _suggestedTags.map((tag) {
            return FilterChip(
              label: Text(tag),
              labelStyle: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
              backgroundColor: cs.surfaceContainerLow,
              side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              onSelected: (_) => _handleTagTap(tag),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// 搜索结果列表组件
  Widget _buildResultsSection(
    List<Music> results,
    MusicProvider musicProvider,
    ColorScheme cs,
    TextTheme textTheme,
  ) {
    if (results.isEmpty) {
      return Center(
        key: const ValueKey("empty_results"),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 48,
              color: cs.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              "未找到相关歌曲",
              style: textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      key: const ValueKey("results_list"),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final song = results[index];
        final isCurrent = musicProvider.currentMusic?.id == song.id;

        return ListTile(
          onTap: () {
            // 点击直接播放，并打开详情页
            musicProvider.playFromLibrary(song);
            context.push("/music-detail", extra: song);
          },
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 48,
              height: 48,
              color: cs.surfaceContainerHighest,
              child: song.coverBytes?.isNotEmpty == true
                  ? Image.memory(song.coverBytes!, fit: BoxFit.cover)
                  : Icon(Icons.music_note_rounded, color: cs.primary),
            ),
          ),
          title: Text(
            song.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
              color: isCurrent ? cs.primary : null,
            ),
          ),
          subtitle: Text(
            song.artist,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodySmall,
          ),
          trailing: const Icon(Icons.chevron_right_rounded, size: 20),
        );
      },
    );
  }
}
