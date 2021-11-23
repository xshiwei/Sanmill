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

part of 'package:sanmill/screens/rule_settings/rule_settings_page.dart';

class _FlyPieceCountModal extends StatelessWidget {
  const _FlyPieceCountModal({
    Key? key,
    required this.flyPieceCount,
    required this.onChanged,
  }) : super(key: key);

  final int flyPieceCount;
  final Function(int?)? onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: S.of(context).flyPieceCount,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          RadioListTile(
            title: const Text('3'),
            groupValue: flyPieceCount,
            value: 3,
            onChanged: onChanged,
          ),
          RadioListTile(
            title: const Text('4'),
            groupValue: flyPieceCount,
            value: 4,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
