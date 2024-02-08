import 'dart:async';

import 'package:safe_change_notifier/safe_change_notifier.dart';

import '../../constants.dart';
import '../../data.dart';
import 'library_service.dart';

const kFixedListAmount = 5; // local, radio, podcasts, newplaylist, favs

class LibraryModel extends SafeChangeNotifier {
  LibraryModel(this._service);

  final LibraryService _service;
  StreamSubscription<bool>? _likedAudiosSub;
  StreamSubscription<bool>? _playlistsSub;
  StreamSubscription<bool>? _albumsSub;
  StreamSubscription<bool>? _podcastsSub;
  StreamSubscription<bool>? _stationsSub;
  StreamSubscription<bool>? _localAudioIndexSub;
  StreamSubscription<bool>? _podcastIndexSub;
  StreamSubscription<bool>? _radioIndexSub;
  StreamSubscription<bool>? _lastPositionsSub;
  StreamSubscription<bool>? _updatesChangedSub;
  StreamSubscription<bool>? _neverShowFailedImportsSub;
  StreamSubscription<bool>? _favTagsSub;
  StreamSubscription<bool>? _favCountriesSub;

  StreamSubscription<bool>? _lastFavSub;
  StreamSubscription<bool>? _lastCountryCodeSub;
  StreamSubscription<bool>? _downloadsSub;

  bool get neverShowFailedImports => _service.neverShowFailedImports;
  Future<void> setNeverShowLocalImports() async =>
      await _service.setNeverShowFailedImports();

  Future<void> init() async {
    if (totalListAmount - 1 >= _service.appIndex) {
      _index = _service.appIndex;
    }

    _localAudioIndexSub =
        _service.localAudioIndexChanged.listen((_) => notifyListeners());
    _radioIndexSub =
        _service.radioIndexChanged.listen((_) => notifyListeners());
    _podcastIndexSub =
        _service.podcastIndexChanged.listen((_) => notifyListeners());
    _likedAudiosSub =
        _service.likedAudiosChanged.listen((event) => notifyListeners());
    _playlistsSub =
        _service.playlistsChanged.listen((event) => notifyListeners());
    _albumsSub = _service.albumsChanged.listen((event) => notifyListeners());
    _podcastsSub =
        _service.podcastsChanged.listen((event) => notifyListeners());
    _stationsSub =
        _service.starredStationsChanged.listen((event) => notifyListeners());
    _lastPositionsSub =
        _service.lastPositionsChanged.listen((_) => notifyListeners());
    _updatesChangedSub =
        _service.updatesChanged.listen((_) => notifyListeners());
    _neverShowFailedImportsSub =
        _service.neverShowFailedImportsChanged.listen((_) => notifyListeners());
    _favTagsSub = _service.favTagsChanged.listen((_) => notifyListeners());
    _favCountriesSub =
        _service.favCountriesChanged.listen((_) => notifyListeners());

    _lastFavSub = _service.lastFavChanged.listen((_) => notifyListeners());
    _downloadsSub = _service.downloadsChanged.listen((_) => notifyListeners());
    _lastCountryCodeSub =
        _service.lastCountryCodeChanged.listen((_) => notifyListeners());

    notifyListeners();
  }

  Future<void> safeStates() async {
    await _service.safeStates();
  }

  @override
  Future<void> dispose() async {
    _localAudioIndexSub?.cancel();
    _radioIndexSub?.cancel();
    _podcastIndexSub?.cancel();
    _likedAudiosSub?.cancel();
    _playlistsSub?.cancel();
    _albumsSub?.cancel();
    _podcastsSub?.cancel();
    _stationsSub?.cancel();
    _lastPositionsSub?.cancel();
    _updatesChangedSub?.cancel();
    _neverShowFailedImportsSub?.cancel();
    _favTagsSub?.cancel();
    _favCountriesSub?.cancel();
    _lastFavSub?.cancel();
    _downloadsSub?.cancel();
    _lastCountryCodeSub?.cancel();

    super.dispose();
  }

