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
  StreamSubscription<bool>? _updatesChangedSub;
  StreamSubscription<bool>? _favTagsSub;
  StreamSubscription<bool>? _favCountriesSub;
  StreamSubscription<bool>? _favLanguageCodeFavsSub;
  StreamSubscription<bool>? _lastFavSub;
  StreamSubscription<bool>? _lastCountryCodeSub;
  StreamSubscription<bool>? _downloadsSub;

  Future<bool> init() async {
    await _service.init();
    if (totalListAmount - 1 >= _service.appIndex) {
      _index = _service.appIndex;
    }

    _localAudioIndexSub ??=
        _service.localAudioIndexChanged.listen((_) => notifyListeners());
    _radioIndexSub ??=
        _service.radioIndexChanged.listen((_) => notifyListeners());
    _podcastIndexSub ??=
        _service.podcastIndexChanged.listen((_) => notifyListeners());
    _likedAudiosSub ??=
        _service.likedAudiosChanged.listen((event) => notifyListeners());
    _playlistsSub ??=
        _service.playlistsChanged.listen((event) => notifyListeners());
    _albumsSub = _service.albumsChanged.listen((event) => notifyListeners());
    _podcastsSub ??=
        _service.podcastsChanged.listen((event) => notifyListeners());
    _stationsSub ??=
        _service.starredStationsChanged.listen((event) => notifyListeners());
    _updatesChangedSub ??=
        _service.updatesChanged.listen((_) => notifyListeners());
    _favTagsSub ??= _service.favTagsChanged.listen((_) => notifyListeners());
    _favCountriesSub ??=
        _service.favCountriesChanged.listen((_) => notifyListeners());
    _favLanguageCodeFavsSub ??=
        _service.favLanguagesChanged.listen((_) => notifyListeners());
    _lastFavSub ??=
        _service.lastFavRadioTagChanged.listen((_) => notifyListeners());
    _downloadsSub ??=
        _service.downloadsChanged.listen((_) => notifyListeners());
    _lastCountryCodeSub ??=
        _service.lastCountryCodeChanged.listen((_) => notifyListeners());

    notifyListeners();
    return true;
  }

  @override
  Future<void> dispose() async {
    await _localAudioIndexSub?.cancel();
    await _radioIndexSub?.cancel();
    await _podcastIndexSub?.cancel();
    await _likedAudiosSub?.cancel();
    await _playlistsSub?.cancel();
    await _albumsSub?.cancel();
    await _podcastsSub?.cancel();
    await _stationsSub?.cancel();
    await _updatesChangedSub?.cancel();
    await _favTagsSub?.cancel();
    await _favCountriesSub?.cancel();
    await _favLanguageCodeFavsSub?.cancel();
    await _lastFavSub?.cancel();
    await _downloadsSub?.cancel();
    await _lastCountryCodeSub?.cancel();
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
  void addStarredStation(String url, Set<Audio> audios) =>
      _service.addStarredStation(url, audios);

  void unStarStation(String url) {
    final stationIndex = indexOfStation(url);
    if (stationIndex == index) {
      setIndex(_service.appIndex - 1);
    }
    _service.unStarStation(url);
  }

  int? indexOfStation(String? id) {
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

  String? get lastRadioTag => _service.lastRadioTag;
  void setLastRadioTag(String? value) => _service.setLastRadioTag(value);
  void addFavRadioTag(String value) => _service.addFavRadioTag(value);
  void removeRadioFavTag(String value) => _service.removeFavRadioTag(value);
  Set<String> get favRadioTags => _service.favRadioTags;
  int get favRadioTagsLength => _service.favRadioTags.length;

  String? get lastCountryCode => _service.lastCountryCode;
  void setLastCountryCode(String? value) => _service.setLastCountryCode(value);
  void addFavCountryCode(String value) => _service.addFavCountryCode(value);
  void removeFavCountryCode(String value) =>
      _service.removeFavCountryCode(value);
  Set<String> get favCountryCodes => _service.favCountryCodes;
  int get favCountriesLength => _service.favCountryCodes.length;

  String? get lastLanguageCode => _service.lastLanguageCode;
  void setLastLanguage(String? value) => _service.setLastLanguageCode(value);
  void addFavLanguageCode(String value) => _service.addFavLanguageCode(value);
  void removeFavLanguageCode(String value) =>
      _service.removeFavLanguageCode(value);
  Set<String> get favLanguageCodes => _service.favLanguageCodes;
  int get favLanguagesLength => _service.favLanguageCodes.length;

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

  Future<void> updatePlaylist(String id, Set<Audio> audios) async =>
      await _service.updatePlaylist(id, audios);

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

  void clearPlaylist(String id) => _service.clearPlaylist(id);

  List<String> getPlaylistNames() =>
      playlists.entries.map((e) => e.key).toList();

  void moveAudioInPlaylist({
    required int oldIndex,
    required int newIndex,
    required String id,
  }) =>
      _service.moveAudioInPlaylist(
        oldIndex: oldIndex,
        newIndex: newIndex,
        id: id,
      );

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

  int? indexOfPodcast(String? id) {
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

  int? indexOfAlbum(String? id) {
    if (id == null) return null;
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
}
