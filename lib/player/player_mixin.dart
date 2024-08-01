import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:watch_it/watch_it.dart';

import '../app/app_model.dart';
import '../common/data/audio.dart';
import '../common/view/copy_clipboard_content.dart';
import '../common/view/snackbars.dart';
import '../library/library_model.dart';
import '../local_audio/local_audio_model.dart';
import '../local_audio/view/album_page.dart';
import '../local_audio/view/artist_page.dart';
import '../podcasts/podcast_utils.dart';
import '../radio/view/station_page.dart';

mixin PlayerMixin {
  String getSubTitle(Audio? audio) =>
      switch (audio?.audioType) {
        AudioType.podcast => audio?.album,
        AudioType.radio => audio?.title,
        _ => audio?.artist
      } ??
      '';

  String getTitle({required Audio? audio, required String? icyTitle}) =>
      icyTitle?.isNotEmpty == true && audio?.audioType == AudioType.radio
          ? icyTitle!
          : (audio?.title?.isNotEmpty == true ? audio!.title! : '');

  void onTitleTap({
    Audio? audio,
    String? text,
    required BuildContext context,
  }) {
    if (text?.isNotEmpty == true && audio?.audioType == AudioType.radio ||
        audio?.audioType == null) {
      showSnackBar(
        context: context,
        content: CopyClipboardContent(text: text!),
      );
      return;
    }

    switch (audio?.audioType) {
      case AudioType.local:
        _onLocalAudioTitleTap(
          audio: audio!,
        );
        return;
      case AudioType.radio:
      case AudioType.podcast:
        if (audio?.url == null) return;
        showSnackBar(
          context: context,
          content: CopyClipboardContent(
            text: audio!.url!,
            onSearch: () => launchUrl(Uri.parse(audio.url!)),
          ),
        );
        return;
      default:
        return;
    }
  }

  void _onLocalAudioTitleTap({required Audio audio}) {
    final localAudioModel = di<LocalAudioModel>();
    final albumAudios = localAudioModel.findAlbum(audio);
    if (albumAudios?.firstOrNull == null) return;
    final id = albumAudios!.first.albumId;
    if (id == null) return;

    di<AppModel>().setFullWindowMode(false);

    final libraryModel = di<LibraryModel>();
    libraryModel.push(
      builder: (_) => AlbumPage(
        id: id,
        album: albumAudios,
      ),
      pageId: id,
    );
  }

  void onArtistTap({required Audio audio, required BuildContext context}) {
    switch (audio.audioType) {
      case AudioType.local:
        _onLocalAudioArtistTap(
          audio: audio,
        );
        return;
      case AudioType.radio:
        _onRadioArtistTap(audio);
        return;
      case AudioType.podcast:
        _onPodcastArtistTap(
          audio: audio,
          context: context,
        );
        return;
      default:
        return;
    }
  }

  void _onRadioArtistTap(Audio audio) {
    final libraryModel = di<LibraryModel>();
    if (audio.url == null) return;
    libraryModel.push(
      builder: (_) => StationPage(station: audio),
      pageId: audio.url!,
    );
  }

  void _onPodcastArtistTap({
    required Audio audio,
    required BuildContext context,
  }) {
    final libraryModel = di<LibraryModel>();
    if (audio.website != null &&
        libraryModel.isPodcastSubscribed(audio.website)) {
      libraryModel.pushNamed(pageId: audio.website!);
    } else {
      searchAndPushPodcastPage(
        context: context,
        feedUrl: audio.website,
        itemImageUrl: audio.albumArtUrl,
        genre: audio.genre,
        play: false,
      );
    }
  }

  void _onLocalAudioArtistTap({required Audio audio}) {
    final localAudioModel = di<LocalAudioModel>();
    final artistName = audio.artist;
    if (artistName == null) return;
    final artistAudios = localAudioModel.findTitlesOfArtist(artistName);
    final artist = artistAudios?.firstOrNull?.artist;
    if (artist == null) return;
    final images = localAudioModel.findImages(artistAudios ?? {});
    di<AppModel>().setFullWindowMode(false);

    di<LibraryModel>().push(
      builder: (_) => ArtistPage(
        artistAudios: artistAudios,
        images: images,
      ),
      pageId: artist,
    );
  }
}
