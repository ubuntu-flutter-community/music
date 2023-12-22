import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:mpris_service/mpris_service.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:smtc_windows/smtc_windows.dart';

import '../../constants.dart';
import '../../data.dart';
import '../../library.dart';
import '../../player.dart';
import '../../utils.dart';
import 'my_audio_handler.dart';

class PlayerService {
  PlayerService({
    required this.player,
    required this.controller,
    required this.libraryService,
  });

  final Player player;
  final VideoController controller;
  final LibraryService libraryService;

  MPRIS? _mpris;
  SMTCWindows? _smtc;
  MyAudioHandler? _audioService;

  StreamSubscription<PressedButton>? _smtcSub;
  StreamSubscription<bool>? _isPlayingSub;
  StreamSubscription<Duration>? _durationSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<bool>? _isCompletedSub;
  StreamSubscription<double>? _volumeSub;

  final _queueController = StreamController<bool>.broadcast();
  Stream<bool> get queueChanged => _queueController.stream;
  (String, List<Audio>) _queue = ('', []);
  (String, List<Audio>) get queue => _queue;
  void setQueue((String, List<Audio>) value) {
    if (value == _queue || value.$2.isEmpty) return;
    _queue = value;
    _queueController.add(true);
  }

  final _mpvMetaDataController = StreamController<bool>.broadcast();
  Stream<bool> get mpvMetaDataChanged => _mpvMetaDataController.stream;
  MpvMetaData? _mpvMetaData;
  MpvMetaData? get mpvMetaData => _mpvMetaData;
  void setMpvMetaData(MpvMetaData value) {
    if (value == _mpvMetaData) return;
    _mpvMetaData = value;
    _mpvMetaDataController.add(true);
  }

  final _audioController = StreamController<bool>.broadcast();
  Stream<bool> get audioChanged => _audioController.stream;
  Audio? _audio;
  Audio? get audio => _audio;
  Future<void> _setAudio(Audio? value) async {
    if (value == null || value == _audio) return;
    _audio = value;
    libraryService.setLastAudio(value);
    _setIsVideo();

    _audioController.add(true);
  }

  final _isVideoController = StreamController<bool>.broadcast();
  Stream<bool> get isVideoChanged => _isVideoController.stream;
  void _setIsVideo() {
    _isVideo = false;
    for (var t in _videoTypes) {
      if (audio?.url?.contains(t) == true) {
        _isVideo = true;
        break;
      }
    }
  }

  bool? _isVideo;
  bool? get isVideo => _isVideo;
  void setIsVideo(bool? value) {
    if (value == _isVideo) return;
    _isVideo = value;
    _isVideoController.add(true);
  }

  final _nextAudioController = StreamController<bool>.broadcast();
  Stream<bool> get nextAudioChanged => _nextAudioController.stream;
  Audio? _nextAudio;
  Audio? get nextAudio => _nextAudio;
  set nextAudio(Audio? value) {
    if (value == null || value == _nextAudio) return;
    _nextAudio = value;
    _nextAudioController.add(true);
  }

  final _isPlayingController = StreamController<bool>.broadcast();
  Stream<bool> get isPlayingChanged => _isPlayingController.stream;
  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;
  void setIsPlaying(bool value) {
    if (value == _isPlaying) return;
    _isPlaying = value;
    _isPlayingController.add(true);
    _setMediaControlsIsPlaying(value);
  }

  final _durationController = StreamController<bool>.broadcast();
  Stream<bool> get durationChanged => _durationController.stream;
  Duration? _duration;
  Duration? get duration => _duration;
  void setDuration(Duration? value) {
    if (value?.inSeconds == _duration?.inSeconds) return;
    _duration = value;
    libraryService.setDuration(value);
    _durationController.add(true);
    _setMediaControlDuration(value);
  }

  final _positionController = StreamController<bool>.broadcast();
  Stream<bool> get positionChanged => _positionController.stream;
  Duration? _position = Duration.zero;
  Duration? get position => _position;
  void setPosition(Duration? value) {
    if (position?.inSeconds == value?.inSeconds) return;
    _position = value;
    libraryService.setPosition(value);
    _positionController.add(true);
    _setMediaControlPosition(value);
  }

  final _repeatSingleController = StreamController<bool>.broadcast();
  Stream<bool> get repeatSingleChanged => _repeatSingleController.stream;
  bool _repeatSingle = false;
  bool get repeatSingle => _repeatSingle;
  void setRepeatSingle(bool value) {
    if (value == _repeatSingle) return;
    _repeatSingle = value;
    _estimateNext();
    _repeatSingleController.add(true);
  }

