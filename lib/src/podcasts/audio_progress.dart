import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../build_context_x.dart';
import '../../common.dart';
import '../../player.dart';

class AudioProgress extends ConsumerWidget {
  const AudioProgress({
    super.key,
    this.lastPosition,
    this.duration,
    required this.selected,
  });

  final Duration? lastPosition;
  final Duration? duration;
  final bool selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.t;

    final pos = (selected
            ? ref.watch(playerModelProvider.select((m) => m.position))
            : lastPosition) ??
        Duration.zero;

    final dur = (selected
            ? ref.watch(playerModelProvider.select((m) => m.duration))
            : duration) ??
        Duration.zero;

    bool sliderActive = dur.inSeconds > pos.inSeconds;

    return RepaintBoundary(
      child: SizedBox(
        height: podcastProgressSize,
        width: podcastProgressSize,
        child: Progress(
          color: selected
              ? theme.colorScheme.primary.withOpacity(0.9)
              : theme.colorScheme.primary.withOpacity(0.4),
          value: sliderActive
              ? (pos.inSeconds.toDouble() / dur.inSeconds.toDouble())
              : 0,
          backgroundColor: Colors.transparent,
          strokeWidth: 3,
        ),
      ),
    );
  }
}
