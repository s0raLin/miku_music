import 'package:myapp/model/Music/index.dart';

enum SongSortType { auto, nameAsc, nameDesc, artistAsc }

enum AlbumSortType { nameAsc, nameDesc, songCountDesc }

class LibraryService {
  List<Music> getSortedLibrary(
    List<Music> library, {
    SongSortType sortType = SongSortType.auto,
  }) {
    final list = List<Music>.from(library);
    switch (sortType) {
      case SongSortType.nameAsc:
        list.sort((a, b) => a.title.compareTo(b.title));
      case SongSortType.nameDesc:
        list.sort((a, b) => b.title.compareTo(a.title));
      case SongSortType.artistAsc:
        list.sort((a, b) => a.artist.compareTo(b.artist));
      case SongSortType.auto:
        break;
    }
    return list;
  }

  List<MapEntry<String, List<Music>>> getSortedAlbums(
    List<Music> library, {
    SongSortType songSortType = SongSortType.auto,
    AlbumSortType albumSortType = AlbumSortType.nameAsc,
  }) {
    final sortedSongs = getSortedLibrary(library, sortType: songSortType);
    final map = <String, List<Music>>{};

    for (final song in sortedSongs) {
      final albumName = song.album ?? "未知专辑";
      map.putIfAbsent(albumName, () => []).add(song);
    }

    final entries = map.entries.toList();
    switch (albumSortType) {
      case AlbumSortType.nameAsc:
        entries.sort((a, b) => a.key.compareTo(b.key));
      case AlbumSortType.nameDesc:
        entries.sort((a, b) => b.key.compareTo(a.key));
      case AlbumSortType.songCountDesc:
        entries.sort((a, b) => b.value.length.compareTo(a.value.length));
    }
    return entries;
  }

  /// Merge new scanned songs into existing library preserving cover & lyrics.
  List<Music> mergeLibrary(
    List<Music> existingLibrary,
    List<Music> scannedSongs,
  ) {
    final Map<String, Music> uniqueMap = {
      for (var song in existingLibrary) song.id: song,
    };

    for (var newSong in scannedSongs) {
      final oldSong = uniqueMap[newSong.id];
      if (oldSong != null) {
        final hasOldCover =
            oldSong.coverBytes != null && oldSong.coverBytes!.isNotEmpty;
        final hasNewCover =
            newSong.coverBytes != null && newSong.coverBytes!.isNotEmpty;

        if (hasOldCover && !hasNewCover) {
          uniqueMap[newSong.id] = newSong.copyWith(
            coverBytes: oldSong.coverBytes,
            lyrics: (newSong.lyrics == null || newSong.lyrics!.isEmpty)
                ? oldSong.lyrics
                : newSong.lyrics,
          );
          continue;
        }
      }
      uniqueMap[newSong.id] = newSong;
    }

    return uniqueMap.values.toList();
  }
}
