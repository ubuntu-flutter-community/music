import 'package:flutter/widgets.dart';
import 'package:github/github.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:safe_change_notifier/safe_change_notifier.dart';

import '../common/view/snackbars.dart';
import '../constants.dart';
import '../settings/settings_service.dart';

class AppModel extends SafeChangeNotifier {
  AppModel({
    required SettingsService settingsService,
    required GitHub gitHub,
    required bool allowManualUpdates,
  })  : _countryCode = WidgetsBinding
            .instance.platformDispatcher.locale.countryCode
            ?.toLowerCase(),
        _gitHub = gitHub,
        _allowManualUpdates = allowManualUpdates,
        _settingsService = settingsService;

  final GitHub _gitHub;
  final SettingsService _settingsService;
  final bool _allowManualUpdates;
  bool get allowManualUpdate => _allowManualUpdates;

  final String? _countryCode;
  String? get countryCode => _countryCode;

  bool _showWindowControls = true;
  bool get showWindowControls => _showWindowControls;
  void setShowWindowControls(bool value) {
    _showWindowControls = value;
    notifyListeners();
  }

  bool? _fullWindowMode;
  bool? get fullWindowMode => _fullWindowMode;
  void setFullWindowMode(bool? value) {
    if (value == null || value == _fullWindowMode) return;
    _fullWindowMode = value;
    notifyListeners();
  }

  String? _appName;
  String? get appName => _appName;
  String? _packageName;
  String? get packageName => _packageName;
  String? _version;
  String? get version => _version;
  String? _buildNumber;
  String? get buildNumber => _buildNumber;

  Future<void> disposePatchNotes() async {
    if (_version != null) {
      return _settingsService.disposePatchNotes(_version!);
    } else {
      return Future.error('unknown version');
    }
  }

  bool recentPatchNotesDisposed() => _version == null
      ? false
      : _settingsService.recentPatchNotesDisposed(_version!);
  bool? _updateAvailable;
  bool? get updateAvailable => _updateAvailable;
  String? _onlineVersion;
  String? get onlineVersion => _onlineVersion;
  Future<void> checkForUpdate(bool isOnline, BuildContext context) async {
    _updateAvailable == null;
    notifyListeners();

    if (!_allowManualUpdates || !isOnline) {
      _updateAvailable = false;
      notifyListeners();
      return Future.value();
    }
    _onlineVersion = await getOnlineVersion().onError(
      (error, stackTrace) {
        if (context.mounted) {
          showSnackBar(context: context, content: Text(error.toString()));
        }
        return null;
      },
    );
    final onlineVersion = getExtendedVersionNumber(_onlineVersion) ?? 0;
    final currentVersion = getExtendedVersionNumber(version) ?? 0;
    if (onlineVersion > currentVersion) {
      _updateAvailable = true;
    } else {
      _updateAvailable = false;
    }
    notifyListeners();
  }

  int? getExtendedVersionNumber(String? version) {
    if (version == null) return null;
    version = version.replaceAll('v', '');
    List versionCells = version.split('.');
    versionCells = versionCells.map((i) => int.parse(i)).toList();
    return versionCells[0] * 100000 + versionCells[1] * 1000 + versionCells[2];
  }

  Future<void> init() async {
    final packageInfo = await PackageInfo.fromPlatform();
    _appName = packageInfo.appName;
    _packageName = packageInfo.packageName;
    _version = packageInfo.version;
    _buildNumber = packageInfo.buildNumber;
  }

  Future<String?> getOnlineVersion() async {
    final release = await _gitHub.repositories
        .listReleases(RepositorySlug.full(kGitHubShortLink))
        .toList();
    return release.firstOrNull?.tagName;
  }

  Future<List<Contributor>> getContributors() async {
    return _gitHub.repositories
        .listContributors(
          RepositorySlug.full(kGitHubShortLink),
        )
        .where((c) => c.type == 'User')
        .toList();
  }
}
