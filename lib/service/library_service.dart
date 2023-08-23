import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:musicpod/constants.dart';
import 'package:musicpod/data/audio.dart';
import 'package:musicpod/utils.dart';

class LibraryService {
  //
  // last positions
  //
  Map<String, Duration>? _lastPositions = {};
  Map<String, Duration>? get lastPositions => _lastPositions;
  final _lastPositionsController = StreamController<bool>.broadcast();
  Stream<bool> get lastPositionsChanged => _lastPositionsController.stream;
  void addLastPosition(String url, Duration lastPosition) {
    if (_lastPositions?.containsKey(url) == true) {
      _lastPositions?.update(url, (value) => lastPosition);
    } else {
      _lastPositions?.putIfAbsent(url, () => lastPosition);
    }

    writeSetting(url, lastPosition.toString(), kLastPositionsFileName)
        .then((_) => _lastPositionsController.add(true));
  }

  Duration? getLastPosition(String? url) => _lastPositions?[url];

  //
  // Liked Audios
  //
  Set<Audio> _likedAudios = {};
  Set<Audio> get likedAudios => _likedAudios;
  final _likedAudiosController = StreamController<bool>.broadcast();
  Stream<bool> get likedAudiosChanged => _likedAudiosController.stream;

  void addLikedAudio(Audio audio, [bool notify = true]) {
    _likedAudios.add(audio);
    if (notify) {
      _write({'likedAudios': _likedAudios}, kLikedAudios)
          .then((value) => _likedAudiosController.add(true));
    }
  }

  void addLikedAudios(Set<Audio> audios) {
    for (var audio in audios) {
      addLikedAudio(audio, false);
    }
    _write({'likedAudios': _likedAudios}, kLikedAudios)
        .then((value) => _likedAudiosController.add(true));
  }

  bool liked(Audio audio) {
    return likedAudios.contains(audio);
  }

  void removeLikedAudio(Audio audio, [bool notify = true]) {
    _likedAudios.remove(audio);
    if (notify) {
      _write({'likedAudios': _likedAudios}, kLikedAudios)
          .then((value) => _likedAudiosController.add(true));
    }
  }

  void removeLikedAudios(Set<Audio> audios) {
    for (var audio in audios) {
      removeLikedAudio(audio, false);
    }
    _write({'likedAudios': _likedAudios}, kLikedAudios)
        .then((value) => _likedAudiosController.add(true));
  }

  //
  // Starred stations
  //

  Map<String, Set<Audio>> _starredStations = {};
  Map<String, Set<Audio>> get starredStations => _starredStations;
  int get starredStationsLength => _starredStations.length;
  final _starredStationsController = StreamController<bool>.broadcast();
  Stream<bool> get starredStationsChanged => _starredStationsController.stream;

  void addStarredStation(String name, Set<Audio> audios) {
    _starredStations.putIfAbsent(name, () => audios);
    _write(_starredStations, kStarredStationsFileName)
        .then((_) => _starredStationsController.add(true));
  }

  void unStarStation(String name) {
    _starredStations.remove(name);
    _write(_starredStations, kStarredStationsFileName)
        .then((_) => _starredStationsController.add(true));
  }

  bool isStarredStation(String name) {
    return _starredStations.containsKey(name);
  }

  //
  // Playlists
  //

  Map<String, Set<Audio>> _playlists = {};
  Map<String, Set<Audio>> get playlists => _playlists;
  final _playlistsController = StreamController<bool>.broadcast();
  Stream<bool> get playlistsChanged => _playlistsController.stream;

  void addPlaylist(String name, Set<Audio> audios) {
    _playlists.putIfAbsent(name, () => audios);
    _write(_playlists, kPlaylistsFileName)
        .then((_) => _playlistsController.add(true));
  }

  void removePlaylist(String name) {
    _playlists.remove(name);
    _write(_playlists, kPlaylistsFileName)
        .then((_) => _playlistsController.add(true));
  }

  void updatePlaylistName(String oldName, String newName) {
    if (newName == oldName) return;
    final oldList = _playlists[oldName];
    if (oldList != null) {
      _playlists.remove(oldName);
      _playlists.putIfAbsent(newName, () => oldList);
    }

    _write(_playlists, kPlaylistsFileName)
        .then((_) => _playlistsController.add(true));
  }

