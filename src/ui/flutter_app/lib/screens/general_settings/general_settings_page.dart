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

import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart' show Box;

import '../../generated/intl/l10n.dart';
import '../../models/general_settings.dart';
import '../../services/database/database.dart';
import '../../services/environment_config.dart';
import '../../services/logger.dart';
import '../../services/mill/mill.dart';
import '../../shared/constants.dart';
import '../../shared/custom_drawer/custom_drawer.dart';
import '../../shared/scaffold_messenger.dart';
import '../../shared/settings/settings.dart';
import '../../shared/theme/app_theme.dart';

part 'package:sanmill/screens/general_settings/algorithm_modal.dart';
part 'package:sanmill/screens/general_settings/duration_modal.dart';
part 'package:sanmill/screens/general_settings/move_time_slider.dart';
part 'package:sanmill/screens/general_settings/ratio_modal.dart';
part 'package:sanmill/screens/general_settings/reset_settings_alert.dart';
part 'package:sanmill/screens/general_settings/skill_level_picker.dart';

class GeneralSettingsPage extends StatelessWidget {
  const GeneralSettingsPage({super.key});
  static const String _tag = "[general_settings_page]";

  // Restore
  void _restoreFactoryDefaultSettings(BuildContext context) => showDialog(
        context: context,
        builder: (_) => const _ResetSettingsAlert(),
      );

