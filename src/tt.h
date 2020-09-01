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

#ifndef TT_H_INCLUDED
#define TT_H_INCLUDED

#include "hashmap.h"
#include "types.h"

using namespace CTSL;

#ifdef TRANSPOSITION_TABLE_ENABLE

/// TTEntry struct is the 4 bytes transposition table entry, defined as below:
///
/// value       8 bit
/// depth       8 bit
/// type        8 bit
/// age         8 bit

struct TTEntry
{
    Value value() const
    {
        return (Value)value8;
    }

    Depth depth() const
    {
        return (Depth)depth8 + DEPTH_OFFSET;
    }

    Bound bound() const
    {
        return (Bound)(genBound8);
    }

private:
    friend class TranspositionTable;

    int8_t  value8;
    int8_t  depth8;
    uint8_t genBound8;
#ifdef TRANSPOSITION_TABLE_FAKE_CLEAN
    uint8_t age8;
#endif // TRANSPOSITION_TABLE_FAKE_CLEAN
#ifdef TT_MOVE_ENABLE
    Move ttMove;
#endif // TT_MOVE_ENABLE
};


class TranspositionTable
{
public:
    static bool search(const Key &key, TTEntry &tte);
    static Value probe(const Key &key,
                            const Depth &depth,
                            const Value &alpha,
                            const Value &beta,
                            Bound &type
    #ifdef TT_MOVE_ENABLE
                            , Move &ttMove
    #endif // TT_MOVE_ENABLE
                            );

    static int save(const Value &value,
                          const Depth &depth,
                          const Bound &type,
                          const Key &key
#ifdef TT_MOVE_ENABLE
                          , const Move &ttMove
#endif // TT_MOVE_ENABLE
                         );

    static void clear();

    static void prefetch(const Key &key);

private:
    friend struct TTEntry;
};

extern HashMap<Key, TTEntry> TT;

#ifdef TRANSPOSITION_TABLE_FAKE_CLEAN
extern uint8_t transpositionTableAge;
#endif // TRANSPOSITION_TABLE_FAKE_CLEAN

#endif  // TRANSPOSITION_TABLE_ENABLE

#endif // #ifndef TT_H_INCLUDED
