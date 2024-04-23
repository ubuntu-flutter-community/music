import 'dart:io';

import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:flutter/material.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';

import '../../../media_file_x.dart';
import '../../../common.dart';
import '../../../constants.dart';
import '../../../data.dart';
import '../../../get.dart';
import '../../../library.dart';
import '../../../local_audio.dart';
import '../../../playlists.dart';
import '../../common/fall_back_header_image.dart';
import '../../l10n/l10n.dart';
import '../../theme.dart';
import 'playlst_add_audios_dialog.dart';

class PlaylistPage extends StatelessWidget {
  const PlaylistPage({
    super.key,
    required this.playlist,
  });

  final MapEntry<String, Set<Audio>> playlist;

  @override
  Widget build(BuildContext context) {
    final model = getIt<LocalAudioModel>();
    final libraryModel = getIt<LibraryModel>();
    final failedImports = <String>[];
    return DropRegion(
      formats: Formats.standardFormats,
      hitTestBehavior: HitTestBehavior.opaque,
      onDropEnded: (p0) {
        if (failedImports.isEmpty) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 10),
            content: FailedImportsContent(
              onNeverShowFailedImports: () {},
              failedImports: failedImports,
            ),
          ),
        );
      },
      onPerformDrop: (event) async {
        for (var item in event.session.items) {
          final reader = item.dataReader!;

          reader.getValue(
            Formats.fileUri,
            (value) {
              if (value == null) return;
              final file = File.fromUri(value);
              if (!file.isValidMedia) return;
              readMetadata(file, getImage: true).then(
                (data) {
                  libraryModel.addAudioToPlaylist(
                    playlist.key,
                    Audio.fromMetadata(path: file.path, data: data),
                  );
                },
              );
            },
            onError: (value) {
              failedImports.add(value.toString());
            },
          );
        }
      },
      onDropOver: (event) {
        if (event.session.allowedOperations.contains(DropOperation.copy)) {
          return DropOperation.copy;
        } else {
          return DropOperation.none;
        }
      },
      child: AudioPage(
        classicTiles: false,
        onAlbumTap: (text) {
          final albumAudios = model.findAlbum(Audio(album: text));
          if (albumAudios?.firstOrNull == null) return;
          final id = albumAudios!.first.albumId;
          if (id == null) return;

          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) {
                return AlbumPage(
                  id: id,
                  album: albumAudios,
                );
              },
            ),
          );
        },
        onArtistTap: (text) {
          final artistAudios = model.findArtist(Audio(artist: text));
          final images = model.findImages(artistAudios ?? {});

          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) {
                return ArtistPage(
                  images: images,
                  artistAudios: artistAudios,
                );
              },
            ),
          );
        },
        audioPageType: AudioPageType.playlist,
        image: PlaylistHeaderImage(playlist: playlist),
        headerLabel: context.l10n.playlist,
        headerTitle: playlist.key,
        audios: playlist.value,
        pageId: playlist.key,
        noResultMessage: Text(context.l10n.emptyPlaylist),
        controlPanelButton: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: context.l10n.editPlaylist,
              icon: Icon(Iconz().pen),
              onPressed: () => showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  content: SizedBox(
                    height: 200,
                    width: 500,
                    child: PlaylistContent(
                      playlistName: playlist.key,
                      initialValue: playlist.key,
                      allowDelete: true,
                      allowRename: true,
                      libraryModel: libraryModel,
                    ),
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: context.l10n.clearPlaylist,
              icon: Icon(Iconz().clearAll),
              onPressed: () => libraryModel.clearPlaylist(playlist.key),
            ),
            IconButton(
              tooltip: context.l10n.add,
              icon: Icon(Iconz().plus),
              onPressed: () => showDialog(
                context: context,
                builder: (context) =>
                    PlaylistAddAudiosDialog(playlistId: playlist.key),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PlaylistHeaderImage extends StatelessWidget {
  const PlaylistHeaderImage({
    super.key,
    required this.playlist,
  });

  final MapEntry<String, Set<Audio>> playlist;

  @override
  Widget build(BuildContext context) {
    final model = getIt<LocalAudioModel>();
    final playlistImages = model.findImages(playlist.value);
    final length = playlistImages == null ? 0 : playlistImages.take(16).length;

    final padding = length == 1 ? 0.0 : 8.0;
    final spacing = length == 1 ? 0.0 : 16.0;
    final width = length == 1
        ? kMaxAudioPageHeaderHeight
        : length < 10
            ? 50.0
            : 32.0;
    final height = length == 1
        ? kMaxAudioPageHeaderHeight
        : length < 10
            ? 50.0
            : 32.0;
    final radius = length == 1 ? 0.0 : width / 2;

    Widget image;
    if (length == 0) {
      image = Icon(
        Iconz().playlist,
        size: 65,
      );
    } else {
      image = Center(
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: List.generate(
              length,
              (index) => ClipRRect(
                borderRadius: BorderRadius.circular(radius),
                child: Image.memory(
                  playlistImages!.elementAt(index),
                  width: width,
                  height: height,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.medium,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return FallBackHeaderImage(
      color: getAlphabetColor(playlist.key),
      child: image,
    );
  }
}