  int get totalListAmount {
    return starredStationsLength +
        podcastsLength +
        playlistsLength +
        pinnedAlbumsLength +
        kFixedListAmount;
  }

  Set<Audio>? getAudiosById(String pageId) {
    if (pageId == kLikedAudiosPageId) {
      return likedAudios;
    } else {
      return playlists[pageId] ??
          pinnedAlbums[pageId] ??
          podcasts[pageId] ??
          starredStations[pageId];
    }
  }

  //
  // Liked Audios
  //
  Set<Audio> get likedAudios => _service.likedAudios;

  void addLikedAudio(Audio audio, [bool notify = true]) =>
      _service.addLikedAudio(audio, notify);

  void addLikedAudios(Set<Audio> audios) => _service.addLikedAudios(audios);

  bool liked(Audio? audio) => audio == null ? false : _service.liked(audio);

  void removeLikedAudio(Audio audio, [bool notify = true]) =>
      _service.removeLikedAudio(audio, notify);

  void removeLikedAudios(Set<Audio> audios) =>
      _service.removeLikedAudios(audios);

  //
  // Starred stations
  //

  Map<String, Set<Audio>> get starredStations => _service.starredStations;
  int get starredStationsLength => _service.starredStations.length;
  void addStarredStation(String name, Set<Audio> audios) =>
      _service.addStarredStation(name, audios);

  void unStarStation(String url) {
    final stationIndex = indexOfStation(url);
    if (stationIndex == index) {
      setIndex(_service.appIndex - 1);
    }
    _service.unStarStation(url);
  }

  int? indexOfStation(String id) {
    final station = starredStations[id];
    if (station == null) return null;
    final allStations = starredStations.entries.map((e) => e.value).toList();
    return kFixedListAmount +
        playlistsLength +
        podcastsLength +
        pinnedAlbumsLength +
        allStations.indexOf(station);
  }

  bool isStarredStation(String? url) =>
      url?.isNotEmpty == false ? false : _service.isStarredStation(url);

  Set<String> get favTags => _service.favTags;
  int get favTagsLength => _service.favTags.length;

  void addFavTag(String value) => _service.addFavTag(value);
  void removeFavTag(String value) => _service.removeFavTag(value);

  String? get lastFav => _service.lastFav;
  void setLastFav(String? value) => _service.setLastFav(value);

  String? get lastCountryCode => _service.lastCountryCode;
  void setLastCountryCode(String? value) => _service.setLastCountryCode(value);

  void addFavCountry(String value) => _service.addFavCountry(value);
  void removeFavCountry(String value) => _service.removeFavCountry(value);

  Set<String> get favCountryCodes => _service.favCountries;
  int get favCountriesLength => _service.favCountries.length;

  //
  // Playlists
  //

  Map<String, Set<Audio>> get playlists => _service.playlists;
  int get playlistsLength => playlists.length;
  List<Audio> getPlaylistAt(int index) =>
      playlists.entries.elementAt(index).value.toList();
  Set<Audio>? getPlaylistById(String id) => _service.playlists[id];

  bool isPlaylistSaved(String? name) => playlists.containsKey(name);

  void addPlaylist(String name, Set<Audio> audios) =>
      _service.addPlaylist(name, audios);

  void removePlaylist(String id) {
    final playlistIndex = getIndexOfPlaylist(id);
    if (index == playlistIndex) {
      setIndex(_service.appIndex - 1);
    }
    _service.removePlaylist(id);
  }

  int? getIndexOfPlaylist(String id) {
    if (id == kLikedAudiosPageId) return 4;
    final playlist = getPlaylistById(id);
    if (playlist == null) return null;
    final allPlaylists = playlists.entries.map((e) => e.value).toList();
    return kFixedListAmount + allPlaylists.indexOf(playlist);
  }

  void updatePlaylistName(String oldName, String newName) =>
      _service.updatePlaylistName(oldName, newName);

  void addAudioToPlaylist(String playlist, Audio audio) =>
      _service.addAudioToPlaylist(playlist, audio);

