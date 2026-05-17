import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:myapp/model/Music/index.dart';
import 'package:myapp/service/Music/index.dart';

class MyAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  AudioPlayer get player => _player;

  MyAudioHandler() {
    // 转发播放器事件到 audio_service 的状态流中
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);
  }

  /// 供 Provider 调用：切换歌曲并播放
  Future<void> playMusic(MusicInfo music) async {
    final uri = await MusicService.getAudioServiceCoverFromBytes(music.coverBytes, music.id);
    final item = MediaItem(
      id: music.id,
      album: music.album ?? "未知专辑",
      title: music.title,
      artist: music.artist,
      duration: music.duration,
      artUri: uri,
    );

    mediaItem.add(item);

    try {
      await _player.setFilePath(music.id);
      await play();
    } catch (e) {
      playbackState.add(
        playbackState.value.copyWith(errorMessage: e.toString()),
      );
    }
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() async {
    await _player.stop();
    await playbackState.firstWhere(
      (state) => state.processingState == AudioProcessingState.idle,
    );
  }

  /// 状态转换
  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious, // 上一首
        if (_player.playing) MediaControl.pause else MediaControl.play, // 播放/暂停
        MediaControl.skipToNext, // 下一首
        // MediaControl.stop,   // ← 已移除，不再显示停止按钮
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 2], // 紧凑模式显示前3个按钮
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    );
  }
}
