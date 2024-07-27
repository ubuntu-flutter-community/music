import 'package:flutter/material.dart';
import 'package:podcast_search/podcast_search.dart';
import 'package:watch_it/watch_it.dart';

import '../../common/data/podcast_genre.dart';
import '../../common/view/common_widgets.dart';
import '../../common/view/country_auto_complete.dart';
import '../../common/view/language_autocomplete.dart';
import '../../common/view/theme.dart';
import '../../extensions/build_context_x.dart';
import '../../library/library_model.dart';
import '../../settings/settings_model.dart';
import '../podcast_model.dart';
import 'podcast_genre_autocomplete.dart';

class PodcastsControlPanel extends StatelessWidget with WatchItMixin {
  const PodcastsControlPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final libraryModel = di<LibraryModel>();
    final theme = context.t;
    final model = di<PodcastModel>();
    final searchQuery = watchPropertyValue((PodcastModel m) => m.searchQuery);
    final country = watchPropertyValue((PodcastModel m) => m.country);

    void setCountry(Country? country) {
      model.setCountry(country);
      libraryModel.setLastCountryCode(country?.code);
    }

    final podcastGenre = watchPropertyValue((PodcastModel m) => m.podcastGenre);
    final sortedGenrez = watchPropertyValue((PodcastModel m) => m.sortedGenres);
    final setPodcastGenre = model.setPodcastGenre;
    final usePodcastIndex =
        watchPropertyValue((SettingsModel m) => m.usePodcastIndex);
    watchPropertyValue((LibraryModel m) => m.favLanguagesLength);
    watchPropertyValue((LibraryModel m) => m.favCountriesLength);
    final favLanguageCodes =
        watchPropertyValue((LibraryModel m) => m.favLanguageCodes);

    final sortedGenres = usePodcastIndex
        ? sortedGenrez.where((e) => !e.name.contains('XXXITunesOnly')).toList()
        : sortedGenrez
            .where((e) => !e.name.contains('XXXPodcastIndexOnly'))
            .toList();
    final language = watchPropertyValue((PodcastModel m) => m.language);

    final fillColor = theme.chipTheme.selectedColor;

    return Align(
      alignment: Alignment.center,
      child: SizedBox(
        width: 380,
        child: Padding(
          padding: const EdgeInsets.only(
            left: 20,
            right: 20,
            top: 10,
          ),
          child: Row(
            children: [
              if (usePodcastIndex)
                Expanded(
                  child: LanguageAutoComplete(
                    contentPadding: countryPillPadding,
                    fillColor: language != null
                        ? fillColor
                        : yaruStyled
                            ? theme.dividerColor
                            : null,
                    filled: language != null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(100),
                      borderSide: yaruStyled
                          ? BorderSide.none
                          : BorderSide(
                              color: theme.colorScheme.outline,
                              width: 1.3,
                              strokeAlign: 1,
                            ),
                    ),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    isDense: true,
                    width: 150,
                    height: chipHeight,
                    value: language,
                    favs: favLanguageCodes,
                    addFav: (language) {
                      if (language?.isoCode == null) return;
                      libraryModel.addFavLanguageCode(language!.isoCode);
                    },
                    removeFav: (language) {
                      if (language?.isoCode == null) return;
                      libraryModel.removeFavLanguageCode(language!.isoCode);
                    },
                    onSelected: (language) {
                      model.setLanguage(language);
                      libraryModel.setLastLanguage(language?.isoCode);
                      model.search(searchQuery: searchQuery);
                    },
                  ),
                )
              else
                Expanded(
                  child: CountryAutoComplete(
                    contentPadding: countryPillPadding,
                    fillColor: fillColor,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(100),
                      borderSide: yaruStyled
                          ? BorderSide.none
                          : BorderSide(
                              color: theme.colorScheme.outline,
                              width: 1.3,
                              strokeAlign: 1,
                            ),
                    ),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    isDense: true,
                    width: 200,
                    height: chipHeight,
                    countries: [
                      ...[
                        ...Country.values,
                      ].where(
                        (e) =>
                            libraryModel.favCountryCodes.contains(e.code) ==
                            true,
                      ),
                      ...[...Country.values].where(
                        (e) =>
                            libraryModel.favCountryCodes.contains(e.code) ==
                            false,
                      ),
                    ]..remove(Country.none),
                    onSelected: (country) {
                      setCountry(country);
                      model.setLimit(20);

                      model.search(searchQuery: searchQuery);
                    },
                    value: country,
                    addFav: (v) {
                      if (country?.code == null) return;
                      libraryModel.addFavCountryCode(v!.code);
                    },
                    removeFav: (v) {
                      if (country?.code == null) return;
                      libraryModel.removeFavCountryCode(v!.code);
                    },
                    favs: libraryModel.favCountryCodes,
                  ),
                ),
              const SizedBox(
                width: 10,
              ),
              Expanded(
                child: PodcastGenreAutoComplete(
                  contentPadding: countryPillPadding,
                  fillColor: podcastGenre != PodcastGenre.all
                      ? fillColor
                      : yaruStyled
                          ? theme.dividerColor
                          : null,
                  filled: podcastGenre != PodcastGenre.all,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(100),
                    borderSide: yaruStyled
                        ? BorderSide.none
                        : BorderSide(
                            color: theme.colorScheme.outline,
                            width: 1.3,
                            strokeAlign: 1,
                          ),
                  ),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  isDense: true,
                  width: 200,
                  height: chipHeight,
                  genres: sortedGenres,
                  onSelected: (podcastGenre) {
                    if (podcastGenre != null) {
                      setPodcastGenre(podcastGenre);

                      model.setLimit(20);
                    }

                    model.search(searchQuery: searchQuery);
                  },
                  value: podcastGenre,

                  addFav: (v) {
                    // if (country?.code == null) return;
                    // libraryModel.addFavCountry(v!.code);
                  },
                  removeFav: (v) {
                    // if (country?.code == null) return;
                    // libraryModel.removeFavCountry(v!.code);
                  },
                  // favs: libraryModel.favCountryCodes,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
