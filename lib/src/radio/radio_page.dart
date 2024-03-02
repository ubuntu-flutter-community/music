import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yaru/yaru.dart';

import '../../app.dart';
import '../../common.dart';
import '../../globals.dart';
import '../l10n/l10n.dart';
import '../library/library_model.dart';
import 'radio_discover_page.dart';
import 'radio_lib_page.dart';
import 'radio_model.dart';

class RadioPage extends ConsumerStatefulWidget {
  const RadioPage({
    super.key,
    required this.isOnline,
    this.countryCode,
  });

  final bool isOnline;
  final String? countryCode;

  @override
  ConsumerState<RadioPage> createState() => _RadioPageState();
}

class _RadioPageState extends ConsumerState<RadioPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final model = ref.read(radioModelProvider);
      final libraryModel = ref.read(libraryModelProvider);
      final index = libraryModel.radioindex;
      model
          .init(
        countryCode: widget.countryCode,
        index: index,
      )
          .then(
        (connectedHost) {
          if (!widget.isOnline) {
            return;
          }

          ScaffoldMessenger.of(context).showSnackBar(
            _buildConnectSnackBar(connectedHost, model, index),
          );
        },
      );
    });
  }

  SnackBar _buildConnectSnackBar(
    String? connectedHost,
    RadioModel model,
    int index,
  ) {
    return SnackBar(
      duration: connectedHost != null
          ? const Duration(seconds: 1)
          : const Duration(seconds: 30),
      content: Text(
        connectedHost != null
            ? '${context.l10n.connectedTo}: $connectedHost'
            : context.l10n.noRadioServerFound,
      ),
      action: (connectedHost == null)
          ? SnackBarAction(
              onPressed: () => model.init(
                countryCode: widget.countryCode,
                index: index,
              ),
              label: context.l10n.tryReconnect,
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final showWindowControls =
        ref.watch(appModelProvider.select((m) => m.showWindowControls));

    ref.watch(libraryModelProvider.select((m) => m.favTagsLength));

    if (!widget.isOnline) {
      return const OfflinePage();
    } else {
      return Scaffold(
        appBar: HeaderBar(
          style: showWindowControls
              ? YaruTitleBarStyle.normal
              : YaruTitleBarStyle.undecorated,
          titleSpacing: 0,
          leading: navigatorKey.currentState?.canPop() == true
              ? const NavBackButton()
              : const SizedBox.shrink(),
          actions: [
            Flexible(
              child: Padding(
                padding: appBarActionSpacing,
                child: SearchButton(
                  active: false,
                  onPressed: () {
                    navigatorKey.currentState?.push(
                      MaterialPageRoute(
                        builder: (context) => const RadioDiscoverPage(),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
          title: Text('${context.l10n.radio} ${context.l10n.collection}'),
        ),
        body: RadioLibPage(
          isOnline: widget.isOnline,
        ),
      );
    }
  }
}