  final _shuffleController = StreamController<bool>.broadcast();
  Stream<bool> get shuffleChanged => _shuffleController.stream;
  bool _shuffle = false;
  bool get shuffle => _shuffle;
  void setShuffle(bool value) {
    if (value == _shuffle) return;
    _shuffle = value;
    if (value && queue.$2.length > 1) {
      _randomNext();
    }
    _shuffleController.add(true);
  }

  final _volumeController = StreamController<bool>.broadcast();
  Stream<bool> get volumeChanged => _volumeController.stream;
  double _volume = 100.0;
  double get volume => _volume;
  Future<void> setVolume(double value) async {
    if (value == _volume) return;
    await player.setVolume(value);
  }

  bool _firstPlay = true;
  Future<void> play({Duration? newPosition, Audio? newAudio}) async {
    final currentIndex =
        (audio == null || queue.$2.isEmpty || !queue.$2.contains(audio!))
            ? 0
            : queue.$2.indexOf(audio!);
    if (newAudio != null) {
      _setAudio(newAudio);
    }
    if (audio == null) return;

    if (!queue.$2.contains(audio)) {
      queue.$2.insert(currentIndex, audio!);
      if (queue.$2.length > 1) {
        nextAudio = queue.$2[1];
      }
    }
    final playList = Playlist([
      if (audio!.path != null)
        Media('file://${audio!.path!}')
      else if (audio!.url != null)
        Media(audio!.url!),
    ]);

    player.open(playList);
    if (newPosition != null && _audio!.audioType != AudioType.radio) {
      player.setVolume(0).then(
            (_) => Future.delayed(const Duration(seconds: 3)).then(
              (_) =>
                  player.seek(newPosition).then((_) => player.setVolume(100.0)),
            ),
          );
    }
    _setMediaControlsMetaData(audio!);
    _loadColor();
    _firstPlay = false;
  }

  Future<void> playOrPause() async {
    return _firstPlay ? play(newPosition: _position) : player.playOrPause();
  }

  Future<void> pause() async {
    await player.pause();
  }

  Future<void> seek() async {
    if (position == null) return;
    await player.seek(position!);
  }

  Future<void> resume() async {
    if (audio == null) return;
    await player.playOrPause();
  }

  Future<void> init() async {
    await _initMediaControl();

    await _readPlayerState();

    _isPlayingSub = player.stream.playing.listen((value) {
      setIsPlaying(value);
    });

    _durationSub = player.stream.duration.listen((newDuration) {
      setDuration(newDuration);
    });

    _positionSub = player.stream.position.listen((newPosition) {
      setPosition(newPosition);
    });

    _isCompletedSub = player.stream.completed.listen((value) async {
      if (value) {
        await playNext();
      }
    });

    await (player.platform as NativePlayer).observeProperty(
      'metadata',
      (data) async => setMpvMetaData(MpvMetaData.fromJson(data)),
    );

    _volumeSub = player.stream.volume.listen((value) {
      _volume = value;
      _volumeController.add(true);
    });
  }

  Future<void> playNext() async {
    safeLastPosition();
    if (!repeatSingle && nextAudio != null) {
      _setAudio(nextAudio);
      _estimateNext();
    }
    await play();
  }

  Future<void> insertIntoQueue(Audio audio) async {
    if (_queue.$2.isNotEmpty && !_queue.$2.contains(audio) && _audio != null) {
      final currentIndex = queue.$2.indexOf(_audio!);
      _queue.$2.insert(currentIndex + 1, audio);
      nextAudio = queue.$2[currentIndex + 1];
    }
  }

  void _estimateNext() {
    if (audio == null) return;

    if (queue.$2.isNotEmpty == true && queue.$2.contains(audio)) {
      final currentIndex = queue.$2.indexOf(audio!);

      if (shuffle && queue.$2.length > 1) {
        _randomNext();
      } else {
        if (currentIndex == queue.$2.length - 1) {
          nextAudio = queue.$2.elementAt(0);
        } else {
          nextAudio = queue.$2.elementAt(queue.$2.indexOf(audio!) + 1);
        }
      }
    }
  }

  void _randomNext() {
    if (audio == null) return;
    final currentIndex = queue.$2.indexOf(audio!);
    final max = queue.$2.length;
    final random = Random();
    var randomIndex = random.nextInt(max);
    while (randomIndex == currentIndex) {
      randomIndex = random.nextInt(max);
    }
    nextAudio = queue.$2.elementAt(randomIndex);
  }

