import 'package:flutter/material.dart';
import 'package:yaru/yaru.dart';

import '../../build_context_x.dart';
import '../l10n/l10n.dart';
import 'common_widgets.dart';

class OfflinePage extends StatelessWidget {
  const OfflinePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.t;
    return YaruDetailPage(
      appBar: HeaderBar(
        adaptive: true,
        title: Text(context.l10n.offline),
        backgroundColor: Colors.transparent,
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            YaruAnimatedVectorIcon(
              YaruAnimatedIcons.no_network,
              size: 200,
              color: theme.disabledColor,
            ),
            Padding(
              padding: const EdgeInsets.only(
                top: kYaruPagePadding,
                left: 40,
                right: 40,
              ),
              child: Text(
                context.l10n.offlineDescription,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: theme.disabledColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
