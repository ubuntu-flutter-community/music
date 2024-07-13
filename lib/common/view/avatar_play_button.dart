import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

import '../../extensions/build_context_x.dart';
import '../../l10n/l10n.dart';
import '../../player/player_model.dart';
import '../data/audio.dart';
import 'common_widgets.dart';
import 'icons.dart';

class AvatarPlayButton extends StatelessWidget with WatchItMixin {
  const AvatarPlayButton({
    super.key,
    required this.audios,
    required this.pageId,
  });

  final Set<Audio> audios;
  final String pageId;

  @override
  Widget build(BuildContext context) {
    final theme = context.t;
    final playerModel = di<PlayerModel>();
    final isPlayerPlaying = watchPropertyValue((PlayerModel m) => m.isPlaying);
    final pageIsQueue = watchPropertyValue(
      (PlayerModel m) => m.queueName != null && m.queueName == pageId,
    );
    final iconData =
        isPlayerPlaying && pageIsQueue ? Iconz().pause : Iconz().play;

    return CircleAvatar(
      radius: avatarIconSize,
      backgroundColor: theme.colorScheme.inverseSurface,
      child: IconButton(
        tooltip: context.l10n.playAll,
        onPressed: () {
          if (isPlayerPlaying) {
            if (pageIsQueue) {
              playerModel.pause();
            } else {
              playerModel.startPlaylist(
                audios: audios,
                listName: pageId,
              );
            }
          } else {
            if (pageIsQueue) {
              playerModel.resume();
            } else {
              playerModel.startPlaylist(
                audios: audios,
                listName: pageId,
              );
            }
          }
        },
        icon: Icon(
          iconData,
          color: theme.colorScheme.onInverseSurface,
        ),
      ),
    );
  }
}