  void removeAudioFromPlaylist(String playlist, Audio audio) =>
      _service.removeAudioFromPlaylist(playlist, audio);

  List<String> getPlaylistNames() =>
      playlists.entries.map((e) => e.key).toList();

  // Podcasts

  Map<String, Set<Audio>> get podcasts => _service.podcasts;
  int get podcastsLength => podcasts.length;
  void addPodcast(String feedUrl, Set<Audio> audios) =>
      _service.addPodcast(feedUrl, audios);
  void updatePodcast(String feedUrl, Set<Audio> audios) =>
      _service.updatePodcast(feedUrl, audios);

  void removePodcast(String feedUrl) {
    final podcastIndex = indexOfPodcast(feedUrl);
    if (podcastIndex == index) {
      setIndex(_service.appIndex - 1);
    }
    _service.removePodcast(feedUrl);
  }

  int? indexOfPodcast(String id) {
    final podcast = podcasts[id];
    if (podcast == null) return null;
    final allPodcasts = podcasts.entries.map((e) => e.value).toList();
    return kFixedListAmount + playlistsLength + allPodcasts.indexOf(podcast);
  }

  bool podcastSubscribed(String? feedUrl) =>
      feedUrl == null ? false : podcasts.containsKey(feedUrl);

  bool podcastUpdateAvailable(String feedUrl) =>
      _service.podcastUpdateAvailable(feedUrl);

  int? get podcastUpdatesLength => _service.podcastUpdatesLength;

  void removePodcastUpdate(String feedUrl) =>
      _service.removePodcastUpdate(feedUrl);

  int get downloadsLength => _service.downloads.length;

  String? getDownload(String? url) =>
      url == null ? null : _service.downloads[url];

  bool feedHasDownload(String? feedUrl) =>
      feedUrl == null ? false : _service.feedHasDownloads(feedUrl);

  int get feedsWithDownloadsLength => _service.feedsWithDownloadsLength;

  //
  // Albums
  //

  Map<String, Set<Audio>> get pinnedAlbums => _service.pinnedAlbums;
  int get pinnedAlbumsLength => pinnedAlbums.length;
  List<Audio> getAlbumAt(int index) =>
      pinnedAlbums.entries.elementAt(index).value.toList();
  bool isPinnedAlbum(String name) => pinnedAlbums.containsKey(name);

  void addPinnedAlbum(String name, Set<Audio> audios) =>
      _service.addPinnedAlbum(name, audios);

  void removePinnedAlbum(String name) {
    final albumIndex = indexOfAlbum(name);
    if (albumIndex == index) {
      setIndex(_service.appIndex - 1);
    }
    _service.removePinnedAlbum(name);
  }

  int? indexOfAlbum(String id) {
    final album = pinnedAlbums[id];
    if (album == null) return null;
    final allAlbums = pinnedAlbums.entries.map((e) => e.value).toList();
    return kFixedListAmount +
        playlistsLength +
        podcastsLength +
        allAlbums.indexOf(album);
  }

  int? _index;
  int? get index => _index;
  void setIndex(int? value) {
    if (value == null || value == _index) return;
    _index = value;
    _service.setAppIndex(value);
    notifyListeners();
  }

  int? get localAudioindex => _service.localAudioIndex;
  void setLocalAudioindex(int? value) {
    if (value == null || value == _service.localAudioIndex) return;
    _service.setLocalAudioIndex(value);
  }

  int get radioindex => _service.radioIndex;
  void setRadioIndex(int value) => _service.setRadioIndex(value);

  int get podcastIndex => _service.podcastIndex;
  void setPodcastIndex(int value) => _service.setPodcastIndex(value);

  Map<String, Duration>? get lastPositions => _service.lastPositions;
  Duration? getLastPosition(String? url) => _service.getLastPosition(url);
  void addLastPosition(String url, Duration lastPosition) =>
      _service.addLastPosition(url, lastPosition);

  Future<void> disposePatchNotes() async => await _service.disposePatchNotes();

  bool get recentPatchNotesDisposed => _service.recentPatchNotesDisposed;
}
