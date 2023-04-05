import 'package:flutter/material.dart';
import 'package:musicpod/app/local_audio/album_view.dart';
import 'package:musicpod/app/local_audio/artists_view.dart';
import 'package:musicpod/app/local_audio/local_audio_model.dart';
import 'package:musicpod/app/local_audio/local_audio_search_field.dart';
import 'package:musicpod/app/local_audio/local_audio_search_page.dart';
import 'package:musicpod/app/local_audio/titles_view.dart';
import 'package:musicpod/app/tabbed_page.dart';
import 'package:musicpod/l10n/l10n.dart';
import 'package:provider/provider.dart';
import 'package:yaru_widgets/yaru_widgets.dart';

class LocalAudioPage extends StatefulWidget {
  const LocalAudioPage({super.key, this.showWindowControls = true});

  final bool showWindowControls;

  @override
  State<LocalAudioPage> createState() => _LocalAudioPageState();
}

class _LocalAudioPageState extends State<LocalAudioPage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final searchQuery = context.select((LocalAudioModel m) => m.searchQuery);

    return Navigator(
      onPopPage: (route, result) => route.didPop(result),
      pages: [
        MaterialPage(
          child: StartPage(
            showWindowControls: widget.showWindowControls,
            selectedIndex: _selectedIndex,
            onIndexSelected: (index) => setState(() {
              _selectedIndex = index;
            }),
          ),
        ),
        if (searchQuery?.isNotEmpty == true)
          MaterialPage(
            child: LocalAudioSearchPage(
              showWindowControls: widget.showWindowControls,
            ),
          )
      ],
    );
  }
}

class StartPage extends StatelessWidget {
  const StartPage({
    super.key,
    required this.showWindowControls,
    required this.selectedIndex,
    this.onIndexSelected,
  });

  final bool showWindowControls;
  final int selectedIndex;
  final void Function(int index)? onIndexSelected;

  @override
  Widget build(BuildContext context) {
    final audios = context.read<LocalAudioModel>().audios;
    final artists = context.read<LocalAudioModel>().findAllArtists();
    final albums = context.read<LocalAudioModel>().findAllAlbums();
    final searchQuery = context.select((LocalAudioModel m) => m.searchQuery);
    final setSearchQuery = context.read<LocalAudioModel>().setSearchQuery;
    final search = context.read<LocalAudioModel>().search;

    final theme = Theme.of(context);

    void onTap(text) {
      setSearchQuery(text);
      search();
    }

    return YaruDetailPage(
      backgroundColor: theme.brightness == Brightness.dark
          ? const Color.fromARGB(255, 37, 37, 37)
          : Colors.white,
      appBar: YaruWindowTitleBar(
        style: showWindowControls
            ? YaruTitleBarStyle.normal
            : YaruTitleBarStyle.undecorated,
        title: LocalAudioSearchField(
          key: ValueKey(searchQuery),
        ),
      ),
      body: TabbedPage(
        initialIndex: selectedIndex,
        onTap: onIndexSelected,
        tabTitles: [
          context.l10n.titles,
          context.l10n.artists,
          context.l10n.albums,
        ],
        views: [
          TitlesView(
            onArtistTap: onTap,
            onAlbumTap: onTap,
            audios: audios,
            showWindowControls: showWindowControls,
          ),
          ArtistsView(
            showWindowControls: showWindowControls,
            similarArtistsSearchResult: artists,
            onArtistTap: onTap,
            onAlbumTap: onTap,
          ),
          AlbumsView(
            showWindowControls: showWindowControls,
            albums: albums,
            onArtistTap: onTap,
            onAlbumTap: onTap,
          ),
        ],
      ),
    );
  }
}
