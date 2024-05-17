import 'package:flutter/material.dart';
import 'package:yaru/yaru.dart';

import '../../common.dart';
import '../data/audio.dart';
import 'sliver_audio_page_control_panel.dart';
import 'sliver_audio_tile_list.dart';

class SliverAudioPage extends StatelessWidget {
  const SliverAudioPage({
    super.key,
    required this.pageId,
    this.audios,
    required this.audioPageType,
    this.onPageSubTitleTab,
    this.onPageLabelTab,
    this.pageTitle,
    this.pageSubTitle,
    this.pageLabel,
    this.image,
    this.controlPanel,
    this.noSearchResultMessage,
    this.noSearchResultIcons,
  });

  final String pageId;
  final Set<Audio>? audios;
  final AudioPageType audioPageType;

  final String? pageTitle;
  final String? pageSubTitle;
  final String? pageLabel;
  final Widget? image;

  final void Function(String text)? onPageSubTitleTab;
  final void Function(String)? onPageLabelTab;

  final Widget? controlPanel;

  final Widget? noSearchResultMessage;
  final Widget? noSearchResultIcons;

  @override
  Widget build(BuildContext context) {
    return YaruDetailPage(
      appBar: HeaderBar(
        adaptive: true,
        title: Text(pageTitle ?? pageId),
      ),
      body: AdaptiveContainer(
        child: audios == null
            ? const Center(
                child: Progress(),
              )
            : audios!.isEmpty
                ? NoSearchResultPage(
                    message: noSearchResultMessage,
                    icons: noSearchResultIcons,
                  )
                : CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: AudioPageHeader(
                          title: pageTitle ?? pageId,
                          image: image,
                          subTitle: pageSubTitle,
                          label: pageLabel,
                          onLabelTab: audioPageType == AudioPageType.likedAudio
                              ? null
                              : onPageLabelTab,
                          onSubTitleTab: onPageSubTitleTab,
                        ),
                      ),
                      SliverAudioPageControlPanel(
                        controlPanel: controlPanel ??
                            AvatarPlayButton(
                              audios: audios ?? {},
                              pageId: pageId,
                            ),
                      ),
                      if (audios == null)
                        const SliverToBoxAdapter(
                          child: Center(
                            child: Progress(),
                          ),
                        )
                      else
                        SliverAudioTileList(
                          audioPageType: audioPageType,
                          audios: audios!,
                          pageId: pageId,
                          onSubTitleTab: onPageLabelTab,
                        ),
                    ],
                  ),
      ),
    );
  }
}