  Future<void> playPrevious() async {
    if (queue.$2.isNotEmpty == true &&
        audio != null &&
        queue.$2.contains(audio)) {
      final currentIndex = queue.$2.indexOf(audio!);

      if (currentIndex == 0) {
        return;
      }
      _setAudio(queue.$2.elementAt(currentIndex - 1));
      nextAudio = queue.$2.elementAt(queue.$2.indexOf(audio!) + 1);

      await play();
    }
  }

  Future<void> startPlaylist(Set<Audio> audios, String listName) async {
    setQueue((listName, audios.toList()));
    _setAudio(audios.first);
    _position = libraryService.getLastPosition.call(_audio?.url);
    _estimateNext();
    await play(newPosition: _position);
  }

  Color? _color;
  Color? get color => _color;

  Future<void> _loadColor() async {
    if (audio == null) return;
    if (audio?.path != null && audio?.pictureData != null) {
      final image = MemoryImage(
        audio!.pictureData!,
      );
      final generator = await PaletteGenerator.fromImageProvider(image);
      _color = generator.dominantColor?.color;
    } else {
      if (audio?.imageUrl == null && audio?.albumArtUrl == null) return;

      final image = NetworkImage(
        audio!.imageUrl ?? audio!.albumArtUrl!,
      );
      final generator = await PaletteGenerator.fromImageProvider(image);
      _color = generator.dominantColor?.color;
    }
  }

  Future<void> _readPlayerState() async {
    final playerState = await libraryService.readPlayerState();

    if (playerState.$1 != null) {
      setPosition(playerState.$1!);
    }
    if (playerState.$2 != null) {
      setDuration(playerState.$2);
    }
    if (playerState.$3 != null) {
      _audio = playerState.$3;

      if (_audio != null) {
        await _setMediaControlsMetaData(audio!);
      }
      _setIsVideo();
    }
  }

  void safeLastPosition() {
    if (_audio?.audioType == AudioType.radio ||
        _audio?.url == null ||
        _position == null) return;
    libraryService.addLastPosition(_audio!.url!, _position!);
  }

  Future<void> _initMediaControl() async {
    if (Platform.isLinux) {
      await _initMpris();
    } else if (Platform.isWindows) {
      _initSmtc();
    } else if (Platform.isAndroid || Platform.isMacOS) {
      await _initAudioService();
    }
  }

  void _initSmtc() {
    _smtc = SMTCWindows(
      enabled: true,
      config: const SMTCConfig(
        fastForwardEnabled: false,
        nextEnabled: true,
        pauseEnabled: true,
        playEnabled: true,
        rewindEnabled: false,
        prevEnabled: true,
        stopEnabled: false,
      ),
    );

    _smtcSub = _smtc?.buttonPressStream.listen((event) {
      switch (event) {
        case PressedButton.play:
          playOrPause().then(
            (_) => _smtc?.setPlaybackStatus(
              _isPlaying ? PlaybackStatus.Playing : PlaybackStatus.Paused,
            ),
          );
          break;
        case PressedButton.pause:
          playOrPause().then(
            (_) => _smtc?.setPlaybackStatus(
              _isPlaying ? PlaybackStatus.Playing : PlaybackStatus.Paused,
            ),
          );
          break;
        case PressedButton.next:
          playNext();
          break;
        case PressedButton.previous:
          playPrevious();
          break;
        default:
          break;
      }
    });
  }

  Future<void> _initMpris() async {
    _mpris = await MPRIS.create(
      busName: kBusName,
      identity: kAppName,
      desktopEntry: kDesktopEntry,
    );
    _mpris?.setEventHandler(
      MPRISEventHandler(
        playPause: () async {
          _mpris?.playbackStatus == MPRISPlaybackStatus.playing
              ? pause()
              : playOrPause();
        },
        play: () async {
          play();
        },
        pause: () async {
          pause();
        },
        next: () async {
          playNext();
        },
        previous: () async {
          playPrevious();
        },
      ),
    );
  }

