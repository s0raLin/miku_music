import 'dart:math';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:myapp/model/Music/index.dart';

import 'package:rxdart/rxdart.dart';

class PositionData {
  final Duration position;
  final Duration bufferedPosition;
  final Duration duration;

  PositionData(this.position, this.bufferedPosition, this.duration);
}

enum PlayMode { sequence, shuffle, repeat }

//区分点击还是自动切歌
enum PlayTrigger { user, auto }

class MusicProvider extends ChangeNotifier {
  //私有播放器实例
  final AudioPlayer player = AudioPlayer();

  // 歌曲库
  List<MusicInfo> _library = [];
  List<MusicInfo> get library => _library;
  // 全局播放队列
  List<MusicInfo> _queue = [];
  int _currentIndex = -1;

  List<MusicInfo> get queue => _queue;

  //添加到队尾
  void addToQueue(MusicInfo music) {
    _queue.add(music);
    notifyListeners();
  }

  //从队尾移除
  void remoteFromQueue(int index) {
    if (index == _currentIndex) return; //不能删除当前播放的
    _queue.removeAt(index);
    if (index < _currentIndex) _currentIndex--; //维护当前index
    notifyListeners();
  }

  //清空队列
  void clearQueue() {
    _queue.clear();
    _currentIndex = -1;
    player.stop();
    notifyListeners();
  }

  void playFromLibrary(MusicInfo music) {
    //检查是否在队列里
    final existingIndex = _queue.indexWhere((m) => m.id == music.id);

    if (existingIndex != -1) {
      //已经在队列,直接跳过
      playByIndex(existingIndex);
    } else {
      //不在队列,加入队尾再播放
      _queue.add(music);
      playByIndex(_queue.length - 1);
    }
  }

  Future<void> playMusic(String path, {shouldPlay = true}) async {
    try {
      //停止当前播放,清理状态
      await player.stop();

      //加载新路径
      await player.setFilePath(path);

      //播放
      if (shouldPlay) {
        player.play();
      }
    } catch (e) {
      return;
    }
  }

  //当前正在播放的音乐信息

  //当前正在播放的音乐对象
  MusicInfo? get currentMusic {
    if (_currentIndex < 0 || _currentIndex >= _queue.length) {
      return null;
    }
    return _queue[_currentIndex];
  }

  //切换播放/暂停
  void togglePlay() {
    if (player.playing) {
      player.pause();
    } else {
      player.play();
    }
    notifyListeners(); //触发监听
  }

  PlayMode _playMode = PlayMode.sequence;
  PlayMode get playMode => _playMode;

  // 切换三种模式
  void togglePlayMode() {
    _playMode = switch (_playMode) {
      PlayMode.sequence => PlayMode.shuffle,
      PlayMode.shuffle => PlayMode.repeat,
      PlayMode.repeat => PlayMode.sequence,
    };
    notifyListeners();
  }

  Future playByIndex(int index) async {
    if (index < 0 || index >= _queue.length) return;
    _currentIndex = index;
    notifyListeners();

    final path = _queue[index].id;
    await player.setFilePath(path);
    player.play();
  }

  Future<void> _playNext({PlayTrigger trigger = PlayTrigger.auto}) async {
    if (_queue.isEmpty) return;

    switch (_playMode) {
      case PlayMode.repeat:
        if (trigger == PlayTrigger.user) {
          // 用户点击下一首
          await playByIndex((_currentIndex + 1) % _queue.length);
        } else {
          //单曲循环
          await player.seek(Duration.zero);
          player.play();
        }
        break;
      case PlayMode.shuffle:
        //随机,排除当前index
        final candidates = List.generate(_queue.length, (i) => i)
          ..remove(_currentIndex);
        if (candidates.isEmpty) return;
        await playByIndex(candidates[Random().nextInt(candidates.length)]);
        break;
      case PlayMode.sequence:
        // 顺序 到最后一首就停
        if (_currentIndex < _queue.length - 1) {
          await playByIndex(_currentIndex + 1);
        } else {
          if (trigger == PlayTrigger.user) {
            // 跳到第一首
            await playByIndex(0);
          } else {
            await player.seek(Duration.zero); //自动停下
          }
        }
        break;
    }
  }

  Future<void> _playPrev() async {
    if (_queue.isEmpty) return;

    if (_currentIndex > 0) {
      await playByIndex(_currentIndex - 1);
    } else {
      await playByIndex(_queue.length - 1); //第一首跳到最后一首
    }
  }

  MusicProvider() {
    player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) _playNext();
    });
  }

  Stream<PositionData> get positionDataStream =>
      Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
        player.positionStream, // 当前播放位置
        player.bufferedPositionStream, // 缓冲位置
        player.durationStream, // 总时长
        (position, bufferedPosition, duration) => // 输出
            PositionData(position, bufferedPosition, duration ?? Duration.zero),
      );
}
