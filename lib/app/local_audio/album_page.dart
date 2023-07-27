import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:musicpod/app/common/audio_page.dart';
import 'package:musicpod/app/common/constants.dart';
import 'package:musicpod/data/audio.dart';
import 'package:musicpod/l10n/l10n.dart';
import 'package:yaru_icons/yaru_icons.dart';
import 'package:yaru_widgets/yaru_widgets.dart';

class AlbumPage extends StatelessWidget {
  const AlbumPage({
    super.key,
    required this.name,
    required this.isPinnedAlbum,
    required this.removePinnedAlbum,
    required this.album,
    required this.addPinnedAlbum,
    this.onArtistTap,
    this.onAlbumTap,
  });

  static Widget createIcon(
    BuildContext context,
    Uint8List? picture,
    bool enabled,
  ) {
    Widget? albumArt;
    if (picture != null) {
      albumArt = SizedBox(
        width: kSideBarIconSize,
        height: kSideBarIconSize,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: Image.memory(
            picture,
            height: kSideBarIconSize,
            fit: BoxFit.fitHeight,
            filterQuality: FilterQuality.medium,
          ),
        ),
      );
    }
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: albumArt ??
          const Icon(
            YaruIcons.playlist_play,
          ),
    );
  }

  final String? name;
  final bool Function(String name) isPinnedAlbum;
  final void Function(String name) removePinnedAlbum;
  final Set<Audio>? album;
  final void Function(String name, Set<Audio> audios) addPinnedAlbum;
  final void Function(String artist)? onArtistTap;
  final void Function(String album)? onAlbumTap;

  @override
  Widget build(BuildContext context) {
    return AudioPage(
      onAlbumTap: onAlbumTap,
      onArtistTap: onArtistTap,
      audioPageType: AudioPageType.album,
      pageLabel: context.l10n.album,
      pageSubtile: album?.firstOrNull?.artist,
      image: album?.firstOrNull?.pictureData != null
          ? Image.memory(
              album!.firstOrNull!.pictureData!,
              width: 200.0,
              fit: BoxFit.fitWidth,
              filterQuality: FilterQuality.medium,
            )
          : null,
      controlPageButton: name == null
          ? null
          : isPinnedAlbum(name!)
              ? YaruIconButton(
                  icon: Icon(
                    YaruIcons.pin,
                    color: Theme.of(context).primaryColor,
                  ),
                  onPressed: () => removePinnedAlbum(
                    name!,
                  ),
                )
              : YaruIconButton(
                  icon: const Icon(
                    YaruIcons.pin,
                  ),
                  onPressed: album == null
                      ? null
                      : () => addPinnedAlbum(
                            name!,
                            album!,
                          ),
                ),
      deletable: false,
      audios: album,
      pageId: name!,
      editableName: false,
    );
  }
}
