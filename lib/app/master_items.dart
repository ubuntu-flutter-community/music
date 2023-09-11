import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:musicpod/app/audio_page_filter_bar.dart';
import 'package:musicpod/app/common/audio_page.dart';
import 'package:musicpod/app/common/offline_page.dart';
import 'package:musicpod/app/common/spaced_divider.dart';
import 'package:musicpod/app/liked_audio_page.dart';
import 'package:musicpod/app/local_audio/album_page.dart';
import 'package:musicpod/app/local_audio/local_audio_page.dart';
import 'package:musicpod/app/master_item.dart';
import 'package:musicpod/app/playlists/playlist_page.dart';
import 'package:musicpod/app/podcasts/podcast_page.dart';
import 'package:musicpod/app/podcasts/podcasts_page.dart';
import 'package:musicpod/app/radio/radio_page.dart';
import 'package:musicpod/app/radio/station_page.dart';
import 'package:musicpod/data/audio.dart';
import 'package:musicpod/l10n/l10n.dart';
import 'package:yaru_icons/yaru_icons.dart';

List<MasterItem> createMasterItems({
  required int? localAudioIndex,
  required void Function(int? value) setLocalAudioindex,
  required AudioType? audioType,
  required bool isOnline,
  required void Function({required AudioType audioType, required String text})
      onTextTap,
  required Set<Audio> likedLocalAudios,
  required Set<Audio> likedPodcasts,
  required AudioPageType? audioPageType,
  required void Function(AudioPageType? value) setAudioPageType,
  required Map<String, Set<Audio>> subbedPodcasts,
  required bool showSubbedPodcasts,
  required void Function(String name, Set<Audio> audios) addPodcast,
  required void Function(String name) removePodcast,
  required Map<String, Set<Audio>> playlists,
  required bool showPlaylists,
  required void Function(String name) removePlaylist,
  required void Function(String oldName, String newName)? updatePlaylistName,
  required Map<String, Set<Audio>> pinnedAlbums,
  required bool showPinnedAlbums,
  required void Function(String name, Set<Audio> audios) addPinnedAlbum,
  required bool Function(String name) isPinnedAlbum,
  required void Function(String name) removePinnedAlbum,
  required Map<String, Set<Audio>> starredStations,
  required bool showStarredStations,
  required void Function(String name) unStarStation,
  required Future<void> Function({Duration? newPosition, Audio? newAudio}) play,
  required String? countryCode,
  required bool Function(String feedUrl) podcastUpdateAvailable,
  required bool showFilter,
  required bool checkingForPodcastUpdates,
}) {
  return [
    MasterItem(
      titleBuilder: (context) => Text(context.l10n.localAudio),
      pageBuilder: (context) => LocalAudioPage(
        selectedIndex: localAudioIndex ?? 0,
        onIndexSelected: (i) => setLocalAudioindex(i),
      ),
      iconBuilder: (context, selected) => LocalAudioPageIcon(
        selected: selected,
        isPlaying: audioType == AudioType.local,
      ),
    ),
    MasterItem(
      titleBuilder: (context) => Text(context.l10n.radio),
      pageBuilder: (context) => RadioPage(
        countryCode: countryCode,
        isOnline: isOnline,
        onTextTap: (text) => onTextTap(text: text, audioType: AudioType.radio),
      ),
      iconBuilder: (context, selected) => RadioPageIcon(
        selected: selected,
        isPlaying: audioType == AudioType.radio,
      ),
    ),
    MasterItem(
      titleBuilder: (context) => Text(context.l10n.podcasts),
      pageBuilder: (context) {
        return PodcastsPage(
          isOnline: isOnline,
          countryCode: countryCode,
        );
      },
      iconBuilder: (context, selected) => PodcastsPageIcon(
        selected: selected,
        checkingForUpdates: checkingForPodcastUpdates,
        isPlaying: audioType == AudioType.podcast,
      ),
    ),
    MasterItem(
      titleBuilder: (context) => const SpacedDivider(
        top: 10,
        bottom: 10,
        right: 0,
        left: 0,
      ),
      pageBuilder: (context) => const SizedBox.shrink(),
    ),
    MasterItem(
      iconBuilder: (context, selected) => const Icon(YaruIcons.plus),
      titleBuilder: (context) => Text(context.l10n.playlistDialogTitleNew),
      pageBuilder: (context) => const SizedBox.shrink(),
    ),
    MasterItem(
      titleBuilder: (context) => Text(context.l10n.likedSongs),
      pageBuilder: (context) => LikedAudioPage(
        onTextTap: onTextTap,
        likedLocalAudios: likedLocalAudios,
        likedPodcasts: likedPodcasts,
      ),
      iconBuilder: (context, selected) =>
          LikedAudioPage.createIcon(context: context, selected: selected),
    ),
    MasterItem(
      titleBuilder: (context) => showFilter
          ? AudioPageFilterBar(
              mainPageType: mainPageType,
              audioPageType: audioPageType,
              setAudioPageType: setAudioPageType,
            )
          : const SizedBox.shrink(),
      pageBuilder: (context) => const SizedBox.shrink(),
    ),
    if (showSubbedPodcasts)
      for (final podcast in subbedPodcasts.entries)
        MasterItem(
          titleBuilder: (context) => PodcastPage.createTitle(
            context: context,
            title: podcast.value.firstOrNull?.album ??
                podcast.value.firstOrNull?.title ??
                podcast.value.firstOrNull.toString(),
            update: podcastUpdateAvailable(podcast.key),
          ),
          pageBuilder: (context) => isOnline
              ? PodcastPage(
                  pageId: podcast.key,
                  title: podcast.value.firstOrNull?.album ??
                      podcast.value.firstOrNull?.title ??
                      podcast.value.firstOrNull.toString(),
                  audios: podcast.value,
                  onTextTap: onTextTap,
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
          ),
        ),
    if (showPlaylists)
      for (final playlist in playlists.entries)
        MasterItem(
          titleBuilder: (context) => Opacity(
            opacity: showPlaylists ? 1 : 0.5,
            child: Text(playlist.key),
          ),
          pageBuilder: (context) => PlaylistPage(
            onTextTap: onTextTap,
            playlist: playlist,
            unPinPlaylist: removePlaylist,
            updatePlaylistName: updatePlaylistName,
          ),
          iconBuilder: (context, selected) => const Icon(
            YaruIcons.playlist,
          ),
        ),
    if (showPinnedAlbums)
      for (final album in pinnedAlbums.entries)
        MasterItem(
          titleBuilder: (context) => Text(
            album.value.firstOrNull?.album ?? album.key,
          ),
          pageBuilder: (context) => AlbumPage(
            onTextTap: onTextTap,
            album: album.value,
            id: album.key,
            addPinnedAlbum: addPinnedAlbum,
            isPinnedAlbum: isPinnedAlbum,
            removePinnedAlbum: removePinnedAlbum,
          ),
          iconBuilder: (context, selected) => AlbumPage.createIcon(
            context,
            album.value.firstOrNull?.pictureData,
          ),
        ),
    if (showStarredStations)
      for (final station in starredStations.entries)
        MasterItem(
          titleBuilder: (context) => Text(station.key),
          pageBuilder: (context) => isOnline
              ? StationPage(
                  isStarred: true,
                  starStation: (station) {},
                  onTextTap: (text) =>
                      onTextTap(text: text, audioType: AudioType.radio),
                  unStarStation: unStarStation,
                  name: station.key,
                  station: station.value.first,
                  play: play,
                )
              : const OfflinePage(),
          iconBuilder: (context, selected) => StationPage.createIcon(
            context: context,
            imageUrl: station.value.first.imageUrl,
            selected: selected,
            isOnline: isOnline,
          ),
        ),
  ];
}
