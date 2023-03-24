import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:musicpod/app/common/constants.dart';
import 'package:musicpod/data/audio.dart';
import 'package:safe_change_notifier/safe_change_notifier.dart';
import 'package:xdg_directories/xdg_directories.dart';

class PlaylistModel extends SafeChangeNotifier {
  int get totalListAmount =>
      starredStationsLength +
      podcastsLength +
      playlistsLength +
      pinnedAlbumsLength +
      5;

  //
  // Liked Audios
  //
  Set<Audio> _likedAudios = {};
  Set<Audio> get likedAudios => _likedAudios;

  void addLikedAudio(Audio audio, [bool notify = true]) {
    _likedAudios.add(audio);
    if (notify) {
      _write({'likedAudios': _likedAudios}, kLikedAudios)
          .then((value) => notifyListeners());
    }
  }

  void addLikedAudios(Set<Audio> audios) {
    for (var audio in audios) {
      addLikedAudio(audio, false);
    }
    _write({'likedAudios': _likedAudios}, kLikedAudios)
        .then((value) => notifyListeners());
  }

  bool liked(Audio audio) {
    return likedAudios.contains(audio);
  }

  void removeLikedAudio(Audio audio, [bool notify = true]) {
    _likedAudios.remove(audio);
    if (notify) {
      _write({'likedAudios': _likedAudios}, kLikedAudios)
          .then((value) => notifyListeners());
    }
  }

  void removeLikedAudios(Set<Audio> audios) {
    for (var audio in audios) {
      removeLikedAudio(audio, false);
    }
    _write({'likedAudios': _likedAudios}, kLikedAudios)
        .then((value) => notifyListeners());
  }

  //
  // Starred stations
  //

  Map<String, Set<Audio>> _starredStations = {};
  Map<String, Set<Audio>> get starredStations => _starredStations;
  int get starredStationsLength => _starredStations.length;
  void addStarredStation(String name, Set<Audio> audios) {
    _starredStations.putIfAbsent(name, () => audios);
    _write(_starredStations, kStarredStationsFileName)
        .then((_) => notifyListeners());
  }

  void unStarStation(String name) {
    _starredStations.remove(name);
    _write(_starredStations, kStarredStationsFileName)
        .then((_) => notifyListeners());
  }

  bool isStarredStation(String name) {
    return _starredStations.containsKey(name);
  }

  //
  // Normal playlists and albums
  //

  Map<String, Set<Audio>> _playlists = {};
  Map<String, Set<Audio>> get playlists => _playlists;
  int get playlistsLength => _playlists.length;
  List<Audio> getPlaylistAt(int index) =>
      _playlists.entries.elementAt(index).value.toList();

  bool isPlaylistSaved(String? name) => _playlists.containsKey(name);

  void addPlaylist(String name, Set<Audio> audios) {
    _playlists.putIfAbsent(name, () => audios);
    _write(_playlists, kPlaylistsFileName).then((_) => notifyListeners());
  }

  void removePlaylist(String name) {
    _playlists.remove(name);
    _write(_playlists, kPlaylistsFileName).then((_) => notifyListeners());
  }

  void updatePlaylistName(String oldName, String newName) {
    if (newName == oldName) return;
    final oldList = _playlists[oldName];
    if (oldList != null) {
      _playlists.remove(oldName);
      _playlists.putIfAbsent(newName, () => oldList);
    }

    _write(_playlists, kPlaylistsFileName).then((_) => notifyListeners());
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
    _write(_playlists, kPlaylistsFileName).then((_) => notifyListeners());
  }

  void removeAudioFromPlaylist(String playlist, Audio audio) {
    final p = _playlists[playlist];
    if (p != null && p.contains(audio)) {
      p.remove(audio);
    }
    _write(_playlists, kPlaylistsFileName).then((_) => notifyListeners());
  }

  List<String> getTopFivePlaylistNames() {
    return _playlists.entries.take(5).map((e) => e.key).toList();
  }

  // Podcasts

  Map<String, Set<Audio>> _podcasts = {};
  Map<String, Set<Audio>> get podcasts => _podcasts;
  int get podcastsLength => _podcasts.length;
  void addPodcast(String name, Set<Audio> audios) {
    _podcasts.putIfAbsent(name, () => audios);
    _write(_podcasts, kPodcastsFileName).then((_) => notifyListeners());
  }

  void removePodcast(String name) {
    _podcasts.remove(name);
    _podcastsToFeedUrls.remove(name);
    _write(_podcasts, kPodcastsFileName).then((_) => notifyListeners());
  }

  bool podcastSubscribed(String name) => _podcasts.containsKey(name);

  final Map<String, String> _podcastsToFeedUrls = {};
  Map<String, String> get podcastsToFeedUrls => _podcastsToFeedUrls;
  void addPlaylistFeed(String playlist, String feedUrl) {
    _podcastsToFeedUrls.putIfAbsent(playlist, () => feedUrl);
    _write(_podcasts, kPodcastsFileName).then((_) => notifyListeners());
  }

  //
  // Albums
  //

  Map<String, Set<Audio>> _pinnedAlbums = {};
  Map<String, Set<Audio>> get pinnedAlbums => _pinnedAlbums;
  int get pinnedAlbumsLength => _pinnedAlbums.length;
  List<Audio> getAlbumAt(int index) =>
      _pinnedAlbums.entries.elementAt(index).value.toList();

  bool isPinnedAlbum(String name) => _pinnedAlbums.containsKey(name);

  void addPinnedAlbum(String name, Set<Audio> audios) {
    _pinnedAlbums.putIfAbsent(name, () => audios);
    _write(_pinnedAlbums, kPinnedAlbumsFileName).then((_) => notifyListeners());
  }

  void removePinnedAlbum(String name) {
    _pinnedAlbums.remove(name);
    _write(_pinnedAlbums, kPinnedAlbumsFileName).then((_) => notifyListeners());
  }

  Future<void> init() async {
    _playlists = await _read(kPlaylistsFileName);
    _pinnedAlbums = await _read(kPinnedAlbumsFileName);
    _podcasts = await _read(kPodcastsFileName);
    _starredStations = await _read(kStarredStationsFileName);
    _likedAudios =
        (await _read(kLikedAudios)).entries.firstOrNull?.value ?? <Audio>{};
  }

  Future<void> save() async {
    await _write({'likedAudios': _likedAudios}, kLikedAudios);
    await _write(_playlists, kPlaylistsFileName);
    await _write(_pinnedAlbums, kPinnedAlbumsFileName);
    await _write(_podcasts, kPodcastsFileName);
    await _write(_starredStations, kStarredStationsFileName);
  }

  int? _index;
  int? get index => _index;
  set index(int? value) {
    if (value == null || value == _index) return;
    _index = value;
    notifyListeners();
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

  final workingDir = '${configHome.path}/$kMusicPodConfigSubDir';
  if (!Directory(workingDir).existsSync()) {
    await Directory(workingDir).create();
  }
  final path = '$workingDir/$fileName';

  final file = File(path);

  if (!file.existsSync()) {
    file.create();
  }

  await file.writeAsString(jsonStr);
}

Future<Map<String, Set<Audio>>> _read(String fileName) async {
  final workingDir = '${configHome.path}/musicpod';
  final path = '$workingDir/$fileName';
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
}
