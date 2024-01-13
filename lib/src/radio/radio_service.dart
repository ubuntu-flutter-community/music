import 'dart:async';
import 'dart:io';

import 'package:basic_utils/basic_utils.dart';
import 'package:radio_browser_api/radio_browser_api.dart';

import '../../constants.dart';

class RadioService {
  RadioBrowserApi? _radioBrowserApi;

  RadioService();

  Future<String?> init() async {
    if (_radioBrowserApi?.host != null) {
      return _radioBrowserApi?.host;
    }

    for (var host in (await _findHost())) {
      try {
        _radioBrowserApi ??= RadioBrowserApi.fromHost(host);
        if (_radioBrowserApi != null) {
          return _radioBrowserApi?.host;
        }
      } on Exception catch (e) {
        setStatusCode(e.toString());
      }
    }

    return null;
  }

  Future<List<String>> _findHost() async {
    final hosts = <String>[];
    try {
      final records = await DnsUtils.lookupRecord(
        kRadioBrowserBaseUrl,
        RRecordType.A,
      );
      if (records?.isNotEmpty == false) {
        return [];
      }

      for (RRecord record in records ?? <RRecord>[]) {
        final reverse = await DnsUtils.reverseDns(record.data);
        for (RRecord r in reverse ?? <RRecord>[]) {
          hosts.add(r.data.replaceAll('info.', 'info'));
        }
      }
      return hosts;
    } on SocketException {
      return [];
    }
  }

  Future<void> dispose() async {
    // _searchController.close();
    _tagsChangedController.close();
    _statusCodeController.close();
  }

  String? _statusCode;
  String? get statusCode => _statusCode;
  void setStatusCode(String? value) {
    _statusCodeController.add(value != _statusCode);
    _statusCode = value;
  }

  final _statusCodeController = StreamController<bool>.broadcast();
  Stream<bool> get statusCodeChanged => _statusCodeController.stream;

  Future<List<Station>?> getStations({
    String? country,
    String? name,
    String? state,
    Tag? tag,
    int limit = 100,
  }) async {
    if (_radioBrowserApi == null) {
      return [];
    }

    RadioBrowserListResponse<Station>? response;
    try {
      if (name?.isEmpty == false) {
        response = await _radioBrowserApi!.getStationsByName(
          name: name!,
          parameters: InputParameters(
            hidebroken: true,
            order: 'stationcount',
            limit: limit,
          ),
        );
      } else if (country?.isEmpty == false) {
        response = await _radioBrowserApi!.getStationsByCountry(
          country: country!,
          parameters: InputParameters(
            hidebroken: true,
            order: 'stationcount',
            limit: limit,
          ),
        );
      } else if (tag != null) {
        response = await _radioBrowserApi!.getStationsByTag(
          tag: tag.name,
          parameters: InputParameters(
            hidebroken: true,
            order: 'stationcount',
            limit: limit,
          ),
        );
      } else if (state?.isEmpty == false) {
        response = await _radioBrowserApi!.getStationsByState(
          state: state!,
          parameters: InputParameters(
            hidebroken: true,
            order: 'stationcount',
            limit: limit,
          ),
        );
      }
    } on Exception catch (e) {
      if (e is SocketException) {
        return [];
      }
    }
    return response?.items;
  }

  List<Tag>? _tags;
  List<Tag>? get tags => _tags;
  void setTags(List<Tag>? value) {
    _tags = value;
    _tagsChangedController.add(true);
  }

  final _tagsChangedController = StreamController<bool>.broadcast();
  Stream<bool> get tagsChanged => _tagsChangedController.stream;

  Future<void> loadTags() async {
    if (_radioBrowserApi == null) return;
    try {
      final response = await _radioBrowserApi!.getTags(
        parameters: const InputParameters(
          hidebroken: true,
          limit: 500,
          order: 'stationcount',
          reverse: true,
        ),
      );
      _tags = response.items;
    } on Exception catch (e) {
      if (e is SocketException) {
        _tags = [];
      }
    }
  }

  // String? _searchQuery;
  // String? get searchQuery => _searchQuery;
  // final _searchController = StreamController<bool>.broadcast();
  // Stream<bool> get searchQueryChanged => _searchController.stream;
  // void setSearchQuery(String? value) {
  //   _searchQuery = value;
  //   _searchController.add(true);
  // }
}
