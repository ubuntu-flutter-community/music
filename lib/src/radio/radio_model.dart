import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:podcast_search/podcast_search.dart';
import 'package:radio_browser_api/radio_browser_api.dart' hide Country;
import 'package:safe_change_notifier/safe_change_notifier.dart';
import 'package:ubuntu_service/ubuntu_service.dart';

import '../../data.dart';
import '../../l10n.dart';
import '../../library.dart';
import '../../string_x.dart';
import 'radio_search.dart';
import 'radio_service.dart';

class RadioModel extends SafeChangeNotifier {
  final RadioService _radioService;
  final LibraryService _libraryService;

  RadioModel({
    required RadioService radioService,
    required LibraryService libraryService,
  })  : _radioService = radioService,
        _libraryService = libraryService;

  Country? _country;
  Country? get country => _country;
  void setCountry(Country? value) {
    if (value == _country) return;
    _country = value;
    setSearchQuery(search: RadioSearch.country);
  }

  List<Country> get sortedCountries {
    if (_country == null) return Country.values;
    final notSelected =
        Country.values.where((c) => c != _country).toList().sorted(
              (a, b) => a.name.compareTo(b.name),
            );
    final list = <Country>[_country!, ...notSelected];

    return list;
  }

  List<Tag>? get tags => _radioService.tags;
  Tag? _tag;
  Tag? get tag => _tag;
  void setTag(Tag? value) {
    if (value == _tag) return;
    _tag = value;
    setSearchQuery(search: RadioSearch.tag);
  }

  Future<Set<Audio>?> getStations({
    required RadioSearch radioSearch,
    required String? query,
  }) async {
    final stations = switch (radioSearch) {
      RadioSearch.tag => await _radioService.getStations(tag: query),
      RadioSearch.country => await _radioService.getStations(
          country: query?.camelToSentence(),
        ),
      RadioSearch.name => await _radioService.getStations(name: query),
      RadioSearch.state => await _radioService.getStations(state: query),
    };

    if (stations == null) return null;

    if (stations.isEmpty) {
      return <Audio>{};
    }

    return Set.from(
      stations.map(
        (e) {
          return Audio(
            url: e.urlResolved,
            title: e.name,
            artist: e.language ?? e.name,
            album: e.tags ?? '',
            audioType: AudioType.radio,
            imageUrl: e.favicon,
            website: e.homepage,
          );
        },
      ),
    );
  }

  String? _connectedHost;
  Future<String?> init({
    String? countryCode,
    int index = 0,
  }) async {
    _connectedHost ??= await _radioService.init();
    await _radioService.loadTags();

    final lastFav = _libraryService.lastFav;

    _country ??= Country.values.firstWhereOrNull(
      (c) => c.code == (_libraryService.lastCountryCode ?? countryCode),
    );

    if (_connectedHost?.isNotEmpty == true) {
      _tag ??= lastFav == null || tags == null || tags!.isEmpty
          ? null
          : tags!.firstWhere((t) => t.name.contains(lastFav));
    }

    setSearchQuery(search: RadioSearch.values[index]);

    return _connectedHost;
  }

  String? _searchQuery;
  String? get searchQuery => _searchQuery;
  void setSearchQuery({RadioSearch? search, String? query}) {
    switch (search) {
      case RadioSearch.country:
        _searchQuery = country?.name;
        break;
      case RadioSearch.tag:
        _searchQuery = tag?.name;
      default:
        _searchQuery = query ?? _searchQuery;
    }
    notifyListeners();
  }

  RadioCollectionView _radioCollectionView = RadioCollectionView.stations;
  RadioCollectionView get radioCollectionView => _radioCollectionView;
  void setRadioCollectionView(RadioCollectionView value) {
    if (value == _radioCollectionView) return;
    _radioCollectionView = value;
    notifyListeners();
  }
}

enum RadioCollectionView {
  stations,
  tags,
  history;

  String localize(AppLocalizations l10n) {
    return switch (this) {
      stations => l10n.stations,
      tags => l10n.tags,
      history => l10n.history,
    };
  }
}

final radioModelProvider = ChangeNotifierProvider(
  (ref) => RadioModel(
    radioService: getService<RadioService>(),
    libraryService: getService<LibraryService>(),
  ),
);
