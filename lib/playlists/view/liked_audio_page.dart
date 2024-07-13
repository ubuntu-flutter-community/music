import 'package:animated_emoji/animated_emoji.dart';
import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

import '../../common/data/audio.dart';
import '../../common/view/audio_page_type.dart';
import '../../common/view/avatar_play_button.dart';
import '../../common/view/common_widgets.dart';
import '../../common/view/fall_back_header_image.dart';
import '../../common/view/icons.dart';
import '../../common/view/side_bar_fall_back_image.dart';
import '../../common/view/sliver_audio_page.dart';
import '../../constants.dart';
import '../../extensions/build_context_x.dart';
import '../../l10n/l10n.dart';
import '../../library/library_model.dart';
import '../../local_audio/local_audio_model.dart';
import '../../local_audio/view/artist_page.dart';

class LikedAudioPage extends StatelessWidget with WatchItMixin {
  const LikedAudioPage({super.key});

  static Widget createIcon({
    required BuildContext context,
    required bool selected,
  }) {
    return SideBarFallBackImage(
      child: selected ? Icon(Iconz().heartFilled) : Icon(Iconz().heart),
    );
  }

  @override
  Widget build(BuildContext context) {
    final model = di<LocalAudioModel>();
    final likedAudios = watchPropertyValue((LibraryModel m) => m.likedAudios);

    return SliverAudioPage(
      onPageLabelTab: (text) {
        final artistAudios = model.findArtist(Audio(artist: text));
        final images = model.findImages(artistAudios ?? {});

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) {
              return ArtistPage(
                images: images,
                artistAudios: artistAudios,
              );
            },
          ),
        );
      },
      controlPanel: Row(
        children: [
          AvatarPlayButton(audios: likedAudios, pageId: kLikedAudiosPageId),
          Padding(
            padding: const EdgeInsets.only(
              left: 10,
              right: 10,
            ),
            child: Text(
              '${likedAudios.length} ${context.l10n.titles}',
              style: getControlPanelStyle(context.t.textTheme),
            ),
          ),
        ],
      ),
      noSearchResultMessage: Text(context.l10n.likedSongsSubtitle),
      noSearchResultIcons: const AnimatedEmoji(AnimatedEmojis.twoHearts),
      audios: likedAudios,
      audioPageType: AudioPageType.likedAudio,
      pageId: kLikedAudiosPageId,
      pageTitle: context.l10n.likedSongs,
      pageLabel: context.l10n.likedSongsSubtitle,
      image: FallBackHeaderImage(
        child: Icon(
          Iconz().heart,
          size: 65,
        ),
      ),
    );
  }
}
