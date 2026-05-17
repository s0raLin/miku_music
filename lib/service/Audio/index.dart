import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:myapp/model/Music/index.dart';

class MyAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer();

  AudioPlayer get player => _player;

  MyAudioHandler() {
    // 转发播放器事件到 audio_service 的状态流中，供系统通知栏展现
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);
  }

  /// 供 Provider 调用：切换歌曲并播放
  Future<void> playMusic(MusicInfo music) async {
    
    // 1. 通知系统当前正在播放什么（这会在通知栏显示歌名和歌手）
    final item = MediaItem(
      id: music.id,
      album: music.album ?? "未知专辑",
      title: music.title,
      artist: music.artist,
      duration: music.duration, // 传入 Duration
      // 如果有封面图片字节，可以转换为内部 URI，这里暂时放空
    );
    mediaItem.add(item);

    // 2. 加载本地音频文件并播放
    try {
      await _player.setFilePath(music.id);
      play();
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

  /// 状态转换：将 just_audio 内部状态映射到系统的通知栏状态
  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 3],
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
