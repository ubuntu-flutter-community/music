import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:desktop_notifications/desktop_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:github/github.dart';
import 'package:gtk/gtk.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:system_theme/system_theme.dart';
import 'package:ubuntu_service/ubuntu_service.dart';
import 'package:window_manager/window_manager.dart';
import 'package:yaru/yaru.dart';

import 'app.dart';
import 'external_path.dart';
import 'library.dart';
import 'local_audio.dart';
import 'notifications.dart';
import 'player.dart';
import 'podcasts.dart';
import 'radio.dart';
import 'settings.dart';

Future<void> main(List<String> args) async {
  if (!isMobile) {
    await YaruWindowTitleBar.ensureInitialized();
    if (!Platform.isLinux) {
      await windowManager.ensureInitialized();
      WindowManager.instance.setMinimumSize(const Size(500, 700));
    }
  }
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  if (!Platform.isLinux) {
    SystemTheme.fallbackColor = Colors.greenAccent;
    await SystemTheme.accentColor.load();
  }

  final settingsService = SettingsService();
  await settingsService.init();
  registerService<SettingsService>(
    () => settingsService,
    dispose: (s) async => await s.dispose(),
  );

  final libraryService = LibraryService();

  final playerService = PlayerService(
    controller: VideoController(
      Player(
        configuration: const PlayerConfiguration(title: 'MusicPod'),
      ),
    ),
    libraryService: libraryService,
  );
  await playerService.init();

  registerService<PlayerService>(
    () => playerService,
    dispose: (s) async => await s.dispose(),
  );

  registerService<LibraryService>(
    () => libraryService,
    dispose: (s) async => await s.dispose(),
  );
  registerService<LocalAudioService>(
    () => LocalAudioService(settingsService: settingsService),
    dispose: (s) async => await s.dispose(),
  );

  final notificationsService =
      NotificationsService(Platform.isLinux ? NotificationsClient() : null);

  registerService<NotificationsService>(
    () => notificationsService,
    dispose: (s) async => await s.dispose(),
  );
  registerService<PodcastService>(
    () => PodcastService(
      notificationsService: notificationsService,
      settingsService: settingsService,
    ),
    dispose: (s) async => await s.dispose(),
  );
  final connectivity = Connectivity();
  registerService<Connectivity>(
    () => connectivity,
  );

  registerService<ExternalPathService>(
    () => ExternalPathService(
      gtkNotifier: Platform.isLinux ? GtkApplicationNotifier(args) : null,
      playerService: playerService,
    ),
    dispose: (s) => s.dispose(),
  );

  registerService<RadioService>(() => RadioService());

  registerService(GitHub.new);

  runApp(
    ProviderScope(
      child: Platform.isLinux
          ? const GtkApplication(child: YaruMusicPodApp())
          : const MaterialMusicPodApp(),
    ),
  );
}
