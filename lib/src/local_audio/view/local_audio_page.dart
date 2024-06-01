import 'package:animated_emoji/animated_emoji.dart';
import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';
import 'package:yaru/yaru.dart';

import '../../../app.dart';
import '../../../build_context_x.dart';
import '../../../common.dart';
import '../../../constants.dart';
import '../../../data.dart';
import '../../../globals.dart';
import '../../../local_audio.dart';
import '../../../player.dart';
import '../../l10n/l10n.dart';
import '../../library/library_model.dart';
import '../../settings/view/settings_dialog.dart';
import 'local_audio_body.dart';
import 'local_audio_control_panel.dart';
import 'local_audio_view.dart';

class LocalAudioPage extends StatefulWidget with WatchItStatefulWidgetMixin {
  const LocalAudioPage({super.key});

  @override
  State<LocalAudioPage> createState() => _LocalAudioPageState();
}

class _LocalAudioPageState extends State<LocalAudioPage> {
  @override
  void initState() {
    super.initState();
    final failedImports = di<LocalAudioModel>().failedImports;
    if (mounted && failedImports?.isNotEmpty == true) {
      showFailedImportsSnackBar(
        failedImports: failedImports!,
        context: context,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appModel = di<AppModel>();
    final model = di<LocalAudioModel>();
    final audios = watchPropertyValue((LocalAudioModel m) => m.audios);
    final index =
        watchPropertyValue((LibraryModel m) => m.localAudioindex ?? 0);
    final localAudioView = LocalAudioView.values[index];

    void search({
      required String? text,
    }) {
      if (text != null) {
        model.search(text);
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) {
              return const LocalAudioSearchPage();
            },
          ),
        );
      } else {
        navigatorKey.currentState?.maybePop();
      }
    }

    final headerBar = HeaderBar(
      adaptive: true,
      titleSpacing: 0,
      actions: [
        Flexible(
          child: Padding(
            padding: appBarActionSpacing,
            child: SearchButton(
              active: false,
              onPressed: () {
                appModel.setLockSpace(true);
                search(text: '');
              },
            ),
          ),
        ),
      ],
      title: Text(context.l10n.localAudio),
    );

    return YaruDetailPage(
      appBar: headerBar,
      body: AdaptiveContainer(
        child: Column(
          children: [
            const LocalAudioControlPanel(),
            Expanded(
              child: LocalAudioBody(
                localAudioView: localAudioView,
                titles: audios,
                albums: model.allAlbums,
                artists: model.allArtists,
                genres: model.allGenres,
                noResultIcon: const AnimatedEmoji(AnimatedEmojis.bird),
                noResultMessage: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(context.l10n.noLocalTitlesFound),
                    const SizedBox(
                      height: kYaruPagePadding,
                    ),
                    ElevatedButton(
                      child: Text(context.l10n.settings),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => const SettingsDialog(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LocalAudioPageIcon extends StatelessWidget with WatchItMixin {
  const LocalAudioPageIcon({
    super.key,
    required this.selected,
  });

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final audioType = watchPropertyValue((PlayerModel m) => m.audio?.audioType);

    final theme = context.t;
    if (audioType == AudioType.local) {
      return Icon(
        Iconz().play,
        color: theme.colorScheme.primary,
      );
    }

    return Padding(
      padding: kMainPageIconPadding,
      child:
          selected ? Icon(Iconz().localAudioFilled) : Icon(Iconz().localAudio),
    );
  }
}
