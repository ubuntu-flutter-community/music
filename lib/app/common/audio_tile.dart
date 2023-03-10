import 'package:flutter/material.dart';
import 'package:musicpod/data/audio.dart';
import 'package:yaru_widgets/yaru_widgets.dart';

class AudioTile extends StatelessWidget {
  const AudioTile({
    super.key,
    required this.selected,
    required this.audio,
    this.onLike,
    this.likeIcon,
    required this.isPlayerPlaying,
    required this.play,
    required this.pause,
    required this.resume,
  });

  final Audio audio;
  final bool selected;
  final void Function()? onLike;
  final Widget? likeIcon;
  final bool isPlayerPlaying;
  final Future<void> Function() play;
  final Future<void> Function() resume;
  final void Function() pause;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = TextStyle(
      color: selected ? theme.colorScheme.onSurface : theme.hintColor,
      fontWeight: selected ? FontWeight.w500 : FontWeight.normal,
    );

    return ListTile(
      contentPadding: const EdgeInsets.only(left: 8, right: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kYaruButtonRadius),
      ),
      onTap: () {
        if (isPlayerPlaying && selected) {
          pause();
        } else {
          if (selected) {
            resume();
          } else {
            play();
          }
        }
      },
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (audio.metadata?.trackNumber != null)
            Expanded(
              flex: 1,
              child: Text(
                audio.metadata?.trackNumber != null
                    ? '${audio.metadata?.trackNumber}'
                    : ' ',
                style: textStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          Expanded(
            flex: 5,
            child: Text(
              audio.metadata?.title ?? audio.name ?? '',
              style: textStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (audio.metadata?.artist != null)
            Expanded(
              flex: 4,
              child: Text(
                audio.metadata!.artist!,
                style: textStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          if (audio.metadata?.album != null)
            Expanded(
              flex: 4,
              child: Text(
                audio.metadata!.album!,
                style: textStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
      trailing: likeIcon,
    );
  }
}
