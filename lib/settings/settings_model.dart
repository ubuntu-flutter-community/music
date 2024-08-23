import 'dart:async';

import 'package:github/github.dart';
import 'package:safe_change_notifier/safe_change_notifier.dart';

import '../../external_path/external_path_service.dart';
import '../common/data/close_btn_action.dart';
import 'settings_service.dart';

class SettingsModel extends SafeChangeNotifier {
  SettingsModel({
    required SettingsService service,
    required ExternalPathService externalPathService,
    required GitHub gitHub,
  })  : _service = service,
        _externalPathService = externalPathService;

  final SettingsService _service;
  final ExternalPathService _externalPathService;

  StreamSubscription<bool>? _usePodcastIndexChangedSub;
  StreamSubscription<bool>? _podcastIndexApiKeyChangedSub;
  StreamSubscription<bool>? _podcastIndexApiSecretChangedSub;
  StreamSubscription<bool>? _neverShowFailedImportsSub;
  StreamSubscription<bool>? _directoryChangedSub;
  StreamSubscription<bool>? _themeIndexChangedSub;
  StreamSubscription<bool>? _recentPatchNotesDisposedChangedSub;
  StreamSubscription<bool>? _useArtistGridViewChangedSub;
  StreamSubscription<bool>? _closeBtnActionIndexChangedSub;

  String? get directory => _service.directory;
  Future<void> setDirectory(String value) async => _service.setDirectory(value);

  bool get neverShowFailedImports => _service.neverShowFailedImports;
  void setNeverShowFailedImports(bool value) =>
      _service.setNeverShowFailedImports(value);

  bool get usePodcastIndex => _service.usePodcastIndex;
  Future<void> setUsePodcastIndex(bool value) async =>
      _service.setUsePodcastIndex(value);

  int get themeIndex => _service.themeIndex;
  void setThemeIndex(int value) => _service.setThemeIndex(value);

  String? get podcastIndexApiKey => _service.podcastIndexApiKey;
  void setPodcastIndexApiKey(String value) =>
      _service.setPodcastIndexApiKey(value);

  String? get podcastIndexApiSecret => _service.podcastIndexApiSecret;
  void setPodcastIndexApiSecret(String value) async =>
      _service.setPodcastIndexApiSecret(value);

  void playOpenedFile() => _externalPathService.playOpenedFile();

  Future<String?> getPathOfDirectory() async =>
      _externalPathService.getPathOfDirectory();

  CloseBtnAction get closeBtnActionIndex => _service.closeBtnActionIndex;
  void setCloseBtnActionIndex(CloseBtnAction value) =>
      _service.setCloseBtnActionIndex(value);

  void init() {
    _themeIndexChangedSub ??=
        _service.themeIndexChanged.listen((_) => notifyListeners());
    _usePodcastIndexChangedSub ??=
        _service.usePodcastIndexChanged.listen((_) => notifyListeners());
    _podcastIndexApiKeyChangedSub ??=
        _service.podcastIndexApiKeyChanged.listen((_) => notifyListeners());
    _podcastIndexApiSecretChangedSub ??=
        _service.podcastIndexApiSecretChanged.listen((_) => notifyListeners());
    _neverShowFailedImportsSub ??=
        _service.neverShowFailedImportsChanged.listen((_) => notifyListeners());
    _directoryChangedSub ??=
        _service.directoryChanged.listen((_) => notifyListeners());
    _recentPatchNotesDisposedChangedSub ??= _service
        .recentPatchNotesDisposedChanged
        .listen((_) => notifyListeners());
    _closeBtnActionIndexChangedSub ??=
        _service.closeBtnActionChanged.listen((_) => notifyListeners());
  }

  @override
  Future<void> dispose() async {
    await _themeIndexChangedSub?.cancel();
    await _usePodcastIndexChangedSub?.cancel();
    await _podcastIndexApiKeyChangedSub?.cancel();
    await _podcastIndexApiSecretChangedSub?.cancel();
    await _neverShowFailedImportsSub?.cancel();
    await _directoryChangedSub?.cancel();
    await _recentPatchNotesDisposedChangedSub?.cancel();
    await _useArtistGridViewChangedSub?.cancel();
    await _closeBtnActionIndexChangedSub?.cancel();
    super.dispose();
  }
}
