﻿/*
  Sanmill, a mill game playing engine derived from NineChess 1.5
  Copyright (C) 2015-2018 liuweilhy (NineChess author)
  Copyright (C) 2019-2020 Calcitem <calcitem@outlook.com>

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

#include "tt.h"

#ifdef TRANSPOSITION_TABLE_ENABLE
static constexpr int TRANSPOSITION_TABLE_SIZE = 0x2000000; // 8-128M:102s, 4-64M:93s 2-32M:91s 1-16M: 冲突
HashMap<hash_t, TTEntry> TT(TRANSPOSITION_TABLE_SIZE);

#ifdef TRANSPOSITION_TABLE_FAKE_CLEAN
uint8_t transpositionTableAge;
#endif // TRANSPOSITION_TABLE_FAKE_CLEAN

value_t TranspositionTable::probe(const hash_t &key,
                      const depth_t &depth,
                      const value_t &alpha,
                      const value_t &beta,
                      bound_t &type
#ifdef TT_MOVE_ENABLE
                      , move_t &ttMove
#endif // TT_MOVE_ENABLE
                      )
{
    TTEntry tte {};

    if (!TT.find(key, tte)) {
        return VALUE_UNKNOWN;
    }

#ifdef TRANSPOSITION_TABLE_FAKE_CLEAN
#ifdef TRANSPOSITION_TABLE_FAKE_CLEAN_NOT_EXACT_ONLY
    if (tte.type != BOUND_EXACT) {
#endif
        if (tte.age != transpositionTableAge) {
            return VALUE_UNKNOWN;
        }
#ifdef TRANSPOSITION_TABLE_FAKE_CLEAN_NOT_EXACT_ONLY
    }
#endif
#endif // TRANSPOSITION_TABLE_FAKE_CLEAN

    if (depth > tte.depth) {
        goto out;
    }

    type = tte.type;

    switch (tte.type) {
    case BOUND_EXACT:
        return tte.value;
        break;
    case BOUND_UPPER:     // 最多是 tte.value
        if (tte.value <= alpha) {
            return alpha;   // TODO: https://github.com/calcitem/NineChess/issues/25
        }
        break;
    case BOUND_LOWER:     // 至少是 tte.value
        if (tte.value >= beta) {
            return beta;
        }
        break;
    default:
        break;
    }

out:

#ifdef TT_MOVE_ENABLE
    ttMove = tte.ttMove;
#endif // TT_MOVE_ENABLE

    return VALUE_UNKNOWN;
}

bool TranspositionTable::search(const hash_t &key, TTEntry &tte)
{
    return TT.find(key, tte);

    // TODO: 变换局面
#if 0
    if (iter != hashmap.end())
        return iter;

    // 变换局面，查找 key (废弃)
    tempStateShift = st;
    for (int i = 0; i < 2; i++) {
        if (i)
            tempStateShift.mirror(false);

        for (int j = 0; j < 2; j++) {
            if (j)
                tempStateShift.turn(false);
            for (int k = 0; k < 4; k++) {
                tempStateShift.rotate(k * 90, false);
                iter = hashmap.find(tempStateShift.getHash());
                if (iter != hashmap.end())
                    return iter;
            }
        }
    }
#endif
}

void TranspositionTable::prefetch(const hash_t &key)
{
    TT.prefetchValue(key);
}

int TranspositionTable::save(const value_t &value,
                   const depth_t &depth,
                   const bound_t &type,
                   const hash_t &key
#ifdef TT_MOVE_ENABLE
                   , const move_t &ttMove
#endif // TT_MOVE_ENABLE
                  )
{
    // 同样深度或更深时替换
    // 注意: 每走一步以前都必须把散列表中所有的标志项置为 BOUND_NONE

    //hashMapMutex.lock();
    TTEntry tte {};

    if (search(key, tte)) {
#ifdef TRANSPOSITION_TABLE_FAKE_CLEAN
        if (tte.age == transpositionTableAge) {
#endif // TRANSPOSITION_TABLE_FAKE_CLEAN
            if (tte.type != BOUND_NONE &&
                tte.depth > depth) {
                return -1;
            }
#ifdef TRANSPOSITION_TABLE_FAKE_CLEAN
        }
#endif // TRANSPOSITION_TABLE_FAKE_CLEAN
    }

    tte.value = value;
    tte.depth = depth;
    tte.type = type;

#ifdef TT_MOVE_ENABLE
    tte.ttMove = ttMove;
#endif // TT_MOVE_ENABLE

#ifdef TRANSPOSITION_TABLE_FAKE_CLEAN
    tte.age = transpositionTableAge;
#endif // TRANSPOSITION_TABLE_FAKE_CLEAN

    TT.insert(key, tte);

    //hashMapMutex.unlock();

    return 0;
}

void TranspositionTable::clear()
{
#ifdef TRANSPOSITION_TABLE_FAKE_CLEAN
    if (transpositionTableAge == std::numeric_limits<uint8_t>::max())
    {
        loggerDebug("Clean TT\n");
        TT.clear();
        transpositionTableAge = 0;
    } else {
        transpositionTableAge++;
    }
#else
    TT.clear();
#endif // TRANSPOSITION_TABLE_FAKE_CLEAN
}

#endif /* TRANSPOSITION_TABLE_ENABLE */
