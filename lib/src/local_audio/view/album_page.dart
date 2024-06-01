import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

import '../../../build_context_x.dart';
import '../../../common.dart';
import '../../../data.dart';
import '../../../library.dart';
import '../../../local_audio.dart';
import '../../../theme.dart';
import '../../common/explore_online_popup.dart';
import '../../common/sliver_audio_page.dart';
import '../../l10n/l10n.dart';

class AlbumPage extends StatelessWidget {
  const AlbumPage({
    super.key,
    required this.id,
    required this.album,
  });

  final String id;
  final Set<Audio> album;

  @override
  Widget build(BuildContext context) {
    final model = di<LocalAudioModel>();
    final pictureData =
        album.firstWhereOrNull((e) => e.pictureData != null)?.pictureData;

    void onArtistTap(text) {
      final artistName = album.firstOrNull?.artist;
      if (artistName == null) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) {
            final artistAudios = model.findArtist(album.first);
            final images = model.findImages(artistAudios ?? {});

            return ArtistPage(
              images: images,
              artistAudios: artistAudios,
            );
          },
        ),
      );
    }

    return SliverAudioPage(
      pageId: id,
      audioPageType: AudioPageType.album,
      audios: album,
      image: AlbumPageImage(pictureData: pictureData),
      pageTitle: album.firstWhereOrNull((e) => e.album != null)?.album,
      pageSubTitle: album.firstWhereOrNull((e) => e.artist != null)?.artist,
      onPageLabelTab: onArtistTap,
      onPageSubTitleTab: onArtistTap,
      controlPanel: AlbumPageControlButton(album: album, id: id),
    );
  }
}

class AlbumPageSideBarIcon extends StatelessWidget {
  const AlbumPageSideBarIcon({super.key, this.picture, this.album});

  final Uint8List? picture;
  final String? album;

  @override
  Widget build(BuildContext context) {
    if (picture == null) {
      return SideBarFallBackImage(
        child: Icon(
          Iconz().startPlayList,
          color: getAlphabetColor(album ?? 'c'),
        ),
      );
    }

    return SizedBox.square(
      dimension: sideBarImageSize,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: Image.memory(
          picture!,
          height: sideBarImageSize,
          fit: BoxFit.fitHeight,
          filterQuality: FilterQuality.medium,
        ),
      ),
    );
  }
}

class AlbumPageImage extends StatelessWidget {
  const AlbumPageImage({
    super.key,
    required this.pictureData,
  });

  final Uint8List? pictureData;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: BoxDecoration(
            color: context.t.cardColor,
            image: const DecorationImage(
              image: AssetImage('assets/images/media-optical.png'),
            ),
          ),
        ),
        if (pictureData != null)
          Align(
            alignment: Alignment.centerLeft,
            child: Image.memory(
              pictureData!,
              fit: BoxFit.fitHeight,
              filterQuality: FilterQuality.medium,
            ),
          ),
      ],
    );
  }
}

class AlbumPageControlButton extends StatelessWidget {
  const AlbumPageControlButton({
    super.key,
    required this.id,
    required this.album,
  });

  final String id;
  final Set<Audio> album;

  @override
  Widget build(BuildContext context) {
    final libraryModel = di<LibraryModel>();
    final pinnedAlbum = libraryModel.isPinnedAlbum(id);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AvatarPlayButton(audios: album, pageId: id),
        const SizedBox(
          width: 10,
        ),
        IconButton(
          tooltip: context.l10n.pinAlbum,
          isSelected: libraryModel.isPinnedAlbum(id),
          icon: Icon(
            pinnedAlbum ? Iconz().pinFilled : Iconz().pin,
            color: pinnedAlbum ? context.t.colorScheme.primary : null,
          ),
          onPressed: () {
            if (libraryModel.isPinnedAlbum(id)) {
              libraryModel.removePinnedAlbum(id);
            } else {
              libraryModel.addPinnedAlbum(id, album);
            }
          },
        ),
        ExploreOnlinePopup(
          text: '${album.firstOrNull?.artist} - ${album.firstOrNull?.album}',
        ),
      ],
    );
  }
}
