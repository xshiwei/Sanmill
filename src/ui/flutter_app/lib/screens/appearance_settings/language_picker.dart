/*
  This file is part of Sanmill.
  Copyright (C) 2019-2023 The Sanmill developers (see AUTHORS file)

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

part of 'package:sanmill/screens/appearance_settings/appearance_settings_page.dart';

class _LanguagePicker extends StatelessWidget {
  const _LanguagePicker({
    required this.currentLocale,
    required this.onChanged,
  });

  final Locale? currentLocale;
  final Function(Locale?) onChanged;

  @override
  Widget build(BuildContext context) {
    final Column languageColumn = Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        RadioListTile<Locale?>(
          title: Text(
            S.of(context).defaultLanguage,
            textScaleFactor: DB().displaySettings.fontScale,
          ),
          groupValue: currentLocale,
          value: null,
          onChanged: onChanged,
        ),
        const Divider(),
        for (Locale i in localeToLanguageName.keys)
          RadioListTile<Locale>(
            title: Text(
              localeToLanguageName[i]!,
              textScaleFactor: DB().displaySettings.fontScale,
            ),
            groupValue: currentLocale,
            value: i,
            onChanged: onChanged,
          ),
      ],
    );

    return AlertDialog(
      scrollable: true,
      content: languageColumn,
    );
  }
}
