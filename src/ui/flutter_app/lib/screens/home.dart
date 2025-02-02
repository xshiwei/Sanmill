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

import 'package:feedback/feedback.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../generated/intl/l10n.dart';
import '../models/general_settings.dart';
import '../models/rule_settings.dart';
import '../services/database/database.dart';
import '../services/environment_config.dart';
import '../services/logger.dart';
import '../services/mill/mill.dart';
import '../shared/constants.dart';
import '../shared/custom_drawer/custom_drawer.dart';
import '../shared/double_back_to_close_app.dart';
import '../shared/gif_share/gif_share.dart';
import '../shared/gif_share/widgets_to_image.dart';
import '../shared/painters/painters.dart';
import '../shared/privacy_dialog.dart';
import '../shared/scaffold_messenger.dart';
import '../shared/stack_list.dart';
import '../shared/theme/app_theme.dart';
import '../shared/wizard/wizard_dialog.dart';
import 'about_page.dart';
import 'appearance_settings/appearance_settings_page.dart';
import 'game_page/game_page.dart';
import 'general_settings/general_settings_page.dart';
import 'help_screen.dart';
import 'rule_settings/rule_settings_page.dart';

enum _DrawerIndex {
  humanVsAi,
  humanVsHuman,
  aiVsAi,
  setupPosition,
  generalSettings,
  ruleSettings,
  appearance,
  howToPlay,
  feedback,
  about,
  exit,
}

extension _DrawerScreen on _DrawerIndex {
  Widget? get screen {
    switch (this) {
      case _DrawerIndex.humanVsAi:
        return GamePage(
          GameMode.humanVsAi,
          key: const Key("Human-Ai"),
        );
      case _DrawerIndex.humanVsHuman:
        return GamePage(
          GameMode.humanVsHuman,
          key: const Key("Human-Human"),
        );
      case _DrawerIndex.aiVsAi:
        return GamePage(
          GameMode.aiVsAi,
          key: const Key("Ai-Ai"),
        );
      case _DrawerIndex.setupPosition:
        return GamePage(
          GameMode.setupPosition,
          key: const Key("SetupPosition"),
        );
      case _DrawerIndex.generalSettings:
        return const GeneralSettingsPage();
      case _DrawerIndex.ruleSettings:
        return const RuleSettingsPage();
      case _DrawerIndex.appearance:
        return const AppearanceSettingsPage();
      case _DrawerIndex.howToPlay:
        return const HowToPlayScreen();
      case _DrawerIndex.feedback:
        // ignore: only_throw_errors
        throw ErrorDescription(
          "Feedback screen is not a widget and should be called separately",
        );
      case _DrawerIndex.about:
        return const AboutPage();
      case _DrawerIndex.exit:
        if (EnvironmentConfig.test == false) {
          SystemChannels.platform.invokeMethod<void>('SystemNavigator.pop');
        }
        return null;
    }
  }
}

/// Home View
///
/// This widget implements the home view of our app.
class Home extends StatefulWidget {
  const Home({super.key});

  @override
  HomeState createState() => HomeState();
}

class HomeState extends State<Home> with TickerProviderStateMixin {
  final CustomDrawerController _controller = CustomDrawerController();

  Widget _screenView = kIsWeb
      ? _DrawerIndex.humanVsHuman.screen!
      : _DrawerIndex.humanVsAi.screen!;
  _DrawerIndex _drawerIndex =
      kIsWeb ? _DrawerIndex.humanVsHuman : _DrawerIndex.humanVsAi;
  final StackList<_DrawerIndex> _routes = StackList<_DrawerIndex>();

  /// Callback from drawer for replace screen
  /// as user need with passing DrawerIndex (Enum index)
  void _changeIndex(_DrawerIndex index) {
    _controller.hideDrawer();
    if (_drawerIndex == index && _drawerIndex != _DrawerIndex.feedback) {
      return;
    }

    if ((index == _DrawerIndex.howToPlay ||
            index == _DrawerIndex.about ||
            index == _DrawerIndex.feedback) &&
        EnvironmentConfig.test == true) {
      return logger.w("Do not test HowToPlay/Feedback/About page.");
    }

    if (index == _DrawerIndex.feedback) {
      if (Platform.isAndroid) {
        return BetterFeedback.of(context).show(_launchFeedback);
      } else {
        return logger.w("flutter_email_sender does not support this platform.");
      }
    }

    setState(() {
      assert(index != _DrawerIndex.feedback);
      _pushRoute(index);
      _drawerIndex = index;
      if (index.screen != null) {
        _screenView = index.screen!;
      }
    });
  }

