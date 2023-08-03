import 'package:collection/collection.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:desktop_notifications/desktop_notifications.dart';
import 'package:flutter/material.dart';
import 'package:mpris_service/mpris_service.dart';
import 'package:musicpod/app/app_model.dart';
import 'package:musicpod/app/audio_page_filter_bar.dart';
import 'package:musicpod/app/common/audio_page.dart';
import 'package:musicpod/constants.dart';
import 'package:musicpod/app/common/offline_page.dart';
import 'package:musicpod/app/connectivity_notifier.dart';
import 'package:musicpod/app/globals.dart';
import 'package:musicpod/app/library_model.dart';
import 'package:musicpod/app/liked_audio_page.dart';
import 'package:musicpod/app/local_audio/album_page.dart';
import 'package:musicpod/app/local_audio/failed_imports_content.dart';
import 'package:musicpod/app/local_audio/local_audio_model.dart';
import 'package:musicpod/app/local_audio/local_audio_page.dart';
import 'package:musicpod/app/master_item.dart';
import 'package:musicpod/app/player/player_model.dart';
import 'package:musicpod/app/player/player_view.dart';
import 'package:musicpod/app/playlists/playlist_dialog.dart';
import 'package:musicpod/app/playlists/playlist_page.dart';
import 'package:musicpod/app/podcasts/podcast_model.dart';
import 'package:musicpod/app/podcasts/podcast_page.dart';
import 'package:musicpod/app/podcasts/podcasts_page.dart';
import 'package:musicpod/app/radio/radio_model.dart';
import 'package:musicpod/app/radio/radio_page.dart';
import 'package:musicpod/app/radio/station_page.dart';
import 'package:musicpod/app/settings/settings_tile.dart';
import 'package:musicpod/app/splash_screen.dart';
import 'package:musicpod/data/audio.dart';
import 'package:musicpod/l10n/l10n.dart';
import 'package:musicpod/service/library_service.dart';
import 'package:musicpod/service/local_audio_service.dart';
import 'package:musicpod/service/podcast_service.dart';
import 'package:musicpod/service/radio_service.dart';
import 'package:musicpod/utils.dart';
import 'package:provider/provider.dart';
import 'package:ubuntu_service/ubuntu_service.dart';
import 'package:yaru_icons/yaru_icons.dart';
import 'package:yaru_widgets/yaru_widgets.dart';

class App extends StatefulWidget {
  const App({super.key});

