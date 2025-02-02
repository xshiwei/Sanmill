// This file is part of Sanmill.
// Copyright (C) 2019-2023 The Sanmill developers (see AUTHORS file)
//
// Sanmill is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Sanmill is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

import 'dart:io';
import 'dart:ui';

import 'package:catcher/catcher.dart';
import 'package:feedback/feedback.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_driver/driver_extension.dart';
import 'package:hive_flutter/hive_flutter.dart' show Box;
import 'package:path_provider/path_provider.dart';

import 'generated/intl/l10n.dart';
import 'models/display_settings.dart';
import 'screens/home.dart';
import 'services/database/database.dart';
import 'services/environment_config.dart';
import 'services/logger.dart';
import 'shared/constants.dart';
import 'shared/feedback_localization.dart';
import 'shared/painters/painters.dart';
import 'shared/scaffold_messenger.dart';
import 'shared/theme/app_theme.dart';

part 'package:sanmill/services/catcher.dart';
part 'package:sanmill/services/init_system_ui.dart';

Future<void> main() async {
  logger.i('Environment [catcher]: ${EnvironmentConfig.catcher}');
  logger.i('Environment [dev_mode]: ${EnvironmentConfig.devMode}');
  logger.i('Environment [test]: ${EnvironmentConfig.test}');

  if (EnvironmentConfig.test) {
    enableFlutterDriverExtension();
  }

  await DB.init();

  _initUI();

  if (EnvironmentConfig.catcher && !kIsWeb && !Platform.isIOS) {
    catcher = Catcher(
      rootWidget: const SanmillApp(),
      ensureInitialized: true,
    );

    await _initCatcher(catcher);

    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      if (EnvironmentConfig.catcher == true) {
        Catcher.reportCheckedError(error, stack);
      }
      return true;
    };
  } else {
    runApp(const SanmillApp());
  }
}

class SanmillApp extends StatelessWidget {
  const SanmillApp({super.key});

  @override
  Widget build(BuildContext context) {
    DB(window.platformDispatcher.locale);

    if (kIsWeb) {
      Locale? locale;

      if (WidgetsBinding.instance.window.locale == const Locale('und') ||
          !S.supportedLocales.contains(
              Locale(WidgetsBinding.instance.window.locale.languageCode))) {
        locale = const Locale('en');
      } else {
        locale = WidgetsBinding.instance.window.locale;
      }

      return MaterialApp(
        key: GlobalKey<ScaffoldState>(),
        scaffoldMessengerKey: rootScaffoldMessengerKey,
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        locale: locale,
        theme: AppTheme.lightThemeData,
        darkTheme: AppTheme.darkThemeData,
        debugShowCheckedModeBanner: EnvironmentConfig.devMode,
        builder: (BuildContext context, Widget? child) {
          _initOrientation(context);
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(),
            child: child!,
          );
        },
        home: Builder(
          builder: _buildHome,
        ),
      );
    }

    return ValueListenableBuilder<Box<DisplaySettings>>(
      valueListenable: DB().listenDisplaySettings,
      builder: _buildApp,
    );
  }

  Widget _buildApp(BuildContext context, Box<DisplaySettings> box, Widget? _) {
    final DisplaySettings displaySettings = box.get(
      DB.displaySettingsKey,
      defaultValue: const DisplaySettings(),
    )!;

    Locale? locale;

    if (displaySettings.locale == null) {
      if (WidgetsBinding.instance.window.locale == const Locale('und') ||
          !S.supportedLocales.contains(
              Locale(WidgetsBinding.instance.window.locale.languageCode))) {
        DB().displaySettings =
            displaySettings.copyWith(locale: const Locale('en'));
        locale = const Locale('en');
      } else {
        locale = WidgetsBinding.instance.window.locale;
      }
    } else {
      locale = displaySettings.locale;
    }

    final MaterialApp materialApp = MaterialApp(
      /// Add navigator key from Catcher.
      /// It will be used to navigate user to report page or to show dialog.
      navigatorKey: (EnvironmentConfig.catcher && !kIsWeb && !Platform.isIOS)
          ? Catcher.navigatorKey
          : navigatorKey,
      key: GlobalKey<ScaffoldState>(),
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      localizationsDelegates: S.localizationsDelegates,
      supportedLocales: S.supportedLocales,
      locale: locale,
      theme: AppTheme.lightThemeData,
      darkTheme: AppTheme.darkThemeData,
      debugShowCheckedModeBanner: EnvironmentConfig.devMode,
      builder: (BuildContext context, Widget? child) {
        _initOrientation(context);
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaleFactor: displaySettings.fontScale,
          ),
          child: child!,
        );
      },
      home: Builder(
        builder: _buildHome,
      ),
    );

    if (kIsWeb || Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return materialApp;
    } else if (Platform.isAndroid || Platform.isIOS) {
      return BetterFeedback(
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          ...S.localizationsDelegates,
          CustomFeedbackLocalizationsDelegate.delegate,
        ],
        localeOverride: displaySettings.locale,
        theme: AppTheme.feedbackTheme,
        child: materialApp,
      );
    }

    return materialApp;
  }

  Widget _buildHome(BuildContext context) {
    return const Scaffold(
      resizeToAvoidBottomInset: false,
      body: Home(),
    );
  }
}