  void addAudioToPlaylist(String playlist, Audio audio) {
    final p = _playlists[playlist];
    if (p != null) {
      for (var e in p) {
        if (e.path == audio.path) {
          return;
        }
      }
      p.add(audio);
    }
    _write(_playlists, kPlaylistsFileName)
        .then((_) => _playlistsController.add(true));
  }

  void removeAudioFromPlaylist(String playlist, Audio audio) {
    final p = _playlists[playlist];
    if (p != null && p.contains(audio)) {
      p.remove(audio);
    }
    _write(_playlists, kPlaylistsFileName)
        .then((_) => _playlistsController.add(true));
  }

  // Podcasts

  Map<String, Set<Audio>> _podcasts = {};
  Map<String, Set<Audio>> get podcasts => _podcasts;
  int get podcastsLength => _podcasts.length;
  final _podcastsController = StreamController<bool>.broadcast();
  Stream<bool> get podcastsChanged => _podcastsController.stream;

  void addPodcast(String feedUrl, Set<Audio> audios) {
    _podcasts.putIfAbsent(feedUrl, () => audios);
    _write(_podcasts, kPodcastsFileName)
        .then((_) => _podcastsController.add(true));
  }

  void updatePodcast(String feedUrl, Set<Audio> audios) {
    _podcasts.update(feedUrl, (value) => audios);
    _write(_podcasts, kPodcastsFileName)
        .then((_) => _podcastsController.add(true))
        .then((_) => podcastUpdates.add(feedUrl))
        .then((_) => _updateController.add(true));
  }

  final Set<String> podcastUpdates = {};
  bool podcastUpdateAvailable(String feedUrl) =>
      podcastUpdates.contains(feedUrl);
  void removePodcastUpdate(String feedUrl) {
    podcastUpdates.remove(feedUrl);
    _updateController.add(true);
  }

  final _updateController = StreamController<bool>.broadcast();
  Stream<bool> get updatesChanged => _updateController.stream;

  void removePodcast(String name) {
    _podcasts.remove(name);
    _write(_podcasts, kPodcastsFileName)
        .then((_) => _podcastsController.add(true));
  }

  //
  // Albums
  //

  Map<String, Set<Audio>> _pinnedAlbums = {};
  Map<String, Set<Audio>> get pinnedAlbums => _pinnedAlbums;
  int get pinnedAlbumsLength => _pinnedAlbums.length;
  final _albumsController = StreamController<bool>.broadcast();
  Stream<bool> get albumsChanged => _albumsController.stream;

  List<Audio> getAlbumAt(int index) =>
      _pinnedAlbums.entries.elementAt(index).value.toList();

  bool isPinnedAlbum(String name) => _pinnedAlbums.containsKey(name);

  void addPinnedAlbum(String name, Set<Audio> audios) {
    _pinnedAlbums.putIfAbsent(name, () => audios);
    _write(_pinnedAlbums, kPinnedAlbumsFileName)
        .then((_) => _albumsController.add(true));
  }

  void removePinnedAlbum(String name) {
    _pinnedAlbums.remove(name);
    _write(_pinnedAlbums, kPinnedAlbumsFileName)
        .then((_) => _albumsController.add(true));
  }

  bool _neverShowFailedImports = false;
  bool get neverShowFailedImports => _neverShowFailedImports;
  final _neverShowFailedImportsController = StreamController<bool>.broadcast();
  Stream<bool> get neverShowFailedImportsChanged =>
      _neverShowFailedImportsController.stream;
  Future<void> setNeverShowFailedImports() async {
    _neverShowFailedImports = !_neverShowFailedImports;
    await writeSetting(
      kNeverShowImportFails,
      _neverShowFailedImports.toString(),
    );
    _neverShowFailedImportsController.add(true);
  }

  Future<void> init() async {
    await _readRecentPatchNotesDisposed();

    var neverShowImportsOrNull = await readSetting(kNeverShowImportFails);
    _neverShowFailedImports = neverShowImportsOrNull == null
        ? false
        : bool.parse(neverShowImportsOrNull);

    final appIndexOrNull = await readSetting(kAppIndex);
    _appIndex = appIndexOrNull == null ? 0 : int.parse(appIndexOrNull);

    final localAudioIndexOrNull = await readSetting(kLocalAudioIndex);
    _localAudioIndex =
        localAudioIndexOrNull == null ? 0 : int.parse(localAudioIndexOrNull);

    _playlists = await _read(kPlaylistsFileName);
    _pinnedAlbums = await _read(kPinnedAlbumsFileName);
    _podcasts = await _read(kPodcastsFileName);
    _starredStations = await _read(kStarredStationsFileName);
    _lastPositions = (await getSettings(kLastPositionsFileName)).map(
      (key, value) => MapEntry(key, parseDuration(value) ?? Duration.zero),
    );

    _likedAudios =
        (await _read(kLikedAudios)).entries.firstOrNull?.value ?? <Audio>{};
  }