  static Widget create({
    required BuildContext context,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AppModel(),
        ),
        ChangeNotifierProvider(
          create: (_) => RadioModel(getService<RadioService>()),
        ),
        ChangeNotifierProvider(
          create: (_) => PlayerModel(getService<MPRIS>()),
        ),
        ChangeNotifierProvider(
          create: (_) => LocalAudioModel(getService<LocalAudioService>()),
        ),
        ChangeNotifierProvider(
          create: (_) => LibraryModel(getService<LibraryService>())..init(),
        ),
        ChangeNotifierProvider(
          create: (_) => PodcastModel(
            getService<PodcastService>(),
            getService<LibraryService>(),
            getService<Connectivity>(),
            getService<NotificationsClient>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => ConnectivityNotifier(
            getService<Connectivity>(),
          )..init(),
        )
      ],
      child: const App(),
    );
  }

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  String? _code;

  @override
  void initState() {
    super.initState();

    _code = WidgetsBinding.instance.platformDispatcher.locale.countryCode
        ?.toLowerCase();

    YaruWindow.of(context).onClose(
      () async {
        await context.read<PlayerModel>().dispose().then((_) async {
          await context.read<LibraryModel>().dispose().then((_) async {
            await resetAllServices();
          });
        });

        return true;
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (mounted) {
        context.read<PlayerModel>().init();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final light = theme.brightness == Brightness.light;
    final playerToTheRight = MediaQuery.of(context).size.width > 1700;

    // Connectivity
    final isOnline = context.select((ConnectivityNotifier c) => c.isOnline);

    // Local Audio
    final localAudioModel = context.read<LocalAudioModel>();
    final searchLocal = localAudioModel.search;
    final setLocalSearchQuery = localAudioModel.setSearchQuery;
    final setLocalSearchActive = localAudioModel.setSearchActive;

    // Podcasts
    final podcastModel = context.read<PodcastModel>();
    final searchPodcasts = podcastModel.search;
    final setPodcastSearchQuery = podcastModel.setSearchQuery;
    final setPodcastSearchActive = podcastModel.setSearchActive;

    // Radio
    final searchRadio = context.read<RadioModel>().search;
    final setRadioQuery = context.read<RadioModel>().setSearchQuery;
    final setRadioSearchActive = context.read<RadioModel>().setSearchActive;

    // Player
    final play = context.read<PlayerModel>().play;
    final audioType = context.select((PlayerModel m) => m.audio?.audioType);
    final surfaceTintColor =
        context.select((PlayerModel m) => m.surfaceTintColor);
    final isFullScreen = context.select((PlayerModel m) => m.fullScreen);

    // Library
    // Watching values
    final libraryModel = context.read<LibraryModel>();
    final localAudioIndex =
        context.select((LibraryModel m) => m.localAudioindex);
    final index = context.select((LibraryModel m) => m.index);
    final likedAudios = context.select((LibraryModel m) => m.likedAudios);
    final subbedPodcasts = context.select((LibraryModel m) => m.podcasts);
    final playlists = context.select((LibraryModel m) => m.playlists);
    final showPlaylists = context.select((LibraryModel m) => m.showPlaylists);
    final starredStations =
        context.select((LibraryModel m) => m.starredStations);
    final pinnedAlbums = context.select((LibraryModel m) => m.pinnedAlbums);
    final showSubbedPodcasts =
        context.select((LibraryModel m) => m.showSubbedPodcasts);
    final showStarredStations =
        context.select((LibraryModel m) => m.showStarredStations);
    final showPinnedAlbums =
        context.select((LibraryModel m) => m.showPinnedAlbums);
    final audioPageType = context.select((LibraryModel m) => m.audioPageType);
    final ready = context.select((LibraryModel m) => m.ready);
    context.select((LibraryModel m) => m.podcasts.length);
    context.select((LibraryModel m) => m.pinnedAlbums.length);
    context.select((LibraryModel m) => m.starredStations.length);
    context.select((LibraryModel m) => m.playlists.length);

    // Reading methods
    final totalListAmount = libraryModel.totalListAmount;
    final setIndex = libraryModel.setIndex;
    final setLocalAudioindex = libraryModel.setLocalAudioindex;
    final addPlaylist = libraryModel.addPlaylist;
    final addPodcast = libraryModel.addPodcast;
    final removePodcast = libraryModel.removePodcast;
    final removePlaylist = libraryModel.removePlaylist;
    final addPinnedAlbum = libraryModel.addPinnedAlbum;
    final isPinnedAlbum = libraryModel.isPinnedAlbum;
    final removePinnedAlbum = libraryModel.removePinnedAlbum;
    final unStarStation = libraryModel.unStarStation;
    final setAudioPageType = libraryModel.setAudioPageType;

    void onTextTap({
      required String text,
      AudioType audioType = AudioType.local,
    }) {
      switch (audioType) {
        case AudioType.local:
          setLocalSearchActive(true);
          setLocalSearchQuery(text);
          searchLocal();
          setIndex(0);
          break;
        case AudioType.podcast:
          setPodcastSearchActive(true);
          setPodcastSearchQuery(
            text,
          );
          searchPodcasts(searchQuery: text);
          setIndex(2);
          break;
        case AudioType.radio:
          setRadioSearchActive(true);
          setRadioQuery(text);
          searchRadio(name: text);
          setIndex(1);
          break;
      }
    }

    final masterItems = [
      MasterItem(
        tileBuilder: (context) => Text(context.l10n.localAudio),
        builder: (context) => LocalAudioPage(
          selectedIndex: localAudioIndex ?? 0,
          onIndexSelected: (i) => setLocalAudioindex(i),
        ),
        iconBuilder: (context, selected) => LocalAudioPageIcon(
          selected: selected,
          isPlaying: audioType == AudioType.local,
        ),
      ),
      MasterItem(
        tileBuilder: (context) => Text(context.l10n.radio),
        builder: (context) => RadioPage(
          countryCode: _code,
          isOnline: isOnline,
          onTextTap: (text) =>
              onTextTap(text: text, audioType: AudioType.radio),
        ),
        iconBuilder: (context, selected) => RadioPageIcon(
          selected: selected,
          isPlaying: audioType == AudioType.radio,
        ),
      ),
      MasterItem(
        tileBuilder: (context) => Text(context.l10n.podcasts),
        builder: (context) {
          return PodcastsPage(
            isOnline: isOnline,
            countryCode: _code,
          );
        },
        iconBuilder: (context, selected) => PodcastsPageIcon(
          selected: selected,
          isPlaying: audioType == AudioType.podcast,
        ),
      ),
      MasterItem(
        tileBuilder: (context) => const Padding(
          padding: EdgeInsets.only(top: 10, bottom: 10),
          child: Divider(
            height: 0,
          ),
        ),
        builder: (context) => const SizedBox.shrink(),
      ),
      MasterItem(
        iconBuilder: (context, selected) => const Icon(YaruIcons.plus),
        tileBuilder: (context) => Text(context.l10n.playlistDialogTitleNew),
        builder: (context) => const SizedBox.shrink(),
      ),
      MasterItem(
        tileBuilder: (context) => Text(context.l10n.likedSongs),
        builder: (context) => LikedAudioPage(
          onArtistTap: (artist) => onTextTap(text: artist),
          onAlbumTap: (album) => onTextTap(text: album),
          likedAudios: likedAudios,
        ),
        iconBuilder: (context, selected) =>
            LikedAudioPage.createIcon(context: context, selected: selected),
      ),
      MasterItem(
        tileBuilder: (context) => AudioPageFilterBar(
          mainPageType: mainPageType,
          audioPageType: audioPageType,
          setAudioPageType: setAudioPageType,
        ),
        builder: (context) => const SizedBox.shrink(),
      ),
      for (final podcast in subbedPodcasts.entries)
        MasterItem(
          tileBuilder: (context) => PodcastPage.createTitle(
            title: podcast.key,
            enabled: showSubbedPodcasts,
          ),
          builder: (context) => isOnline
              ? PodcastPage(
                  pageId: podcast.key,
                  audios: podcast.value,
                  onAlbumTap: (album) =>
                      onTextTap(text: album, audioType: AudioType.podcast),
                  onArtistTap: (artist) =>
                      onTextTap(text: artist, audioType: AudioType.podcast),
                  addPodcast: addPodcast,
                  removePodcast: removePodcast,
                  imageUrl: podcast.value.firstOrNull?.albumArtUrl ??
                      podcast.value.firstOrNull?.imageUrl,
                )
              : const OfflinePage(),
          iconBuilder: (context, selected) => PodcastPage.createIcon(
            context: context,
            imageUrl: podcast.value.firstOrNull?.albumArtUrl ??
                podcast.value.firstOrNull?.imageUrl,
            isOnline: isOnline,
            enabled: showSubbedPodcasts,
          ),
        ),
      for (final playlist in playlists.entries)
        MasterItem(
          tileBuilder: (context) => Opacity(
            opacity: showPlaylists ? 1 : 0.5,
            child: Text(playlist.key),
          ),
          builder: (context) => PlaylistPage(
            onAlbumTap: (album) => onTextTap(text: album),
            onArtistTap: (artist) => onTextTap(text: artist),
            playlist: playlist,
            unPinPlaylist: removePlaylist,
          ),
          iconBuilder: (context, selected) => Opacity(
            opacity: showPlaylists ? 1 : 0.5,
            child: const Icon(
              YaruIcons.playlist,
            ),
          ),
        ),
      for (final album in pinnedAlbums.entries)
        MasterItem(
          tileBuilder: (context) => Opacity(
            opacity: showPinnedAlbums ? 1 : 0.5,
            child: Text(createPlaylistName(album.key, context)),
          ),
          builder: (context) => AlbumPage(
            onArtistTap: (artist) => onTextTap(text: artist),
            onAlbumTap: (album) => onTextTap(text: album),
            album: album.value,
            name: album.key,
            addPinnedAlbum: addPinnedAlbum,
            isPinnedAlbum: isPinnedAlbum,
            removePinnedAlbum: removePinnedAlbum,
          ),
          iconBuilder: (context, selected) => AlbumPage.createIcon(
            context,
            album.value.firstOrNull?.pictureData,
            showPinnedAlbums,
          ),
        ),
      for (final station in starredStations.entries)
        MasterItem(
          tileBuilder: (context) => Opacity(
            opacity: showStarredStations ? 1 : 0.5,
            child: Text(station.key),
          ),
          builder: (context) => isOnline
              ? StationPage(
                  isStarred: true,
                  starStation: (station) {},
                  onTextTap: (text) =>
                      onTextTap(text: text, audioType: AudioType.radio),
                  unStarStation: unStarStation,
                  name: station.key,
                  station: station.value.first,
                  onPlay: (audio) => play(newAudio: audio),
                )
              : const OfflinePage(),
          iconBuilder: (context, selected) => StationPage.createIcon(
            context: context,
            imageUrl: station.value.first.imageUrl,
            selected: selected,
            isOnline: isOnline,
            enabled: showStarredStations,
          ),
        )
    ];

    final playerBg =
        surfaceTintColor ?? (light ? kBackGroundLight : kBackgroundDark);

    final yaruMasterDetailPage = YaruMasterDetailPage(
      navigatorKey: navigatorKey,
      onSelected: (value) => setIndex(value ?? 0),
      appBar: const YaruWindowTitleBar(
        backgroundColor: Colors.transparent,
        border: BorderSide.none,
        title: Text('MusicPod'),
      ),
      bottomBar: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: SettingsTile(
          onDirectorySelected: (directoryPath) async {
            localAudioModel.setDirectory(directoryPath).then(
                  (value) async => await localAudioModel.init(
                    forceInit: true,
                    onFail: (failedImports) =>
                        ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        duration: const Duration(seconds: 10),
                        content:
                            FailedImportsContent(failedImports: failedImports),
                      ),
                    ),
                  ),
                );
          },
        ),
      ),
      layoutDelegate: const YaruMasterFixedPaneDelegate(
        paneWidth: 250,
      ),
      breakpoint: 740,
      controller: YaruPageController(
        length: totalListAmount,
        initialIndex: index ?? 0,
      ),
      tileBuilder: (context, index, selected, availableWidth) {
        if (index == 3 || index == 6) {
          return masterItems[index].tileBuilder(context);
        } else if (index == 4) {
          return YaruMasterTile(
            selected: false,
            title: masterItems[index].tileBuilder(context),
            leading: masterItems[index].iconBuilder?.call(context, false),
            onTap: () => showDialog(
              context: context,
              builder: (context) {
                return PlaylistDialog(
                  playlistName: context.l10n.createNewPlaylist,
                  onCreateNewPlaylist: addPlaylist,
                );
              },
            ),
          );
        }
        return Padding(
          padding: index == 0 ? const EdgeInsets.only(top: 5) : EdgeInsets.zero,
          child: YaruMasterTile(
            title: masterItems[index].tileBuilder(context),
            leading: masterItems[index].iconBuilder == null
                ? null
                : masterItems[index].iconBuilder!(
                    context,
                    selected,
                  ),
          ),
        );
      },
      pageBuilder: (context, index) => YaruDetailPage(
        body: masterItems[index].builder(context),
      ),
    );

    final Widget body = Stack(
      alignment: Alignment.center,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: yaruMasterDetailPage,
                  ),
                  if (!playerToTheRight)
                    const Divider(
                      height: 0,
                    ),
                  if (!playerToTheRight)
                    Material(
                      color: playerBg,
                      child: PlayerView(
                        onTextTap: onTextTap,
                        playerViewMode: PlayerViewMode.bottom,
                      ),
                    )
                ],
              ),
            ),
            if (playerToTheRight)
              const VerticalDivider(
                width: 0,
              ),
            if (playerToTheRight)
              SizedBox(
                width: 500,
                child: Column(
                  children: [
                    const YaruWindowTitleBar(
                      backgroundColor: Colors.transparent,
                      border: BorderSide.none,
                    ),
                    Expanded(
                      child: PlayerView(
                        playerViewMode: PlayerViewMode.sideBar,
                        onTextTap: onTextTap,
                      ),
                    ),
                  ],
                ),
              )
          ],
        ),
        if (isFullScreen == true)
          Material(
            child: Material(
              color: playerBg,
              child: Column(
                children: [
                  const YaruWindowTitleBar(
                    border: BorderSide.none,
                    backgroundColor: Colors.transparent,
                  ),
                  Expanded(
                    child: PlayerView(
                      onTextTap: onTextTap,
                      playerViewMode: PlayerViewMode.fullWindow,
                    ),
                  )
                ],
              ),
            ),
          )
      ],
    );

    return Material(
      color: playerBg,
      child: ready ? body : const SplashScreen(),
    );
  }
}
