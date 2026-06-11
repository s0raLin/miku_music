import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// Persisted network song metadata (JSON file in app's temp/persistent directory).
class NetworkSongMeta {
  final String id;
  final String title;
  final String artist;
  final String url;
  final String? coverUrl;
  final String? lyrics;
  final int durationMs;

  const NetworkSongMeta({
    required this.id,
    required this.title,
    required this.artist,
    required this.url,
    this.coverUrl,
    this.lyrics,
    this.durationMs = 0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'artist': artist,
    'url': url,
    'coverUrl': coverUrl,
    'lyrics': lyrics,
    'durationMs': durationMs,
  };

  factory NetworkSongMeta.fromJson(Map<String, dynamic> json) {
    return NetworkSongMeta(
      id: json['id'] as String,
      title: json['title'] as String? ?? '未知标题',
      artist: json['artist'] as String? ?? '未知歌手',
      url: json['url'] as String? ?? '',
      coverUrl: json['coverUrl'] as String?,
      lyrics: json['lyrics'] as String?,
      durationMs: (json['durationMs'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Persists network song metadata to a JSON file so app restarts
/// can restore previously played network songs (history & favorites).
class NetworkSongStore {
  NetworkSongStore._();

  static final NetworkSongStore _instance = NetworkSongStore._();
  factory NetworkSongStore() => _instance;

  Future<File> _getStoreFile() async {
    final dir = await getApplicationDocumentsDirectory();
    final networkDir = Directory(p.join(dir.path, 'network_cache'));
    if (!await networkDir.exists()) {
      await networkDir.create(recursive: true);
    }
    return File(p.join(networkDir.path, 'network_songs.json'));
  }

  /// Get the network cache directory path (also used as scan path).
  Future<String> getNetworkCacheDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final networkDir = Directory(p.join(dir.path, 'network_cache'));
    if (!await networkDir.exists()) {
      await networkDir.create(recursive: true);
    }
    return networkDir.path;
  }

  /// Add or update a network song's metadata, then persist to file.
  Future<void> upsert(NetworkSongMeta meta) async {
    try {
      final all = await loadAll();
      all.removeWhere((m) => m.id == meta.id);
      all.insert(0, meta); // most recent first
      await _saveAll(all);
      debugPrint('[NetworkSongStore] upsert ${meta.id} (total: ${all.length})');
    } catch (e) {
      debugPrint('[NetworkSongStore] upsert error: $e');
    }
  }

  /// Load all persisted network songs.
  Future<List<NetworkSongMeta>> loadAll() async {
    try {
      final file = await _getStoreFile();
      if (!await file.exists()) return [];
      final content = await file.readAsString();
      if (content.trim().isEmpty) return [];
      final list = jsonDecode(content) as List<dynamic>;
      return list
          .map((e) => NetworkSongMeta.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[NetworkSongStore] loadAll error: $e');
      return [];
    }
  }

  Future<void> _saveAll(List<NetworkSongMeta> metas) async {
    final file = await _getStoreFile();
    final json = jsonEncode(metas.map((m) => m.toJson()).toList());
    await file.writeAsString(json);
  }

  /// Remove a specific song.
  Future<void> remove(String id) async {
    final all = await loadAll();
    all.removeWhere((m) => m.id == id);
    await _saveAll(all);
  }

  /// Batch upsert: one file read + one write for all metas.
  Future<void> upsertAll(List<NetworkSongMeta> metas) async {
    if (metas.isEmpty) return;
    try {
      final all = await loadAll();
      for (final meta in metas) {
        all.removeWhere((m) => m.id == meta.id);
        all.insert(0, meta);
      }
      await _saveAll(all);
      debugPrint('[NetworkSongStore] upsertAll ${metas.length} songs (total: ${all.length})');
    } catch (e) {
      debugPrint('[NetworkSongStore] upsertAll error: $e');
    }
  }
}
