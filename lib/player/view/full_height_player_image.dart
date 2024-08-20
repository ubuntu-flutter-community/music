import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

import '../../constants.dart';
import '../../local_audio/view/local_cover.dart';
import '../player_model.dart';
import 'player_fall_back_image.dart';
import 'player_remote_source_image.dart';

class FullHeightPlayerImage extends StatelessWidget with WatchItMixin {
  const FullHeightPlayerImage({
    super.key,
    this.fit,
    this.height,
    this.width,
    this.borderRadius,
  });

  final BoxFit? fit;
  final double? height, width;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final audio = watchPropertyValue((PlayerModel m) => m.audio);

    final mpvMetaData = watchPropertyValue((PlayerModel m) => m.mpvMetaData);

    final fallBackImage = PlayerFallBackImage(
      key: const ValueKey(0),
      audio: audio,
      height: height ?? fullHeightPlayerImageSize,
      width: width ?? fullHeightPlayerImageSize,
    );

    Widget image;
    if (audio?.hasPathAndId == true) {
      image = LocalCover(
        key: ValueKey(audio!.path),
        albumId: audio.albumId!,
        path: audio.path!,
        width: width,
        height: height,
        fit: fit ?? BoxFit.fitHeight,
        fallback: fallBackImage,
      );
    } else {
      if (mpvMetaData?.icyTitle != null ||
          audio?.albumArtUrl != null ||
          audio?.imageUrl != null) {
        image = PlayerRemoteSourceImage(
          mpvMetaData: mpvMetaData,
          key: ValueKey(
            (mpvMetaData?.icyTitle ?? '') +
                (audio?.imageUrl ?? '') +
                (audio?.albumArtUrl ?? ''),
          ),
          height: height ?? fullHeightPlayerImageSize,
          width: width ?? fullHeightPlayerImageSize,
          audio: audio,
          fit: fit,
          fallBackIcon: fallBackImage,
          errorIcon: fallBackImage,
        );
      } else {
        image = fallBackImage;
      }
    }

    return SizedBox(
      height: height ?? fullHeightPlayerImageSize,
      width: width ?? fullHeightPlayerImageSize,
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(10),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: image,
        ),
      ),
    );
  }
}
