import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../../constants.dart';
import '../../data.dart';
import '../../patch_notes.dart';
import '../../utils.dart';

Future<void> _writeCache(Set<Audio> audios) async {
  await writeAudioMap({kLocalAudioCache: audios}, kLocalAudioCacheFileName);
}

Future<void> _readCache(Set<Audio>? localAudioCache) async {
  localAudioCache =
      (await readAudioMap(kLocalAudioCacheFileName))[kLocalAudioCache];
}

class LibraryService {
  Future<void> writeLocalAudioCache({required Set<Audio>? audios}) async {
    if (audios == null || audios.isEmpty == true) return;
    await _writeCache(audios);
  }

  Set<Audio>? _localAudioCache;
  Set<Audio>? get localAudioCache => _localAudioCache;
  Future<Set<Audio>?> _readLocalAudioCache() async {
    await compute(_readCache, _localAudioCache);
    return _localAudioCache;
  }

  Future<void> setUseLocalCache(bool value) async {
    await writeSetting(kUseLocalAudioCache, value ? 'true' : 'false');
    _useLocalAudioCache = value;
    _useLocalAudioCacheController.add(true);
  }

  bool? _useLocalAudioCache;
  bool? get useLocalAudioCache => _useLocalAudioCache;
  final _useLocalAudioCacheController = StreamController<bool>.broadcast();
  Stream<bool> get useLocalAudioCacheChanged =>
      _useLocalAudioCacheController.stream;

  Future<void> _readUseLocalAudioCache() async {
    String? value = await readSetting(kUseLocalAudioCache);
    if (value != null) {
      _useLocalAudioCache = bool.parse(value);
    }
  }

  //
  // last positions
  //
  Map<String, Duration> _lastPositions = {};
  Map<String, Duration> get lastPositions => _lastPositions;
  final _lastPositionsController = StreamController<bool>.broadcast();
  Stream<bool> get lastPositionsChanged => _lastPositionsController.stream;
  void addLastPosition(String url, Duration lastPosition) {
    if (_lastPositions.containsKey(url) == true) {
      _lastPositions.update(url, (value) => lastPosition);
    } else {
      _lastPositions.putIfAbsent(url, () => lastPosition);
    }

    writeSetting(url, lastPosition.toString(), kLastPositionsFileName)
        .then((_) => _lastPositionsController.add(true));
  }