  void _setSkillLevel(BuildContext context) => showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const _SkillLevelPicker(),
      );

  void _setMoveTime(BuildContext context) => showModalBottomSheet(
        context: context,
        builder: (_) => const _MoveTimeSlider(),
      );

  void _setWhoMovesFirst(GeneralSettings generalSettings, bool value) {
    DB().generalSettings = generalSettings.copyWith(aiMovesFirst: value);

    MillController().position.changeSideToMove();

    Position.resetScore();

    logger.v("$_tag aiMovesFirst: $value");
  }

  void _setAiIsLazy(GeneralSettings generalSettings, bool value) {
    DB().generalSettings = generalSettings.copyWith(aiIsLazy: value);

    logger.v("$_tag aiIsLazy: $value");
  }

  void _setAlgorithm(BuildContext context, GeneralSettings generalSettings) {
    void callback(SearchAlgorithm? searchAlgorithm) {
      Navigator.pop(context);

      DB().generalSettings =
          generalSettings.copyWith(searchAlgorithm: searchAlgorithm);

      switch (searchAlgorithm) {
        case SearchAlgorithm.alphaBeta:
          rootScaffoldMessengerKey.currentState!
              .showSnackBarClear(S.of(context).whatIsAlphaBeta);
          break;
        case SearchAlgorithm.pvs:
          rootScaffoldMessengerKey.currentState!
              .showSnackBarClear(S.of(context).whatIsPvs);
          break;
        case SearchAlgorithm.mtdf:
          rootScaffoldMessengerKey.currentState!
              .showSnackBarClear(S.of(context).whatIsMtdf);
          break;
        case null:
          break;
      }

      logger.v("$_tag algorithm = $searchAlgorithm");
    }

    showModalBottomSheet(
      context: context,
      builder: (_) => _AlgorithmModal(
        algorithm: generalSettings.searchAlgorithm!,
        onChanged: callback,
      ),
    );
  }

  void _setDrawOnHumanExperience(GeneralSettings generalSettings, bool value) {
    DB().generalSettings =
        generalSettings.copyWith(drawOnHumanExperience: value);

    logger.v("$_tag drawOnHumanExperience: $value");
  }

  void _setConsiderMobility(GeneralSettings generalSettings, bool value) {
    DB().generalSettings = generalSettings.copyWith(considerMobility: value);

    logger.v("$_tag considerMobility: $value");
  }

  void _setIsAutoRestart(GeneralSettings generalSettings, bool value) {
    DB().generalSettings = generalSettings.copyWith(isAutoRestart: value);

    logger.v("$_tag isAutoRestart: $value");
  }

  void _setShufflingEnabled(GeneralSettings generalSettings, bool value) {
    DB().generalSettings = generalSettings.copyWith(shufflingEnabled: value);

    logger.v("$_tag shufflingEnabled: $value");
  }

  void _setTone(GeneralSettings generalSettings, bool value) {
    DB().generalSettings = generalSettings.copyWith(toneEnabled: value);

    logger.v("$_tag toneEnabled: $value");
  }

  void _setKeepMuteWhenTakingBack(
    GeneralSettings generalSettings,
    bool value,
  ) {
    DB().generalSettings =
        generalSettings.copyWith(keepMuteWhenTakingBack: value);

    logger.v("$_tag keepMuteWhenTakingBack: $value");
  }

  void _setScreenReaderSupport(GeneralSettings generalSettings, bool value) {
    DB().generalSettings = generalSettings.copyWith(screenReaderSupport: value);

    logger.v("$_tag screenReaderSupport: $value");
  }

  void _setGameScreenRecorderSupport(
      GeneralSettings generalSettings, bool value) {
    DB().generalSettings =
        generalSettings.copyWith(gameScreenRecorderSupport: value);

    logger.v("$_tag gameScreenRecorderSupport: $value");
  }

  void _setGameScreenRecorderDuration(
    BuildContext context,
    GeneralSettings generalSettings,
  ) {
    void callback(int? duration) {
      Navigator.pop(context);

      DB().generalSettings =
          generalSettings.copyWith(gameScreenRecorderDuration: duration);

      logger.v("[config] gameScreenRecorderDuration = $duration");
    }

    showModalBottomSheet(
      context: context,
      builder: (_) => _DurationModal(
        duration: generalSettings.gameScreenRecorderDuration,
        onChanged: callback,
      ),
    );
  }

  void _setGameScreenRecorderPixelRatio(
    BuildContext context,
    GeneralSettings generalSettings,
  ) {
    void callback(int? ratio) {
      // TODO: Take effect when start new game
      rootScaffoldMessengerKey.currentState!
          .showSnackBarClear(S.of(context).reopenToTakeEffect);

      Navigator.pop(context);

      DB().generalSettings =
          generalSettings.copyWith(gameScreenRecorderPixelRatio: ratio);

      logger.v("[config] gameScreenRecorderPixelRatio = $ratio");
    }

    showModalBottomSheet(
      context: context,
      builder: (_) => _RatioModal(
        ratio: generalSettings.gameScreenRecorderPixelRatio,
        onChanged: callback,
      ),
    );
  }

  SettingsList _buildGeneralSettingsList(
    BuildContext context,
    Box<GeneralSettings> box,
    _,
  ) {
    final GeneralSettings generalSettings = box.get(
      DB.generalSettingsKey,
      defaultValue: const GeneralSettings(),
    )!;

    return SettingsList(
      children: <Widget>[
        SettingsCard(
          title: Text(S.of(context).whoMovesFirst),
          children: <Widget>[
            SettingsListTile.switchTile(
              value: !generalSettings.aiMovesFirst,
              onChanged: (bool val) {
                _setWhoMovesFirst(generalSettings, !val);
                if (val == false) {
                  rootScaffoldMessengerKey.currentState!
                      .showSnackBarClear(S.of(context).firstMoveDetail);
                }
              },
              titleString: generalSettings.aiMovesFirst
                  ? S.of(context).ai
                  : S.of(context).human,
            ),
          ],
        ),
        SettingsCard(
          title: Text(S.of(context).difficulty),
          children: <Widget>[
            SettingsListTile(
              titleString: S.of(context).skillLevel,
              //trailingString: "L" + DB().generalSettings.skillLevel.toString(),
              onTap: () {
                if (EnvironmentConfig.test == false) {
                  _setSkillLevel(context);
                }
              },
            ),
            SettingsListTile(
              titleString: S.of(context).moveTime,
              onTap: () => _setMoveTime(context),
            ),
          ],
        ),
        SettingsCard(
          title: Text(S.of(context).aisPlayStyle),
          children: <Widget>[
            SettingsListTile(
              titleString: S.of(context).algorithm,
              trailingString: generalSettings.searchAlgorithm!.name,
              onTap: () => _setAlgorithm(context, generalSettings),
            ),
            SettingsListTile.switchTile(
              value: generalSettings.drawOnHumanExperience,
              onChanged: (bool val) {
                _setDrawOnHumanExperience(generalSettings, val);
                if (val == true) {
                  rootScaffoldMessengerKey.currentState!.showSnackBarClear(
                      S.of(context).drawOnTheHumanExperienceDetail);
                }
              },
              titleString: S.of(context).drawOnHumanExperience,
            ),
            SettingsListTile.switchTile(
              value: generalSettings.considerMobility,
              onChanged: (bool val) {
                _setConsiderMobility(generalSettings, val);
                rootScaffoldMessengerKey.currentState!.showSnackBarClear(
                    S.of(context).considerMobilityOfPiecesDetail);
              },
              titleString: S.of(context).considerMobility,
            ),
            SettingsListTile.switchTile(
              value: generalSettings.aiIsLazy,
              onChanged: (bool val) {
                _setAiIsLazy(generalSettings, val);
                if (val == true) {
                  rootScaffoldMessengerKey.currentState!
                      .showSnackBarClear(S.of(context).passiveDetail);
                }
              },
              titleString: S.of(context).passive,
            ),
            SettingsListTile.switchTile(
              value: generalSettings.shufflingEnabled,
              onChanged: (bool val) {
                _setShufflingEnabled(generalSettings, val);
                rootScaffoldMessengerKey.currentState!
                    .showSnackBarClear(S.of(context).moveRandomlyDetail);
              },
              titleString: S.of(context).shufflingEnabled,
            ),
          ],
        ),
        SettingsCard(
          title: Text(S.of(context).playSounds),
          children: <Widget>[
            SettingsListTile.switchTile(
              value: generalSettings.toneEnabled,
              onChanged: (bool val) => _setTone(generalSettings, val),
              titleString: S.of(context).playSoundsInTheGame,
            ),
            SettingsListTile.switchTile(
              value: generalSettings.keepMuteWhenTakingBack,
              onChanged: (bool val) =>
                  _setKeepMuteWhenTakingBack(generalSettings, val),
              titleString: S.of(context).keepMuteWhenTakingBack,
            ),
          ],
        ),
        if (!kIsWeb && Platform.isAndroid)
          SettingsCard(
            title: Text(S.of(context).accessibility),
            children: <Widget>[
              SettingsListTile.switchTile(
                value: generalSettings.screenReaderSupport,
                onChanged: (bool val) =>
                    _setScreenReaderSupport(generalSettings, val),
                titleString: S.of(context).screenReaderSupport,
              ),
            ],
          ),
        if (!kIsWeb && (Platform.isAndroid || Platform.isIOS))
          SettingsCard(
            title: Text(S.of(context).gameScreenRecorder),
            children: <Widget>[
              SettingsListTile.switchTile(
                value: generalSettings.gameScreenRecorderSupport,
                onChanged: (bool val) {
                  _setGameScreenRecorderSupport(generalSettings, val);
                  if (val == true) {
                    rootScaffoldMessengerKey.currentState!
                        .showSnackBarClear(S.of(context).experimental);
                  }
                },
                titleString: S.of(context).shareGIF,
              ),
              SettingsListTile(
                titleString: S.of(context).duration,
                trailingString:
                    generalSettings.gameScreenRecorderDuration.toString(),
                onTap: () =>
                    _setGameScreenRecorderDuration(context, generalSettings),
              ),
              SettingsListTile(
                titleString: S.of(context).pixelRatio,
                trailingString:
                    "${generalSettings.gameScreenRecorderPixelRatio}%",
                onTap: () =>
                    _setGameScreenRecorderPixelRatio(context, generalSettings),
              ),
            ],
          ),
        SettingsCard(
          title: Text(S.of(context).restore),
          children: <Widget>[
            SettingsListTile(
              titleString: S.of(context).restoreDefaultSettings,
              onTap: () => _restoreFactoryDefaultSettings(context),
            ),
          ],
        ),
        if (EnvironmentConfig.devMode || EnvironmentConfig.test)
          SettingsCard(
            title: Text(S.of(context).experiments),
            children: <Widget>[
              SettingsListTile.switchTile(
                value: generalSettings.isAutoRestart,
                onChanged: (bool val) =>
                    _setIsAutoRestart(generalSettings, val),
                titleString: S.of(context).isAutoRestart,
              ),
            ],
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlockSemantics(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: AppTheme.lightBackgroundColor,
        appBar: AppBar(
          leading: DrawerIcon.of(context)?.icon,
          title: Text(S.of(context).generalSettings),
        ),
        body: ValueListenableBuilder<Box<GeneralSettings>>(
          valueListenable: DB().listenGeneralSettings,
          builder: _buildGeneralSettingsList,
        ),
      ),
    );
  }
}
