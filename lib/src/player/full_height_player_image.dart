import 'package:flutter/material.dart';

import '../../build_context_x.dart';
import '../../common.dart';
import '../../constants.dart';
import '../../data.dart';
import '../../theme_data_x.dart';

class FullHeightPlayerImage extends StatelessWidget {
  const FullHeightPlayerImage({
    super.key,
    this.audio,
    required this.isOnline,
    required this.size,
  });

  final Audio? audio;
  final bool isOnline;
  final Size size;

  @override
  Widget build(BuildContext context) {
    final theme = context.t;

    IconData iconData;
    if (audio?.audioType == AudioType.radio) {
      iconData = Iconz().radio;
    } else if (audio?.audioType == AudioType.podcast) {
      iconData = Iconz().podcast;
    } else {
      iconData = Iconz().musicNote;
    }

    Widget image;
    if (audio?.pictureData != null) {
      image = Image.memory(
        audio!.pictureData!,
        height: size.height,
        fit: BoxFit.fitWidth,
      );
    } else {
      if (!isOnline) {
        image = Icon(
          iconData,
          size: fullHeightPlayerImageSize * 0.7,
          color: theme.hintColor,
        );
      } else if (audio?.imageUrl != null || audio?.albumArtUrl != null) {
        image = Container(
          height: size.width,
          width: size.width,
          color: theme.isLight ? kCardColorLight : kCardColorDark,
          child: SafeNetworkImage(
            url: audio?.imageUrl ?? audio?.albumArtUrl,
            filterQuality: FilterQuality.medium,
            fit: BoxFit.scaleDown,
            fallBackIcon: Icon(
              iconData,
              size: fullHeightPlayerImageSize * 0.7,
              color: theme.hintColor,
            ),
            height: size.width,
            width: size.width,
          ),
        );
      } else {
        image = Icon(
          iconData,
          size: fullHeightPlayerImageSize * 0.7,
          color: theme.hintColor.withOpacity(0.4),
        );
      }
    }

    return SizedBox(
      height: fullHeightPlayerImageSize,
      width: fullHeightPlayerImageSize,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: image,
      ),
    );
  }
}
