import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

import '../../../app.dart';
import '../../../constants.dart';
import '../../../globals.dart';
import '../../../l10n.dart';
import '../../../library.dart';

ScaffoldFeatureController<SnackBar, SnackBarClosedReason>
    showAddedToPlaylistSnackBar({
  required BuildContext context,
  required LibraryModel libraryModel,
  required String id,
}) {
  final index = libraryModel.getIndexOfPlaylist(id);
  ScaffoldMessenger.of(context).clearSnackBars();
  return ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        '${context.l10n.addedTo} ${id == kLikedAudiosPageId ? context.l10n.likedSongs : id}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      action: SnackBarAction(
        onPressed: () {
          final appModel = di<AppModel>();
          if (appModel.fullWindowMode == true) {
            appModel.setFullWindowMode(false);
          }
          navigatorKey.currentState
              ?.maybePop()
              .then((value) => libraryModel.setIndex(index));
        },
        label: context.l10n.open,
      ),
    ),
  );
}