  int? _localAudioIndex;
  int? get localAudioIndex => _localAudioIndex;
  final _localAudioIndexController = StreamController<int?>.broadcast();
  Stream<int?> get localAudioIndexStream => _localAudioIndexController.stream;
  void setLocalAudioIndex(int? value) {
    _localAudioIndex = value;
  }

  int? _appIndex;
  int? get appIndex => _appIndex;
  void setAppIndex(int? value) {
    _appIndex = value;
  }

  Future<void> dispose() async {
    await writeSetting(kLocalAudioIndex, _localAudioIndex.toString());
    await writeSetting(kAppIndex, _appIndex.toString());
    await writePlayerState();
    await _albumsController.close();
    await _podcastsController.close();
    await _likedAudiosController.close();
    await _playlistsController.close();
    await _starredStationsController.close();
    await _lastPositionsController.close();
    await _localAudioIndexController.close();
    await _neverShowFailedImportsController.close();
    _updateController.close();
  }

  Future<void> disposePatchNotes() async {
    await writeSetting(
      kPatchNotesDisposed,
      kRecentPatchNotesDisposed,
    );
  }

  bool _recentPatchNotesDisposed = false;
  bool get recentPatchNotesDisposed => _recentPatchNotesDisposed;

  Future<void> _readRecentPatchNotesDisposed() async {
    String? value = await readSetting(kPatchNotesDisposed);
    if (value == kRecentPatchNotesDisposed) {
      _recentPatchNotesDisposed = true;
    }
  }

  Future<void> writePlayerState() async {
    await writeSetting(kLastPositionAsString, _position.toString());
    await writeSetting(kLastDurationAsString, _duration.toString());
    await writeSetting(kLastAudio, _lastAudio?.toJson());
  }

  Duration? _duration;
  void setDuration(Duration? duration) => _duration = duration;
  Duration? _position;
  void setPosition(Duration? position) => _position = position;
  Audio? _lastAudio;
  void setLastAudio(Audio? audio) => _lastAudio = audio;

  Future<(Duration?, Duration?, Audio?)> readPlayerState() async {
    Duration? position, duration;
    Audio? audio;
    final positionAsString = await readSetting(kLastPositionAsString);
    final durationAsString = await readSetting(kLastDurationAsString);
    if (positionAsString != null) {
      position = parseDuration(positionAsString);
    }
    if (durationAsString != null) {
      duration = parseDuration(durationAsString);
    }
    final maybeAudio = await readSetting(kLastAudio);
    if (maybeAudio != null) {
      audio = Audio.fromJson(maybeAudio);
    }

    return (position, duration, audio);
  }
}

Future<void> _write(Map<String, Set<Audio>> map, String fileName) async {
  final dynamicMap = map.map(
    (key, value) => MapEntry<String, List<dynamic>>(
      key,
      value.map((audio) => audio.toMap()).toList(),
    ),
  );

  final jsonStr = jsonEncode(dynamicMap);

  final workingDir = await getWorkingDir();
  final path = '$workingDir/$fileName';

  final file = File(path);

  if (!file.existsSync()) {
    file.create();
  }

  await file.writeAsString(jsonStr);
}

Future<Map<String, Set<Audio>>> _read(String fileName) async {
  final workingDir = await getWorkingDir();
  final path = '$workingDir/$fileName';

  try {
    final file = File(path);

    if (file.existsSync()) {
      final jsonStr = await file.readAsString();

      final map = jsonDecode(jsonStr) as Map<String, dynamic>;

      final m = map.map(
        (key, value) => MapEntry<String, Set<Audio>>(
          key,
          Set.from(
            (value as List<dynamic>).map((e) => Audio.fromMap(e)),
          ),
        ),
      );

      return m;
    } else {
      return <String, Set<Audio>>{};
    }
  } on Exception catch (_) {
    return <String, Set<Audio>>{};
  }
}
