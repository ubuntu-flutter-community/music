import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:popover/popover.dart';

import '../../build_context_x.dart';
import '../../common.dart';
import '../../constants.dart';
import '../../data.dart';
import '../../globals.dart';
import '../../player.dart';
import 'bottom_player_image.dart';
import 'bottom_player_title_artist.dart';
import 'very_narrow_bottom_player.dart';

const kBottomPlayerHeight = 90.0;

class BottomPlayer extends StatelessWidget {
  const BottomPlayer({
    super.key,
    required this.setFullScreen,
    required this.audio,
    required this.playPrevious,
    required this.playNext,
    this.isVideo,
    required this.videoController,
    required this.isOnline,
  });

  final Audio? audio;

  final Future<void> Function() playPrevious;
  final Future<void> Function() playNext;

  final void Function(bool?) setFullScreen;

  final bool? isVideo;
  final VideoController videoController;
  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    final theme = context.t;
    final veryNarrow = context.m.size.width < kMasterDetailBreakPoint;
    final active = audio?.path != null || isOnline;

    final bottomPlayerImage = BottomPlayerImage(
      audio: audio,
      size: kBottomPlayerHeight - (veryNarrow ? 20 : 0),
      videoController: videoController,
      isVideo: isVideo,
      isOnline: isOnline,
    );

    final titleAndArtist = BottomPlayerTitleArtist(
      audio: audio,
    );

    final bottomPlayerControls = BottomPlayerControls(
      playPrevious: playPrevious,
      playNext: playNext,
      onFullScreenTap: () => setFullScreen(true),
      active: active,
      showPlaybackRate: audio?.audioType == AudioType.podcast,
    );

    final track = PlayerTrack(
      veryNarrow: veryNarrow,
      active: active,
    );

    if (veryNarrow) {
      final veryNarrowBottomPlayer = VeryNarrowBottomPlayer(
        setFullScreen: setFullScreen,
        bottomPlayerImage: bottomPlayerImage,
        titleAndArtist: titleAndArtist,
        active: active,
        isOnline: isOnline,
        track: track,
      );
      return isMobile
          ? GestureDetector(
              onVerticalDragEnd: (details) {
                if (details.primaryVelocity != null &&
                    details.primaryVelocity! < 150) {
                  setFullScreen(true);
                }
              },
              child: veryNarrowBottomPlayer,
            )
          : veryNarrowBottomPlayer;
    }

    return SizedBox(
      height: kBottomPlayerHeight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          bottomPlayerImage,
          const SizedBox(
            width: 20,
          ),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Flexible(
                  flex: 5,
                  child: titleAndArtist,
                ),
                const SizedBox(
                  width: 5,
                ),
                Flexible(
                  child: LikeIconButton(
                    audio: audio,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(
            width: 10,
          ),
          Expanded(
            flex: 6,
            child: Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 10),
              child: Column(
                children: [
                  bottomPlayerControls,
                  const SizedBox(
                    height: 8,
                  ),
                  track,
                ],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const VolumeSliderPopup(
                  direction: PopoverDirection.top,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 5),
                  child: QueueButton(),
                ),
                IconButton(
                  icon: Icon(
                    Iconz().fullScreen,
                    color: theme.colorScheme.onSurface,
                  ),
                  onPressed: () => setFullScreen(true),
                ),
              ],
            ),
          ),
          const SizedBox(
            width: 10,
          ),
        ],
      ),
    );
  }
}
