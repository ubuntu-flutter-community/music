import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:music/data/audio.dart';
import 'package:safe_change_notifier/safe_change_notifier.dart';

class PlayerModel extends SafeChangeNotifier {
  PlayerModel() : _audioPlayer = AudioPlayer();
  StreamSubscription<PlayerState>? _playerSub;
  StreamSubscription<Duration>? _durationSub;
  StreamSubscription<Duration>? _positionSub;

  Audio? _audio;
  Audio? get audio => _audio;
  set audio(Audio? value) {
    if (value == null || value == _audio) return;
    _audio = value;

    notifyListeners();
  }

  final AudioPlayer _audioPlayer;

  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;
  set isPlaying(bool value) {
    if (value == _isPlaying) return;
    _isPlaying = value;
    notifyListeners();
  }

  Duration? _duration;
  Duration? get duration => _duration;
  set duration(Duration? value) {
    if (value == _duration) return;
    _duration = value;
    notifyListeners();
  }

  Duration? _position;
  Duration? get position => _position;
  set position(Duration? value) {
    if (value == _position) return;
    _position = value;
    notifyListeners();
  }

  bool? _repeatSingle;
  bool? get repeatSingle => _repeatSingle;
  set repeatSingle(bool? value) {
    if (value == null || value == _repeatSingle) return;
    _repeatSingle = value;
    notifyListeners();
  }

  Future<void> play() async {
    if (audio == null) return;
    if (audio!.path != null) {
      await _audioPlayer.play(DeviceFileSource(audio!.path!));
      if (audio!.audioType != AudioType.radio) {
        repeatSingle = _repeatSingle ?? false;
      }
    } else if (audio!.url != null) {
      await _audioPlayer.play(UrlSource(audio!.url!));
    }
  }

  Future<void> pause() async {
    if (audio == null) return;
    await _audioPlayer.pause();
  }

  Future<void> seek() async {
    if (position == null) return;
    await _audioPlayer.seek(position!);
  }

  Future<void> resume() async {
    if (audio == null) return;
    await _audioPlayer.resume();
  }

  Future<void> init() async {
    _playerSub = _audioPlayer.onPlayerStateChanged.listen((playerState) {
      isPlaying = playerState == PlayerState.playing;
    });
    _audioPlayer.onDurationChanged.listen((newDuration) {
      duration = newDuration;
    });
    _audioPlayer.onPositionChanged.listen((newPosition) {
      position = newPosition;
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      _audioPlayer.release();
    });
    notifyListeners();
  }

  @override
  void dispose() {
    _playerSub?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }
}