  bool _isGame(_DrawerIndex index) {
    return index.index < 4;
  }

  void _pushRoute(_DrawerIndex index) {
    final bool curIsGame = _isGame(_drawerIndex);
    final bool nextIsGame = _isGame(index);
    if (curIsGame && !nextIsGame) {
      _routes.push(index);
    } else if (!curIsGame && nextIsGame) {
      _routes.clear();
      _routes.push(index);
    } else {
      _routes.pop();
      _routes.push(index);
    }
    setState(() {});
  }

  bool _canPopRoute() {
    if (_routes.length > 1) {
      _routes.pop();
      setState(() {
        _drawerIndex = _routes.top();
        if (_drawerIndex.screen != null) {
          _screenView = _drawerIndex.screen!;
        }
        logger.v('_drawerIndex: $_drawerIndex');
      });
      return true;
    } else {
      return false;
    }
  }

  void firstRun(BuildContext context) {
    if (DB().generalSettings.firstRun == true) {
      DB().generalSettings = DB().generalSettings.copyWith(firstRun: false);

      final String countryCode = Localizations.localeOf(context).languageCode;

      switch (countryCode) {
        case "fa": // Iran
          DB().ruleSettings = DB()
              .ruleSettings
              .copyWith(piecesCount: 12, hasDiagonalLines: true);
          break;
        default:
          break;
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showPrivacyDialog());
    _routes.push(_drawerIndex);
  }

  @override
  void didChangeDependencies() {
    firstRun(context);

    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    AppTheme.boardPadding = ((deviceWidth(context) - AppTheme.boardMargin * 2) *
                DB().displaySettings.pieceWidth /
                7) /
            2 +
        4;

    final List<CustomDrawerItem<_DrawerIndex>> drawerItems =
        <CustomDrawerItem<_DrawerIndex>>[
      if (!kIsWeb)
        CustomDrawerItem<_DrawerIndex>(
          value: _DrawerIndex.humanVsAi,
          title: S.of(context).humanVsAi,
          icon: const Icon(FluentIcons.person_24_regular),
          groupValue: _drawerIndex,
          onChanged: _changeIndex,
        ),
      CustomDrawerItem<_DrawerIndex>(
        value: _DrawerIndex.humanVsHuman,
        title: S.of(context).humanVsHuman,
        icon: const Icon(FluentIcons.people_24_regular),
        groupValue: _drawerIndex,
        onChanged: _changeIndex,
      ),
      if (!kIsWeb)
        CustomDrawerItem<_DrawerIndex>(
          value: _DrawerIndex.aiVsAi,
          title: S.of(context).aiVsAi,
          icon: const Icon(FluentIcons.bot_24_regular),
          groupValue: _drawerIndex,
          onChanged: _changeIndex,
        ),
      CustomDrawerItem<_DrawerIndex>(
        value: _DrawerIndex.setupPosition,
        title: S.of(context).setupPosition,
        icon: const Icon(FluentIcons.drafts_24_regular),
        groupValue: _drawerIndex,
        onChanged: _changeIndex,
      ),
      CustomDrawerItem<_DrawerIndex>(
        value: _DrawerIndex.generalSettings,
        title: S.of(context).generalSettings,
        icon: const Icon(FluentIcons.options_24_regular),
        groupValue: _drawerIndex,
        onChanged: _changeIndex,
      ),
      CustomDrawerItem<_DrawerIndex>(
        value: _DrawerIndex.ruleSettings,
        title: S.of(context).ruleSettings,
        icon: const Icon(FluentIcons.task_list_ltr_24_regular),
        groupValue: _drawerIndex,
        onChanged: _changeIndex,
      ),
      CustomDrawerItem<_DrawerIndex>(
        value: _DrawerIndex.appearance,
        title: S.of(context).appearance,
        icon: const Icon(FluentIcons.design_ideas_24_regular),
        groupValue: _drawerIndex,
        onChanged: _changeIndex,
      ),
      CustomDrawerItem<_DrawerIndex>(
        value: _DrawerIndex.howToPlay,
        title: S.of(context).howToPlay,
        icon: const Icon(FluentIcons.question_circle_24_regular),
        groupValue: _drawerIndex,
        onChanged: _changeIndex,
      ),
      if (!kIsWeb && Platform.isAndroid)
        CustomDrawerItem<_DrawerIndex>(
          value: _DrawerIndex.feedback,
          title: S.of(context).feedback,
          icon: const Icon(FluentIcons.chat_warning_24_regular),
          groupValue: _drawerIndex,
          onChanged: _changeIndex,
        ),
      CustomDrawerItem<_DrawerIndex>(
        value: _DrawerIndex.about,
        title: S.of(context).about,
        icon: const Icon(FluentIcons.info_24_regular),
        groupValue: _drawerIndex,
        onChanged: _changeIndex,
      ),
      if (!kIsWeb && Platform.isAndroid)
        CustomDrawerItem<_DrawerIndex>(
          value: _DrawerIndex.exit,
          title: S.of(context).exit,
          icon: const Icon(FluentIcons.power_24_regular),
          groupValue: _drawerIndex,
          onChanged: _changeIndex,
        ),
    ];

    return DoubleBackToCloseApp(
      snackBar: CustomSnackBar(S.of(context).tapBackAgainToLeave),
      willBack: () {
        return !_canPopRoute();
      },
      child: WidgetsToImage(
          controller: GifShare().controller,
          child: ValueListenableBuilder<CustomDrawerValue>(
            valueListenable: _controller,
            builder: (_, CustomDrawerValue value, Widget? child) =>
                CustomDrawer(
              controller: _controller,
              header: CustomDrawerHeader(
                title: S.of(context).appName,
              ),
              items: drawerItems,
              // TODO: 4 means Setup Position
              disabledGestures: (kIsWeb ||
                      Platform.isWindows ||
                      Platform.isLinux ||
                      Platform.isMacOS) &&
                  _drawerIndex.index < 4 &&
                  !value.visible,
              orientation: MediaQuery.of(context).orientation,
              child: _screenView,
            ),
          )),
    );
  }

  void _showPrivacyDialog() {
    if (EnvironmentConfig.test == true) {
      return;
    }

    if (!DB().generalSettings.isPrivacyPolicyAccepted &&
        Localizations.localeOf(context).languageCode.startsWith("zh") &&
        (!kIsWeb && Platform.isAndroid)) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) =>
            PrivacyDialog(onConfirm: _showWizardDialog),
      );
    } else {
      _showWizardDialog();
    }
  }

  Future<void> _showWizardDialog() async {
    if (DB().generalSettings.showWizard) {
      await Navigator.of(context).push(
        MaterialPageRoute<dynamic>(
          builder: (BuildContext context) => const WizardDialog(),
          fullscreenDialog: true,
        ),
      );
    }
  }

  /// Drafts an email and sends it to the developer
  static Future<void> _launchFeedback(UserFeedback feedback) async {
    final String screenshotFilePath =
        await _saveFeedbackImage(feedback.screenshot);
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    final String version =
        "${packageInfo.version} (${packageInfo.buildNumber})";

    final Email email = Email(
      body: feedback.text,
      subject: Constants.feedbackSubjectPrefix +
          version +
          Constants.feedbackSubjectSuffix,
      recipients: Constants.recipients,
      attachmentPaths: <String>[screenshotFilePath],
    );
    await FlutterEmailSender.send(email);
  }

  static Future<String> _saveFeedbackImage(Uint8List screenshot) async {
    final Directory output = await getTemporaryDirectory();
    final String screenshotFilePath = "${output.path}/sanmill-feedback.png";
    final File screenshotFile = File(screenshotFilePath);
    await screenshotFile.writeAsBytes(screenshot);
    return screenshotFilePath;
  }
}
