import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yaru/yaru.dart';

import '../../app.dart';
import '../../build_context_x.dart';
import '../../common.dart';
import '../../constants.dart';
import '../../data.dart';
import '../../globals.dart';
import '../../player.dart';
import '../../radio.dart';
import '../../theme.dart';
import '../../theme_data_x.dart';
import 'super_network_image.dart';

class FullHeightPlayerImage extends ConsumerWidget {
  const FullHeightPlayerImage({
    super.key,
    this.audio,
    required this.isOnline,
    this.fit,
    this.height,
    this.width,
    this.borderRadius,
  });

  final Audio? audio;
  final bool isOnline;
  final BoxFit? fit;
  final double? height, width;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.t;

    final mpvMetaData =
        ref.watch(playerModelProvider.select((m) => m.mpvMetaData));

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
        height: height ?? fullHeightPlayerImageSize,
        width: width ?? fullHeightPlayerImageSize,
        fit: fit ?? BoxFit.fitHeight,
      );
    } else {
      if (!isOnline) {
        image = Icon(
          iconData,
          size: fullHeightPlayerImageSize * 0.7,
          color: theme.hintColor,
        );
      } else if (audio?.imageUrl != null || audio?.albumArtUrl != null) {
        image = SuperNetworkImage(
          height: height ?? fullHeightPlayerImageSize,
          width: width ?? fullHeightPlayerImageSize,
          audio: audio,
          fit: fit,
          iconData: iconData,
          theme: theme,
          mpvMetaData: mpvMetaData,
          iconSize: fullHeightPlayerImageSize * 0.7,
          onImageFind: (url) =>
              ref.read(playerModelProvider).loadColor(url: url),
          onGenreTap: (genre) => ref.read(radioModelProvider).init().then(
            (_) {
              ref.read(appModelProvider).setFullScreen(false);
              navigatorKey.currentState?.push(
                MaterialPageRoute(
                  builder: (context) {
                    return RadioSearchPage(
                      radioSearch: RadioSearch.tag,
                      searchQuery: genre.toLowerCase(),
                    );
                  },
                ),
              );
            },
          ),
        );
      } else {
        image = Container(
          height: height ?? fullHeightPlayerImageSize,
          width: width ?? fullHeightPlayerImageSize,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomLeft,
              end: Alignment.topRight,
              colors: [
                getAlphabetColor(
                  audio?.title ?? audio?.album ?? 'a',
                ).scale(
                  lightness: theme.isLight ? 0 : -0.4,
                  saturation: -0.5,
                ),
                getAlphabetColor(
                  audio?.title ?? audio?.album ?? 'a',
                ).scale(
                  lightness: theme.isLight ? -0.1 : -0.2,
                  saturation: -0.5,
                ),
              ],
            ),
          ),
          child: Icon(
            iconData,
            size: fullHeightPlayerImageSize * 0.7,
            color: contrastColor(
              getAlphabetColor(
                audio?.title ?? audio?.album ?? 'a',
              ),
            ),
          ),
        );
      }
    }

    return SizedBox(
      height: height ?? fullHeightPlayerImageSize,
      width: width ?? fullHeightPlayerImageSize,
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(10),
        child: image,
      ),
    );
  }
}