  Future<void> _initAudioService() async {
    _audioService = await AudioService.init(
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'org.feichtmeier.musicpod.channel.audio',
        androidNotificationChannelName: 'MusicPod',
      ),
      builder: () {
        return MyAudioHandler(
          onPlay: playOrPause,
          onNext: playNext,
          onPause: pause,
          onPrevious: playPrevious,
          onSeek: (position) async {
            setPosition(position);
            await seek();
          },
        );
      },
    );
    if (_audioService == null) return;
    _audioService!.playbackState.add(
      PlaybackState(
        playing: false,
        systemActions: {
          MediaAction.seek,
          MediaAction.seekBackward,
          MediaAction.seekForward,
        },
        controls: [
          MediaControl.skipToPrevious,
          MediaControl.rewind,
          MediaControl.play,
          MediaControl.fastForward,
          MediaControl.skipToNext,
        ],
      ),
    );
  }

  void _setMediaControlPosition(Duration? position) {
    if (_audioService == null) return;
    _audioService!.playbackState.add(
      _audioService!.playbackState.value.copyWith(
        updatePosition: position ?? Duration.zero,
      ),
    );
  }

  void _setMediaControlDuration(Duration? duration) {
    if (_audioService == null || _audioService!.mediaItem.value == null) return;
    _audioService!.mediaItem
        .add(_audioService!.mediaItem.value!.copyWith(duration: duration));
  }

  Future<void> _setMediaControlsMetaData(Audio audio) async {
    final uri = await createUriFromAudio(audio);

    _setMprisMetadata(audio, uri);
    _setSmtcMetaData(audio, uri);
    _setAudioServiceMetaData(audio, uri);
  }

  Future<void> _setMediaControlsIsPlaying(bool playing) async {
    _mpris?.playbackStatus =
        playing ? MPRISPlaybackStatus.playing : MPRISPlaybackStatus.paused;
    _smtc?.setPlaybackStatus(
      playing ? PlaybackStatus.Playing : PlaybackStatus.Paused,
    );
    if (_audioService != null) {
      _audioService!.playbackState.add(
        _audioService!.playbackState.value.copyWith(
          playing: playing,
          controls: [
            MediaControl.skipToPrevious,
            MediaControl.rewind,
            playing ? MediaControl.pause : MediaControl.play,
            MediaControl.fastForward,
            MediaControl.skipToNext,
          ],
        ),
      );
    }
  }

  void _setSmtcMetaData(Audio audio, Uri? artUri) {
    if (_smtc == null) return;
    _smtc!.updateMetadata(
      MusicMetadata(
        title: audio.title,
        album: audio.album,
        albumArtist: audio.artist,
        artist: audio.artist,
        thumbnail: audio.audioType == AudioType.local
            ? artUri?.toFilePath(windows: true)
            : '$artUri',
      ),
    );
  }

  void _setMprisMetadata(Audio audio, Uri? artUri) {
    if (_mpris == null || audio.url == null && audio.path == null) return;
    _mpris!.metadata = MPRISMetadata(
      audio.path != null ? Uri.file(audio.path!) : Uri.parse(audio.url!),
      artUrl: artUri,
      album: audio.album,
      albumArtist: [audio.albumArtist ?? ''],
      artist: [audio.artist ?? ''],
      discNumber: audio.discNumber,
      title: audio.title,
      trackNumber: audio.trackNumber,
    );
  }

  void _setAudioServiceMetaData(Audio audio, Uri? artUri) {
    if (_audioService == null) return;
    _audioService!.mediaItem.add(
      MediaItem(
        id: audio.toString(),
        duration: audio.durationMs == null
            ? null
            : Duration(milliseconds: audio.durationMs!.toInt()),
        title: audio.title ?? '',
        artist: audio.artist,
        artUri: artUri,
      ),
    );
  }

  Future<void> dispose() async {
    await _smtcSub?.cancel();
    await _mpris?.dispose();
    await _smtc?.disableSmtc();
    await _smtc?.dispose();
    await _queueController.close();
    await _mpvMetaDataController.close();
    await _audioController.close();
    await _nextAudioController.close();
    await _volumeController.close();
    await _shuffleController.close();
    await _durationController.close();
    await _isVideoController.close();
    await _positionController.close();
    await _isPlayingController.close();
    await _repeatSingleController.close();
    await _isPlayingSub?.cancel();
    await _positionSub?.cancel();
    await _durationSub?.cancel();
    await _isCompletedSub?.cancel();
    await _volumeSub?.cancel();
    await player.dispose();
  }
}

Set<String> _videoTypes = {
  '.3g2',
  '.3gp',
  '.aaf',
  '.asf',
  '.avchd',
  '.avi',
  '.drc',
  '.flv',
  '.m2v',
  '.m3u8',
  '.m4p',
  '.m4v',
  '.mkv',
  '.mng',
  '.mov',
  '.mp2',
  '.mp4',
  '.mpe',
  '.mpeg',
  '.mpg',
  '.mpv',
  '.mxf',
  '.nsv',
  '.ogg',
  '.ogv',
  '.qt',
  '.rm',
  '.rmvb',
  '.roq',
  '.svi',
  '.vob',
  '.webm',
  '.wmv',
  '.yuv',
};
