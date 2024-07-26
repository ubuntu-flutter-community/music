import 'dart:io';

import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';
import 'package:watch_it/watch_it.dart';
import 'package:yaru/yaru.dart';

import '../../app/app_model.dart';
import '../../common/data/audio.dart';
import '../../common/view/adaptive_container.dart';
import '../../common/view/audio_page_header.dart';
import '../../common/view/audio_page_type.dart';
import '../../common/view/audio_tile.dart';
import '../../common/view/avatar_play_button.dart';
import '../../common/view/common_widgets.dart';
import '../../common/view/fall_back_header_image.dart';
import '../../common/view/icons.dart';
import '../../common/view/sliver_audio_page_control_panel.dart';
import '../../common/view/sliver_audio_tile_list.dart';
import '../../common/view/tapable_text.dart';
import '../../common/view/theme.dart';
import '../../constants.dart';
import '../../extensions/build_context_x.dart';
import '../../extensions/media_file_x.dart';
import '../../extensions/theme_data_x.dart';
import '../../l10n/l10n.dart';
import '../../library/library_model.dart';
import '../../local_audio/local_audio_model.dart';
import '../../local_audio/view/album_page.dart';
import '../../local_audio/view/artist_page.dart';
import '../../local_audio/view/genre_page.dart';
import '../../player/player_model.dart';
import 'manual_add_dialog.dart';
import 'playlst_add_audios_dialog.dart';

class PlaylistPage extends StatelessWidget {
  const PlaylistPage({
    super.key,
    required this.playlist,
  });

  final MapEntry<String, Set<Audio>> playlist;

