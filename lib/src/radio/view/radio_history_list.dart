import 'package:animated_emoji/animated_emoji.dart';
import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

import '../../../common.dart';
import '../../../l10n.dart';
import '../../../player.dart';
import 'radio_history_tile.dart';

class RadioHistoryList extends StatelessWidget with WatchItMixin, PlayerMixin {
  const RadioHistoryList({
    super.key,
    this.filter,
    this.emptyMessage,
    this.padding,
    this.emptyIcon,
  });

  final String? filter;
  final Widget? emptyMessage;
  final Widget? emptyIcon;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final radioHistory = watchPropertyValue(
      (PlayerModel m) => m.filteredRadioHistory(filter: filter),
    );
    final current = watchPropertyValue((PlayerModel m) => m.mpvMetaData);

    if (radioHistory.isEmpty) {
      return NoSearchResultPage(
        icons: emptyIcon ?? const AnimatedEmoji(AnimatedEmojis.crystalBall),
        message: emptyMessage ?? Text(context.l10n.emptyHearingHistory),
      );
    }

    return Align(
      alignment: Alignment.topCenter,
      child: ListView.builder(
        padding: padding ?? EdgeInsets.zero,
        itemCount: radioHistory.length,
        itemBuilder: (context, index) {
          final reversedIndex = radioHistory.length - index - 1;
          final e = radioHistory.elementAt(reversedIndex);
          return RadioHistoryTile(
            e: e,
            selected: current?.icyTitle != null &&
                current?.icyTitle == e.value.icyTitle,
          );
        },
      ),
    );
  }
}

class SliverRadioHistoryList extends StatelessWidget
    with WatchItMixin, PlayerMixin {
  const SliverRadioHistoryList({
    super.key,
    this.filter,
    this.emptyMessage,
    this.padding,
    this.emptyIcon,
  });

  final String? filter;
  final Widget? emptyMessage;
  final Widget? emptyIcon;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final radioHistory = watchPropertyValue(
      (PlayerModel m) => m.filteredRadioHistory(filter: filter),
    );
    final current = watchPropertyValue((PlayerModel m) => m.mpvMetaData);

    if (radioHistory.isEmpty) {
      return SliverToBoxAdapter(
        child: NoSearchResultPage(
          icons: emptyIcon ?? const AnimatedEmoji(AnimatedEmojis.crystalBall),
          message: emptyMessage ?? Text(context.l10n.emptyHearingHistory),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final reversedIndex = radioHistory.length - index - 1;
          final e = radioHistory.elementAt(reversedIndex);
          return RadioHistoryTile(
            e: e,
            selected: current?.icyTitle != null &&
                current?.icyTitle == e.value.icyTitle,
          );
        },
        childCount: radioHistory.length,
      ),
    );
  }
}
