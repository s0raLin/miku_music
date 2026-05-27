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
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _searchQuery = "";

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

  void _handleTagTap(String tag) {
    setState(() {
      _searchController.text = tag;
      _searchQuery = tag;
    });
    FocusScope.of(context).requestFocus(_focusNode);
  }

  @override
  Widget build(BuildContext context) {
    final musicProvider = context.watch<MusicProvider>();
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

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
            // 1. M3 标准 SearchBar 区域（已整合返回按钮）
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: SearchBar(
                controller: _searchController,
                focusNode: _focusNode,
                hintText: "搜索歌曲、歌手、专辑...",

                // 🌟 核心修改：将默认的搜索图标替换为符合路由返回逻辑的后退按钮
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () {
                    // 如果键盘醒着，先收起键盘防止顶起上一页的底栏
                    _focusNode.unfocus();
                    context.pop();
                  },
                ),

                trailing: [
                  if (_searchQuery.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        _searchController.clear();
                      },
                    ),
                ],
                elevation: WidgetStateProperty.all(0.0),
                backgroundColor: WidgetStateProperty.all(
                  cs.surfaceContainerHigh,
                ),
                padding: WidgetStateProperty.all(
                  const EdgeInsets.symmetric(
                    horizontal: 8.0,
                  ), // 👈 稍微调小一点，配合 IconButton 视觉更平衡
                ),
                shape: WidgetStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
              ),
            ),

            // 2. 动态内容区
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

  Widget _buildSuggestionsSection(TextTheme textTheme, ColorScheme cs) {
    return ListView(
      key: const ValueKey("suggestions"),
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          "搜索推荐",
          style: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: cs.primary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
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