  @override
  Widget build(BuildContext context) {
    final model = di<LocalAudioModel>();
    final libraryModel = di<LibraryModel>();
    return DropRegion(
      formats: Formats.standardFormats,
      hitTestBehavior: HitTestBehavior.opaque,
      onDropEnded: (e) async {
        Future.delayed(
          const Duration(milliseconds: 300),
        ).then(
          (_) => libraryModel.updatePlaylist(playlist.key, playlist.value),
        );
      },
      onPerformDrop: (e) async {
        for (var item in e.session.items.take(100)) {
          item.dataReader?.getValue(
            Formats.fileUri,
            (value) async {
              if (value == null) return;
              final file = File.fromUri(value);
              if (file.isValidMedia) {
                final data = await readMetadata(file, getImage: true);
                var audio = Audio.fromMetadata(path: file.path, data: data);
                playlist.value.add(audio);
              }
            },
            onError: (_) {},
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
      child: YaruDetailPage(
        appBar: HeaderBar(
          adaptive: true,
          title: Text(playlist.key),
        ),
        body: _PlaylistPageBody(
          onAlbumTap: (text) {
            final albumAudios = model.findAlbum(Audio(album: text));
            if (albumAudios?.firstOrNull == null) return;
            final id = albumAudios!.first.albumId;
            if (id == null) return;
            di<LibraryModel>().push(
              builder: (_) {
                return AlbumPage(
                  id: id,
                  album: albumAudios,
                );
              },
              pageId: id,
            );
          },
          onArtistTap: (text) {
            final artistAudios = model.findArtist(Audio(artist: text));
            final artist = artistAudios?.firstOrNull?.artist;
            if (artist == null) return;
            final images = model.findImages(artistAudios ?? {});

            di<LibraryModel>().push(
              builder: (_) {
                return ArtistPage(
                  images: images,
                  artistAudios: artistAudios,
                );
              },
              pageId: artist,
            );
          },
          image: PlaylistHeaderImage(playlist: playlist),
          audios: playlist.value,
          pageId: playlist.key,
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
    final model = di<LocalAudioModel>();
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

class _PlaylistPageBody extends StatelessWidget with WatchItMixin {
  const _PlaylistPageBody({
    required this.pageId,
    required this.audios,
    this.image,
    this.onAlbumTap,
    this.onArtistTap,
  });

  final String pageId;
  final Set<Audio> audios;
  final Widget? image;

  final void Function(String text)? onAlbumTap;
  final void Function(String text)? onArtistTap;

  @override
  Widget build(BuildContext context) {
    final allowReorder = watchPropertyValue((AppModel m) => m.allowReorder);
    final isPlaying = watchPropertyValue((PlayerModel m) => m.isPlaying);
    final libraryModel = di<LibraryModel>();
    final playerModel = di<PlayerModel>();
    final currentAudio = watchPropertyValue((PlayerModel m) => m.audio);

    watchPropertyValue(
      (LibraryModel m) => m.playlists[pageId]?.length,
    );

    final audioControlPanel = Row(
      mainAxisAlignment: MainAxisAlignment.center,
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
                  playlistName: pageId,
                  initialValue: pageId,
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
          onPressed: () => libraryModel.clearPlaylist(pageId),
        ),
        AvatarPlayButton(audios: audios, pageId: pageId),
        IconButton(
          tooltip: context.l10n.add,
          icon: Icon(Iconz().plus),
          onPressed: () => showDialog(
            context: context,
            builder: (context) => PlaylistAddAudiosDialog(playlistId: pageId),
          ),
        ),
        IconButton(
          tooltip: context.l10n.move,
          isSelected: allowReorder,
          onPressed: () => di<AppModel>().setAllowReorder(!allowReorder),
          icon: Icon(
            Iconz().reorder,
            color: allowReorder ? context.t.colorScheme.primary : null,
          ),
        ),
      ],
    );

    final audioPageHeader = AudioPageHeader(
      title: pageId,
      subTitle: '${audios.length} ${context.l10n.titles}',
      image: image,
      label: context.l10n.playlist,
      description: _PlaylistGenreBar(audios: audios),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: audioPageHeader,
            ),
            SliverAudioPageControlPanel(controlPanel: audioControlPanel),
            if (allowReorder)
              SliverReorderableList(
                itemCount: audios.length,
                itemBuilder: (BuildContext context, int index) {
                  final audio = audios.elementAt(index);
                  final audioSelected = currentAudio == audio;

                  return ReorderableDragStartListener(
                    key: ValueKey(audio.path ?? audio.url),
                    index: index,
                    child: AudioTile(
                      onSubTitleTap: onArtistTap,
                      key: ValueKey(audio.path ?? audio.url),
                      isPlayerPlaying: isPlaying,
                      pause: playerModel.pause,
                      startPlaylist: () => playerModel.startPlaylist(
                        audios: audios,
                        listName: pageId,
                        index: index,
                      ),
                      resume: playerModel.resume,
                      selected: audioSelected,
                      audio: audio,
                      insertIntoQueue: playerModel.insertIntoQueue,
                      pageId: pageId,
                      libraryModel: libraryModel,
                      audioPageType: AudioPageType.playlist,
                    ),
                  );
                },
                onReorder: (oldIndex, newIndex) {
                  if (playerModel.queueName == pageId) {
                    playerModel.moveAudioInQueue(oldIndex, newIndex);
                  }

                  libraryModel.moveAudioInPlaylist(
                    oldIndex: oldIndex,
                    newIndex: newIndex,
                    id: pageId,
                  );
                },
              )
            else
              SliverPadding(
                padding: getAdaptiveHorizontalPadding(constraints),
                sliver: SliverAudioTileList(
                  audios: audios,
                  pageId: pageId,
                  audioPageType: AudioPageType.playlist,
                  onSubTitleTab: onArtistTap,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _PlaylistGenreBar extends StatelessWidget {
  const _PlaylistGenreBar({
    required this.audios,
  });

  final Set<Audio> audios;

  @override
  Widget build(BuildContext context) {
    final style = context.t.pageHeaderDescription;
    Set<String> genres = {};
    for (var e in audios) {
      final g = e.genre?.trim();
      if (g?.isNotEmpty == true) {
        genres.add(g!);
      }
    }

    return SingleChildScrollView(
      child: Wrap(
        alignment: WrapAlignment.center,
        runAlignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: genres
            .mapIndexed(
              (i, e) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TapAbleText(
                    style: style,
                    wrapInFlexible: false,
                    text: e,
                    onTap: () {
                      di<LibraryModel>().push(
                        builder: (context) => GenrePage(genre: e),
                        pageId: e,
                      );
                    },
                  ),
                  if (i != genres.length - 1) const Text(' · '),
                ],
              ),
            )
            .toList(),
      ),
    );
  }
}