  Duration? getLastPosition(String? url) => _lastPositions[url];

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
      writeAudioMap({kLikedAudiosPageId: _likedAudios}, kLikedAudiosFileName)
          .then((value) => _likedAudiosController.add(true));
    }
  }

  void addLikedAudios(Set<Audio> audios) {
    for (var audio in audios) {
      addLikedAudio(audio, false);
    }
    writeAudioMap({kLikedAudiosPageId: _likedAudios}, kLikedAudiosFileName)
        .then((value) => _likedAudiosController.add(true));
  }

  bool liked(Audio audio) {
    return likedAudios.contains(audio);
  }

  void removeLikedAudio(Audio audio, [bool notify = true]) {
    _likedAudios.remove(audio);
    if (notify) {
      writeAudioMap({kLikedAudiosPageId: _likedAudios}, kLikedAudiosFileName)
          .then((value) => _likedAudiosController.add(true));
    }
  }

  void removeLikedAudios(Set<Audio> audios) {
    for (var audio in audios) {
      removeLikedAudio(audio, false);
    }
    writeAudioMap({kLikedAudiosPageId: _likedAudios}, kLikedAudiosFileName)
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
    writeAudioMap(_starredStations, kStarredStationsFileName)
        .then((_) => _starredStationsController.add(true));
  }

  void unStarStation(String name) {
    _starredStations.remove(name);
    writeAudioMap(_starredStations, kStarredStationsFileName)
        .then((_) => _starredStationsController.add(true));
  }

  bool isStarredStation(String? url) {
    return url == null ? false : _starredStations.containsKey(url);
  }

  Set<String> _favTags = {};
  Set<String> get favTags => _favTags;
  bool isFavTag(String value) => _favTags.contains(value);
  final _favTagsController = StreamController<bool>.broadcast();
  Stream<bool> get favTagsChanged => _favTagsController.stream;

  void addFavTag(String name) {
    if (favTags.contains(name)) return;
    _favTags.add(name);
    writeStringIterable(iterable: _favTags, filename: kTagFavsFileName)
        .then((_) => _favTagsController.add(true));
  }

  void removeFavTag(String name) {
    if (!favTags.contains(name)) return;
    _favTags.remove(name);
    writeStringIterable(iterable: _favTags, filename: kTagFavsFileName)
        .then((_) => _favTagsController.add(true));
  }

  String? _lastFav;
  String? get lastFav => _lastFav;
  void setLastFav(String? value) {
    if (value == _lastFav) return;
    _lastFav = value;
    writeSetting(kLastFav, value).then((_) => _lastFavController.add(true));
  }

  final _lastFavController = StreamController<bool>.broadcast();
  Stream<bool> get lastFavChanged => _lastFavController.stream;

  String? _lastCountryCode;
  String? get lastCountryCode => _lastCountryCode;
  void setLastCountryCode(String? value) {
    if (value == _lastCountryCode) return;
    _lastCountryCode = value;
    writeSetting(kLastCountryCode, value)
        .then((_) => _lastCountryCodeController.add(true));
  }

  final _lastCountryCodeController = StreamController<bool>.broadcast();
  Stream<bool> get lastCountryCodeChanged => _lastCountryCodeController.stream;

  Set<String> _favCountries = {};
  Set<String> get favCountries => _favCountries;
  bool isFavCountry(String value) => _favCountries.contains(value);
  final _favCountriesController = StreamController<bool>.broadcast();
  Stream<bool> get favCountriesChanged => _favCountriesController.stream;

  void addFavCountry(String name) {
    if (favCountries.contains(name)) return;
    _favCountries.add(name);
    writeStringIterable(iterable: _favCountries, filename: kCountryFavsFileName)
        .then((_) => _favCountriesController.add(true));
  }

  void removeFavCountry(String name) {
    if (!favCountries.contains(name)) return;
    _favCountries.remove(name);
    writeStringIterable(iterable: _favCountries, filename: kCountryFavsFileName)
        .then((_) => _favCountriesController.add(true));
  }

  //
  // Playlists
  //

  Map<String, Set<Audio>> _playlists = {};
  Map<String, Set<Audio>> get playlists => _playlists;
  final _playlistsController = StreamController<bool>.broadcast();
  Stream<bool> get playlistsChanged => _playlistsController.stream;

  void addPlaylist(String id, Set<Audio> audios) {
    if (!_playlists.containsKey(id)) {
      _playlists.putIfAbsent(id, () => audios);
      writeAudioMap(_playlists, kPlaylistsFileName)
          .then((_) => _playlistsController.add(true));
    }
  }

  void removePlaylist(String id) {
    if (_playlists.containsKey(id)) {
      _playlists.remove(id);
      writeAudioMap(_playlists, kPlaylistsFileName)
          .then((_) => _playlistsController.add(true));
    }
  }

  void updatePlaylistName(String oldName, String newName) {
    if (newName == oldName) return;
    final oldList = _playlists[oldName];
    if (oldList != null) {
      _playlists.remove(oldName);
      _playlists.putIfAbsent(newName, () => oldList);
      writeAudioMap(_playlists, kPlaylistsFileName)
          .then((_) => _playlistsController.add(true));
    }
  }

  void addAudioToPlaylist(String id, Audio audio) {
    final playlist = _playlists[id];
    if (playlist != null) {
      for (var e in playlist) {
        if (e.path == audio.path) {
          return;
        }
      }
      playlist.add(audio);
      writeAudioMap(_playlists, kPlaylistsFileName)
          .then((_) => _playlistsController.add(true));
    }
  }

  void removeAudioFromPlaylist(String id, Audio audio) {
    final playlist = _playlists[id];
    if (playlist != null && playlist.contains(audio)) {
      playlist.remove(audio);
      writeAudioMap(_playlists, kPlaylistsFileName)
          .then((_) => _playlistsController.add(true));
    }
  }

  // Podcasts
  final dio = Dio();
  Map<String, String> _downloads = {};
  Map<String, String> get downloads => _downloads;
  String? getDownload(String? url) => downloads[url];

  Set<String> _feedsWithDownloads = {};
  bool feedHasDownloads(String feedUrl) =>
      _feedsWithDownloads.contains(feedUrl);
  int get feedsWithDownloadsLength => _feedsWithDownloads.length;

  final _downloadsController = StreamController<bool>.broadcast();
  Stream<bool> get downloadsChanged => _downloadsController.stream;
  void addDownload({
    required String url,
    required String path,
    required String feedUrl,
  }) {
    if (_downloads.containsKey(url)) return;
    _downloads.putIfAbsent(url, () => path);
    _feedsWithDownloads.add(feedUrl);
    writeStringMap(_downloads, kDownloads)
        .then(
          (_) => writeStringIterable(
            iterable: _feedsWithDownloads,
            filename: kFeedsWithDownloads,
          ),
        )
        .then((_) => _downloadsController.add(true));
  }

  void removeDownload({required String url, required String feedUrl}) {
    final path = _downloads[url];

    if (path != null) {
      final file = File(path);
      if (file.existsSync()) {
        file.deleteSync();
      }
    }

    if (_downloads.containsKey(url)) {
      _downloads.remove(url);
      _feedsWithDownloads.remove(feedUrl);

      writeStringMap(_downloads, kDownloads)
          .then(
            (_) => writeStringIterable(
              iterable: _feedsWithDownloads,
              filename: kFeedsWithDownloads,
            ),
          )
          .then((_) => _downloadsController.add(true));
    }
  }

  void _removeFeedWithDownload(String feedUrl) {
    if (!_feedsWithDownloads.contains(feedUrl)) return;
    _feedsWithDownloads.remove(feedUrl);
    writeStringIterable(
      iterable: _feedsWithDownloads,
      filename: kFeedsWithDownloads,
    ).then((_) => _downloadsController.add(true));
  }

  String? _downloadsDir;
  String? get downloadsDir => _downloadsDir;
  Map<String, Set<Audio>> _podcasts = {};
  Map<String, Set<Audio>> get podcasts => _podcasts;
  int get podcastsLength => _podcasts.length;
  final _podcastsController = StreamController<bool>.broadcast();
  Stream<bool> get podcastsChanged => _podcastsController.stream;

  void addPodcast(String feedUrl, Set<Audio> audios) {
    if (_podcasts.containsKey(feedUrl)) return;
    _podcasts.putIfAbsent(feedUrl, () => audios);
    writeAudioMap(_podcasts, kPodcastsFileName)
        .then((_) => _podcastsController.add(true));
  }

  void updatePodcast(String feedUrl, Set<Audio> audios) {
    if (feedUrl.isEmpty || audios.isEmpty) return;
    _addPodcastUpdate(feedUrl);
    _podcasts.update(feedUrl, (value) => audios);
    writeAudioMap(_podcasts, kPodcastsFileName)
        .then((_) => _podcastsController.add(true));
  }

  void _addPodcastUpdate(String feedUrl) {
    if (_podcastUpdates?.contains(feedUrl) == true) return;
    _podcastUpdates?.add(feedUrl);
    writeStringIterable(iterable: _podcastUpdates!, filename: kPodcastsUpdates)
        .then((_) => _updateController.add(true));
  }

  Set<String>? _podcastUpdates;
  int? get podcastUpdatesLength => _podcastUpdates?.length;

  bool podcastUpdateAvailable(String feedUrl) =>
      _podcastUpdates?.contains(feedUrl) == true;

  void removePodcastUpdate(String feedUrl) {
    if (_podcastUpdates?.isNotEmpty == false) return;
    _podcastUpdates?.remove(feedUrl);
    writeStringIterable(iterable: _podcastUpdates!, filename: kPodcastsUpdates)
        .then((_) => _updateController.add(true));
  }

  final _updateController = StreamController<bool>.broadcast();
  Stream<bool> get updatesChanged => _updateController.stream;

  void removePodcast(String name) {
    if (!_podcasts.containsKey(name)) return;
    _podcasts.remove(name);
    writeAudioMap(_podcasts, kPodcastsFileName)
        .then((_) => _podcastsController.add(true))
        .then((_) => removePodcastUpdate(name))
        .then((_) => _removeFeedWithDownload(name));
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
    writeAudioMap(_pinnedAlbums, kPinnedAlbumsFileName)
        .then((_) => _albumsController.add(true));
  }

  void removePinnedAlbum(String name) {
    _pinnedAlbums.remove(name);
    writeAudioMap(_pinnedAlbums, kPinnedAlbumsFileName)
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

  bool _libraryInitialized = false;
  Future<bool> init() async {
    await _initSettings();
    await _initLibrary();
    return _libraryInitialized;
  }

  Future<void> _initLibrary() async {
    if (_libraryInitialized) return;
    if (_useLocalAudioCache == true) {
      await _readLocalAudioCache();
    }
    _playlists = await readAudioMap(kPlaylistsFileName);
    _pinnedAlbums = await readAudioMap(kPinnedAlbumsFileName);
    _podcasts = await readAudioMap(kPodcastsFileName);
    _podcastUpdates = Set.from(
      await readStringIterable(filename: kPodcastsUpdates) ?? <String>{},
    );
    _podcastUpdates ??= {};
    _starredStations = await readAudioMap(kStarredStationsFileName);
    _lastPositions = (await getSettings(kLastPositionsFileName)).map(
      (key, value) => MapEntry(key, parseDuration(value) ?? Duration.zero),
    );
    _likedAudios =
        (await readAudioMap(kLikedAudiosFileName)).entries.firstOrNull?.value ??
            <Audio>{};
    _favTags = Set.from(
      (await readStringIterable(filename: kTagFavsFileName) ?? <String>{}),
    );
    _favCountries = Set.from(
      (await readStringIterable(filename: kCountryFavsFileName) ?? <String>{}),
    );
    _downloadsDir = await getDownloadsDir();
    _downloads = await readStringMap(kDownloads);
    _feedsWithDownloads = Set.from(
      await readStringIterable(filename: kFeedsWithDownloads) ?? <String>{},
    );
    _libraryInitialized = true;
  }

  bool _settingsInitialized = false;
  Future<void> _initSettings() async {
    if (_settingsInitialized) return;

    await _readUseLocalAudioCache();

    await _readRecentPatchNotesDisposed();

    var neverShowImportsOrNull = await readSetting(kNeverShowImportFails);
    _neverShowFailedImports = neverShowImportsOrNull == null
        ? false
        : bool.parse(neverShowImportsOrNull);

    final appIndexOrNull = await readSetting(kAppIndex);
    _appIndex = appIndexOrNull == null ? 0 : int.parse(appIndexOrNull);

    final localAudioIndexStringOrNull = await readSetting(kLocalAudioIndex);
    if (localAudioIndexStringOrNull != null) {
      final localParse = int.tryParse((await readSetting(kLocalAudioIndex)));
      if (localParse != null) {
        _localAudioIndex = localParse;
      }
    }

    final radioIndexStringOrNull = await readSetting(kRadioIndex);
    if (radioIndexStringOrNull != null) {
      final radioParse = int.tryParse(radioIndexStringOrNull);
      if (radioParse != null) {
        _radioIndex = radioParse;
      }
    }

    _settingsInitialized = true;
  }

  int _localAudioIndex = 0;
  int get localAudioIndex => _localAudioIndex;
  final _localAudioIndexController = StreamController<bool>.broadcast();
  Stream<bool> get localAudioIndexChanged => _localAudioIndexController.stream;
  void setLocalAudioIndex(int value) {
    if (value == _localAudioIndex) return;
    _localAudioIndex = value;
    _localAudioIndexController.add(true);
  }

  int _radioIndex = 2; // Default to RadioSearch.country
  int get radioIndex => _radioIndex;
  final _radioIndexController = StreamController<bool>.broadcast();
  Stream<bool> get radioIndexChanged => _radioIndexController.stream;
  void setRadioIndex(int value) {
    if (value == _radioIndex) return;
    _radioIndex = value;
    _radioIndexController.add(true);
  }

  int _podcastIndex = 0;
  int get podcastIndex => _podcastIndex;
  final _podcastIndexController = StreamController<bool>.broadcast();
  Stream<bool> get podcastIndexChanged => _podcastIndexController.stream;
  void setPodcastIndex(int value) {
    if (value == _podcastIndex) return;
    _podcastIndex = value;
    _podcastIndexController.add(true);
  }

  int _appIndex = 0;
  int get appIndex => _appIndex;
  void setAppIndex(int value) {
    _appIndex = value;
  }

  Future<void> dispose() async {
    dio.close();
    await safeStates();
    await _useLocalAudioCacheController.close();
    await _albumsController.close();
    await _podcastsController.close();
    await _likedAudiosController.close();
    await _playlistsController.close();
    await _starredStationsController.close();
    await _favTagsController.close();
    await _favCountriesController.close();
    await _lastPositionsController.close();
    await _localAudioIndexController.close();
    await _radioIndexController.close();
    await _podcastIndexController.close();
    await _neverShowFailedImportsController.close();
    await _lastFavController.close();
    await _updateController.close();
    await _downloadsController.close();
  }

  Future<void> safeStates() async {
    await writeSetting(kLocalAudioIndex, _localAudioIndex.toString());
    await writeSetting(kRadioIndex, _radioIndex.toString());
    await writeSetting(kPodcastIndex, _podcastIndex.toString());
    await writeSetting(kAppIndex, _appIndex.toString());
    await writePlayerState();
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
    final playerState = PlayerState(
      audio: _lastAudio,
      duration: _duration?.toString(),
      position: _position?.toString(),
      queue: _queue != null && _queue!.length < 200 ? _queue : null,
      queueName: _queue != null && _queue!.length < 200 ? _queueName : null,
    );

    await writeJsonToFile(playerState.toMap(), kPlayerStateFileName);
  }

  Duration? _duration;
  void setDuration(Duration? duration) => _duration = duration;
  Duration? _position;
  void setPosition(Duration? position) => _position = position;
  Audio? _lastAudio;
  void setLastAudio(Audio? audio) => _lastAudio = audio;
  String? _queueName;
  List<Audio>? _queue;
  void setQueueName(String? value) => _queueName = value;
  void setQueue(List<Audio>? value) => _queue = value;

  Future<PlayerState?> readPlayerState() async {
    try {
      final workingDir = await getWorkingDir();
      final file = File(p.join(workingDir, kPlayerStateFileName));

      if (file.existsSync()) {
        final jsonStr = await file.readAsString();

        return PlayerState.fromJson(jsonStr);
      } else {
        return null;
      }
    } on Exception catch (_) {
      return null;
    }
  }
}
