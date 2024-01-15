import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants.dart';
import '../../data.dart';
import '../../library.dart';
import '../common/icons.dart';

class LikeIconButton extends StatelessWidget {
  const LikeIconButton({
    super.key,
    required this.audio,
    this.color,
  });

  final Audio? audio;

  final Color? color;

  @override
  Widget build(BuildContext context) {
    final libraryModel = context.read<LibraryModel>();
    if (audio?.audioType == AudioType.podcast) {
      return const SizedBox.shrink();
    }
    context.select((LibraryModel m) => m.likedAudios.length);
    context.select((LibraryModel m) => m.starredStations.length);

    final isStarredStation = libraryModel.isStarredStation(audio?.url);
    final liked = libraryModel.liked(audio);

    Widget likeIcon;
    if (audio?.audioType == AudioType.radio) {
      likeIcon = Iconz().getAnimatedStar(isStarredStation);
    } else {
      likeIcon = Iconz().getAnimatedHeartIcon(liked: liked);
    }

    final void Function()? onLike;
    if (audio == null && audio?.url == null) {
      onLike = null;
    } else {
      if (audio?.audioType == AudioType.radio) {
        onLike = () {
          isStarredStation
              ? libraryModel.unStarStation(audio!.url!)
              : libraryModel.addStarredStation(
                  audio!.url!,
                  {audio!},
                );
        };
      } else {
        onLike = () {
          if (liked) {
            libraryModel.removeLikedAudio(audio!, true);
          } else {
            libraryModel.addLikedAudio(audio!, true);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: AddToPlaylistSnackBar(
                  libraryModel: libraryModel,
                  id: kLikedAudiosPageId,
                ),
              ),
            );
          }
        };
      }
    }
    return IconButton(
      icon: likeIcon,
      onPressed: onLike,
      color: color,
    );
  }
}
