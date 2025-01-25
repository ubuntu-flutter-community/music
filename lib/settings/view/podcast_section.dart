import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';
import 'package:yaru/yaru.dart';

import '../../common/view/common_widgets.dart';
import '../../common/view/icons.dart';
import '../../common/view/ui_constants.dart';
import '../../extensions/build_context_x.dart';
import '../../extensions/shared_preferences_x.dart';
import '../../extensions/string_x.dart';
import '../../l10n/l10n.dart';
import '../../podcasts/download_model.dart';
import '../../podcasts/podcast_model.dart';
import '../settings_model.dart';

class PodcastSection extends StatefulWidget with WatchItStatefulWidgetMixin {
  const PodcastSection({super.key});

  @override
  State<PodcastSection> createState() => _PodcastSectionState();
}

class _PodcastSectionState extends State<PodcastSection> {
  String? _initialKey;
  String? _initialSecret;
  late TextEditingController _keyController, _secretController;

  @override
  void initState() {
    super.initState();
    final model = di<SettingsModel>();
    _initialKey = model.podcastIndexApiKey;
    _keyController = TextEditingController(text: _initialKey);
    _initialSecret = model.podcastIndexApiSecret;
    _secretController = TextEditingController(text: _initialSecret);
  }

  @override
  void dispose() {
    _keyController.dispose();
    _secretController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final l10n = context.l10n;
    final model = di<SettingsModel>();
    final usePodcastIndex =
        watchPropertyValue((SettingsModel m) => m.usePodcastIndex);
    final podcastIndexApiKey =
        watchPropertyValue((SettingsModel m) => m.podcastIndexApiKey);
    final podcastIndexApiSecret =
        watchPropertyValue((SettingsModel m) => m.podcastIndexApiSecret);

    return YaruSection(
      margin: const EdgeInsets.all(kLargestSpace),
      headline: Text(l10n.podcasts),
      child: Column(
        children: [
          const _DownloadsTile(),
          YaruTile(
            title: Text(l10n.usePodcastIndex),
            trailing: CommonSwitch(
              value: usePodcastIndex,
              onChanged: (v) async {
                await model.setUsePodcastIndex(v);
                if (context.mounted) {
                  di<PodcastModel>().init(
                    forceInit: true,
                    updateMessage: l10n.newEpisodeAvailable,
                  );
                }
              },
            ),
          ),
          if (usePodcastIndex)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _keyController,
                onChanged: (v) => setState(() => _initialKey = v),
                obscureText: true,
                decoration: InputDecoration(
                  label: Text(SPKeys.podcastIndexApiKey.camelToSentence),
                  suffixIcon: IconButton(
                    tooltip: l10n.save,
                    onPressed: () =>
                        model.setPodcastIndexApiKey(_keyController.text),
                    icon: Icon(
                      Iconz.check,
                      color: podcastIndexApiKey == _initialKey
                          ? theme.colorScheme.success
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ),
          if (usePodcastIndex)
            Padding(
              padding: const EdgeInsets.only(
                left: 8,
                right: 8,
                bottom: kLargestSpace,
              ),
              child: TextField(
                controller: _secretController,
                onChanged: (v) => setState(() => _initialSecret = v),
                obscureText: true,
                decoration: InputDecoration(
                  label: Text(SPKeys.podcastIndexApiSecret.camelToSentence),
                  suffixIcon: IconButton(
                    tooltip: l10n.save,
                    onPressed: () =>
                        model.setPodcastIndexApiSecret(_secretController.text),
                    icon: Icon(
                      Iconz.check,
                      color: podcastIndexApiSecret == _initialSecret
                          ? theme.colorScheme.success
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DownloadsTile extends StatefulWidget with WatchItStatefulWidgetMixin {
  const _DownloadsTile();

  @override
  State<_DownloadsTile> createState() => _DownloadsTileState();
}

class _DownloadsTileState extends State<_DownloadsTile> {
  String? _error;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return YaruTile(
      title: Text(l10n.downloadsDirectory),
      subtitle: Text(
        _error ?? watchPropertyValue((SettingsModel m) => m.downloadsDir ?? ''),
      ),
      trailing: ImportantButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              content: SizedBox(
                width: 300,
                child: Text(
                  l10n.downloadsChangeWarning,
                  style: context.textTheme.bodyLarge,
                ),
              ),
              actions: [
                OutlinedButton(
                  onPressed: Navigator.of(context).pop,
                  child: Text(l10n.cancel),
                ),
                ImportantButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    di<SettingsModel>().setDownloadsCustomDir(
                      onSuccess: () => di<DownloadModel>().deleteAllDownloads(),
                      onFail: (e) => setState(() => _error = e.toString()),
                    );
                  },
                  child: Text(l10n.ok),
                ),
              ],
            ),
          );
        },
        child: Text(
          l10n.select,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
