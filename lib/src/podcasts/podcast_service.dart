import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:podcast_search/podcast_search.dart';

import '../../common.dart';
import '../../data.dart';
import '../../utils.dart';
import '../notifications/notifications_service.dart';

class PodcastService {
  final NotificationsService _notificationsService;
  PodcastService(this._notificationsService) : _search = Search();

  final _searchChangedController = StreamController<bool>.broadcast();
  Stream<bool> get searchChanged => _searchChangedController.stream;
  SearchResult? _searchResult;
  SearchResult? get searchResult => _searchResult;
  final Search _search;

  Future<void> dispose() async {
    _searchChangedController.close();
  }

  Future<SearchResult?> search({
    String? searchQuery,
    PodcastGenre podcastGenre = PodcastGenre.science,
    Country? country,
    int limit = 10,
  }) async {
    _searchResult = null;

    SearchResult? result;
    String? error;
    try {
      if (searchQuery == null || searchQuery.isEmpty == true) {
        result = await _search.charts(
          genre: podcastGenre == PodcastGenre.all ? '' : podcastGenre.id,
          limit: limit,
          country: country ?? Country.none,
        );
      } else {
        result = await _search.search(
          searchQuery,
          country: country ?? Country.none,
          language: Language.none,
          limit: limit,
        );
      }
    } catch (e) {
      error = e.toString();
    }

    if (result != null && result.successful) {
      _searchResult = result;
    } else {
      _searchResult =
          SearchResult.fromError(lastError: error ?? 'Something went wrong');
    }
    _searchChangedController.add(true);
    return _searchResult;
  }

  Future<void> updatePodcasts({
    required Map<String, Set<Audio>> oldPodcasts,
    required void Function(String name, Set<Audio> audios) updatePodcast,
    required String updateMessage,
  }) async {
    for (final old in oldPodcasts.entries) {
      if (old.value.isNotEmpty) {
        final list = old.value.toList();
        sortListByAudioFilter(
          audioFilter: AudioFilter.year,
          audios: list,
          descending: true,
        );
        final firstOld = list.firstOrNull;

        if (firstOld?.website != null) {
          await findEpisodes(
            feedUrl: firstOld!.website!,
          ).then((audios) {
            if (firstOld.year != null &&
                    audios.firstOrNull?.year == firstOld.year ||
                audios.isEmpty) return;

            updatePodcast(old.key, audios);
            _notificationsService.notify(
              message: '$updateMessage ${firstOld.album ?? old.value}',
            );
          });
        }
      }
    }
  }
}

Audio _createAudio(
  Episode episode,
  Podcast? podcast, [
  String? itemImageUrl,
  String? genre,
]) {
  return Audio(
    url: episode.contentUrl,
    audioType: AudioType.podcast,
    imageUrl: episode.imageUrl,
    albumArtUrl: itemImageUrl ?? podcast?.image,
    title: episode.title,
    album: podcast?.title,
    artist: podcast?.copyright,
    albumArtist: podcast?.description,
    durationMs: episode.duration?.inMilliseconds.toDouble(),
    year: episode.publicationDate?.millisecondsSinceEpoch,
    description: episode.description,
    website: podcast?.url,
    genre: genre,
  );
}

Future<Set<Audio>> findEpisodes({
  required String feedUrl,
  String? itemImageUrl,
  String? genre,
}) async {
  final episodes = <Audio>{};
  final Podcast? podcast = await compute(loadPodcast, feedUrl);

  if (podcast?.episodes.isNotEmpty == true) {
    for (var episode in podcast?.episodes ?? []) {
      if (episode.contentUrl != null) {
        final audio = _createAudio(
          episode,
          podcast,
          itemImageUrl,
          genre,
        );
        episodes.add(audio);
      }
    }
  }
  final sortedEpisodes = episodes.toList();
  sortListByAudioFilter(
    audioFilter: AudioFilter.year,
    audios: sortedEpisodes,
    descending: true,
  );
  return Set<Audio>.from(sortedEpisodes);
}

Future<Podcast?> loadPodcast(String url) async {
  try {
    return await Podcast.loadFeed(
      url: url,
    );
  } catch (e) {
    return null;
  }
}
