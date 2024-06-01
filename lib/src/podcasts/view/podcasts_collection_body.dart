import 'package:animated_emoji/animated_emoji.dart';
import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';
import 'package:yaru/yaru.dart';

import '../../../build_context_x.dart';
import '../../../common.dart';
import '../../../constants.dart';
import '../../../data.dart';
import '../../../l10n.dart';
import '../../../player.dart';
import '../../../podcasts.dart';
import '../../../theme.dart';
import '../../globals.dart';
import '../../library/library_model.dart';

class PodcastsCollectionBody extends StatelessWidget with WatchItMixin {
  const PodcastsCollectionBody({
    super.key,
    required this.isOnline,
    required this.loading,
  });

  final bool isOnline;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final theme = context.t;
    final subs = watchPropertyValue((LibraryModel m) => m.podcasts);
    watchPropertyValue((LibraryModel m) => m.podcastUpdatesLength);
    final playerModel = di<PlayerModel>();
    final libraryModel = di<LibraryModel>();
    final podcastUpdateAvailable = libraryModel.podcastUpdateAvailable;
    final feedHasDownload = libraryModel.feedHasDownload;
    final updatesLength =
        watchPropertyValue((LibraryModel m) => m.podcastUpdatesLength);
    final model = di<PodcastModel>();
    final updatesOnly = watchPropertyValue((PodcastModel m) => m.updatesOnly);
    final downloadsOnly =
        watchPropertyValue((PodcastModel m) => m.downloadsOnly);
    final subsLength = watchPropertyValue((LibraryModel m) => m.podcastsLength);
    final feedsWithDownloadLength =
        watchPropertyValue((LibraryModel m) => m.feedsWithDownloadsLength);
    final setUpdatesOnly = model.setUpdatesOnly;
    final setDownloadsOnly = model.setDownloadsOnly;
    final removeUpdate = libraryModel.removePodcastUpdate;

    final itemCount = updatesOnly
        ? updatesLength
        : (downloadsOnly ? feedsWithDownloadLength : subsLength);

    return subsLength == 0
        ? NoSearchResultPage(
            icons: const AnimatedEmoji(AnimatedEmojis.faceInClouds),
            message: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(context.l10n.noPodcastSubsFound),
                const SizedBox(
                  height: 10,
                ),
                ImportantButton(
                  onPressed: () => model.setSearchActive(true),
                  child: Text(context.l10n.discover),
                ),
              ],
            ),
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const SizedBox(
                    width: kYaruPagePadding,
                  ),
                  YaruChoiceChipBar(
                    chipBackgroundColor: chipColor(theme),
                    selectedChipBackgroundColor:
                        chipSelectionColor(theme, loading),
                    borderColor: chipBorder(theme, loading),
                    yaruChoiceChipBarStyle: YaruChoiceChipBarStyle.wrap,
                    clearOnSelect: false,
                    selectedFirst: false,
                    labels: [
                      Text(context.l10n.newEpisodes),
                      Text(
                        context.l10n.downloadsOnly,
                      ),
                    ],
                    isSelected: [
                      updatesOnly,
                      downloadsOnly,
                    ],
                    onSelected: loading
                        ? null
                        : (index) {
                            if (index == 0) {
                              if (updatesOnly) {
                                setUpdatesOnly(false);
                              } else {
                                model.update(context.l10n.newEpisodeAvailable);

                                setUpdatesOnly(true);
                                setDownloadsOnly(false);
                              }
                            } else {
                              if (downloadsOnly) {
                                setDownloadsOnly(false);
                              } else {
                                setDownloadsOnly(true);
                                setUpdatesOnly(false);
                              }
                            }
                          },
                  ),
                ],
              ),
              const SizedBox(
                height: 15,
              ),
              Expanded(
                child: loading
                    ? LoadingGrid(limit: subsLength)
                    : GridView.builder(
                        padding: gridPadding,
                        itemCount: itemCount,
                        gridDelegate: audioCardGridDelegate,
                        itemBuilder: (context, index) {
                          final MapEntry<String, Set<Audio>> podcast;
                          if (updatesOnly) {
                            podcast = subs.entries
                                .where((e) => podcastUpdateAvailable(e.key))
                                .elementAt(index);
                          } else if (downloadsOnly) {
                            podcast = subs.entries
                                .where((e) => feedHasDownload(e.key))
                                .elementAt(index);
                          } else {
                            podcast = subs.entries.elementAt(index);
                          }

                          final artworkUrl600 =
                              podcast.value.firstOrNull?.albumArtUrl ??
                                  podcast.value.firstOrNull?.imageUrl;
                          final image = SafeNetworkImage(
                            url: artworkUrl600,
                            fit: BoxFit.cover,
                            height: kAudioCardDimension,
                            width: kAudioCardDimension,
                          );

                          return AudioCard(
                            image: image,
                            bottom: AudioCardBottom(
                              style: podcastUpdateAvailable(podcast.key)
                                  ? theme.textTheme.bodyMedium?.copyWith(
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                      ) ??
                                      TextStyle(
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                      )
                                  : null,
                              text: podcast.value.firstOrNull?.album ??
                                  podcast.value.firstOrNull?.title ??
                                  podcast.value.firstOrNull.toString(),
                            ),
                            onPlay: () {
                              runOrConfirm(
                                context: context,
                                noConfirm: podcast.value.length <
                                    kAudioQueueThreshHold,
                                message: context.l10n.queueConfirmMessage(
                                  podcast.value.length.toString(),
                                ),
                                run: () => playerModel
                                    .startPlaylist(
                                      audios: podcast.value,
                                      listName: podcast.key,
                                    )
                                    .then((_) => removeUpdate(podcast.key)),
                                onCancel: () {
                                  model.setSelectedFeedUrl(null);
                                  ScaffoldMessenger.of(context)
                                      .clearSnackBars();
                                },
                              );
                            },
                            onTap: () => navigatorKey.currentState?.push(
                              MaterialPageRoute(
                                builder: (context) {
                                  if (!isOnline) return const OfflinePage();

                                  return PodcastPage(
                                    pageId: podcast.key,
                                    title: podcast.value.firstOrNull?.album ??
                                        podcast.value.firstOrNull?.title ??
                                        podcast.value.firstOrNull.toString(),
                                    audios: podcast.value,
                                    imageUrl: podcast
                                            .value.firstOrNull?.albumArtUrl ??
                                        podcast.value.firstOrNull?.imageUrl,
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
  }
}
