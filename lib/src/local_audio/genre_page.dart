import 'package:flutter/material.dart';

import 'package:yaru/yaru.dart';

import '../../common.dart';
import '../../data.dart';
import '../../globals.dart';
import '../../l10n.dart';
import '../../local_audio.dart';
import '../../radio.dart';

class GenrePage extends StatelessWidget {
  const GenrePage({required this.genre, super.key});

  final String genre;

  @override
  Widget build(BuildContext context) {
    final model = ref.read(localAudioModelProvider);
    final radioModel = getIt<RadioModel>();

    final artistAudiosWithGenre = model.findArtistsOfGenre(Audio(genre: genre));

    return YaruDetailPage(
      appBar: HeaderBar(
        adaptive: true,
        leading: (navigatorKey.currentState?.canPop() == true)
            ? const NavBackButton()
            : const SizedBox.shrink(),
        titleSpacing: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: context.l10n.searchForRadioStationsWithGenreName,
              onPressed: () {
                radioModel.init().then(
                      (_) => navigatorKey.currentState?.push(
                        MaterialPageRoute(
                          builder: (context) {
                            return RadioSearchPage(
                              radioSearch: RadioSearch.tag,
                              searchQuery: genre.toLowerCase(),
                            );
                          },
                        ),
                      ),
                    );
              },
              icon: Icon(Iconz().radio),
            ),
            const SizedBox(
              width: 5,
            ),
            Text(genre),
          ],
        ),
      ),
      body: AdaptiveContainer(
        child: ArtistsView(
          artists: artistAudiosWithGenre,
        ),
      ),
    );
  }
}
