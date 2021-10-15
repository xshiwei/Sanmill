/*
  This file is part of Sanmill.
  Copyright (C) 2019-2021 The Sanmill developers (see AUTHORS file)

  Sanmill is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  Sanmill is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

import 'package:flutter/widgets.dart';
import 'package:hive_flutter/adapters.dart'
    show HiveField, HiveType, BinaryReader, BinaryWriter, TypeAdapter;
import 'package:json_annotation/json_annotation.dart';
import 'package:sanmill/services/storage/adapters/color_adapter.dart';
import 'package:sanmill/shared/theme/app_theme.dart';

part 'color.g.dart';

/// Color data model
///
/// holds the data needed for the Color Settings
@HiveType(typeId: 0)
@JsonSerializable()
class ColorSettings {
  ColorSettings({
    Color? boardLineColor,
    Color? darkBackgroundColor,
    Color? boardBackgroundColor,
    Color? whitePieceColor,
    Color? blackPieceColor,
    Color? pieceHighlightColor,
    Color? messageColor,
    Color? drawerColor,
    Color? drawerBackgroundColor,
    Color? drawerTextColor,
    Color? drawerHighlightItemColor,
    Color? mainToolbarBackgroundColor,
    Color? mainToolbarIconColor,
    Color? navigationToolbarBackgroundColor,
    Color? navigationToolbarIconColor,
  }) {
    this.boardLineColor = boardLineColor ?? AppTheme.boardLineColor;
    this.darkBackgroundColor =
        darkBackgroundColor ?? AppTheme.darkBackgroundColor;
    this.boardBackgroundColor =
        boardBackgroundColor ?? AppTheme.boardBackgroundColor;
    this.whitePieceColor = whitePieceColor ?? AppTheme.whitePieceColor;
    this.blackPieceColor = blackPieceColor ?? AppTheme.blackPieceColor;
    this.pieceHighlightColor =
        pieceHighlightColor ?? AppTheme.pieceHighlightColor;
    this.messageColor = messageColor ?? AppTheme.messageColor;
    this.drawerColor = drawerColor ?? AppTheme.drawerColor;
    this.drawerBackgroundColor =
        drawerBackgroundColor ?? AppTheme.drawerBackgroundColor;
    this.drawerTextColor = drawerTextColor ?? AppTheme.drawerTextColor;
    this.drawerHighlightItemColor =
        drawerHighlightItemColor ?? AppTheme.drawerHighlightItemColor;
    this.mainToolbarBackgroundColor =
        mainToolbarBackgroundColor ?? AppTheme.mainToolbarBackgroundColor;
    this.mainToolbarIconColor =
        mainToolbarIconColor ?? AppTheme.mainToolbarBackgroundColor;
    this.navigationToolbarBackgroundColor = navigationToolbarBackgroundColor ??
        AppTheme.navigationToolbarBackgroundColor;
    this.navigationToolbarIconColor =
        navigationToolbarIconColor ?? AppTheme.navigationToolbarIconColor;
  }
  @JsonKey(
    fromJson: ColorAdapter.colorFromJson,
    toJson: ColorAdapter.colorToJson,
  )
  @HiveField(0)
  late Color boardLineColor;

  @JsonKey(
    fromJson: ColorAdapter.colorFromJson,
    toJson: ColorAdapter.colorToJson,
  )
  @HiveField(1)
  late Color darkBackgroundColor;

  @JsonKey(
    fromJson: ColorAdapter.colorFromJson,
    toJson: ColorAdapter.colorToJson,
  )
  @HiveField(2)
  late Color boardBackgroundColor;

  @JsonKey(
    fromJson: ColorAdapter.colorFromJson,
    toJson: ColorAdapter.colorToJson,
  )
  @HiveField(3)
  late Color whitePieceColor;

  @JsonKey(
    fromJson: ColorAdapter.colorFromJson,
    toJson: ColorAdapter.colorToJson,
  )
  @HiveField(4)
  late Color blackPieceColor;

  @JsonKey(
    fromJson: ColorAdapter.colorFromJson,
    toJson: ColorAdapter.colorToJson,
  )
  @HiveField(5)
  late Color pieceHighlightColor;

  @JsonKey(
    fromJson: ColorAdapter.colorFromJson,
    toJson: ColorAdapter.colorToJson,
  )
  @HiveField(6)
  late Color messageColor;

  @JsonKey(
    fromJson: ColorAdapter.colorFromJson,
    toJson: ColorAdapter.colorToJson,
  )
  @HiveField(7)
  late Color drawerColor;

  @JsonKey(
    fromJson: ColorAdapter.colorFromJson,
    toJson: ColorAdapter.colorToJson,
  )
  @HiveField(8)
  late Color drawerBackgroundColor;

  @JsonKey(
    fromJson: ColorAdapter.colorFromJson,
    toJson: ColorAdapter.colorToJson,
  )
  @HiveField(9)
  late Color drawerTextColor;

  @JsonKey(
    fromJson: ColorAdapter.colorFromJson,
    toJson: ColorAdapter.colorToJson,
  )
  @HiveField(10)
  late Color drawerHighlightItemColor;

  @JsonKey(
    fromJson: ColorAdapter.colorFromJson,
    toJson: ColorAdapter.colorToJson,
  )
  @HiveField(11)
  late Color mainToolbarBackgroundColor;

  @JsonKey(
    fromJson: ColorAdapter.colorFromJson,
    toJson: ColorAdapter.colorToJson,
  )
  @HiveField(12)
  late Color mainToolbarIconColor;

  @JsonKey(
    fromJson: ColorAdapter.colorFromJson,
    toJson: ColorAdapter.colorToJson,
  )
  @HiveField(13)
  late Color navigationToolbarBackgroundColor;

  @JsonKey(
    fromJson: ColorAdapter.colorFromJson,
    toJson: ColorAdapter.colorToJson,
  )
  @HiveField(14)
  late Color navigationToolbarIconColor;

  /// encodes a Json style map Coloro a [ColorSettings] obbject
  factory ColorSettings.fromJson(Map<String, dynamic> json) =>
      _$ColorSettingsFromJson(json);

  /// decodes a Json from a [ColorSettings] obbject
  Map<String, dynamic> toJson() => _$ColorSettingsToJson(this);
}
