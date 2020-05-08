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

#ifndef POSITION_H
#define POSITION_H

#include <string>
#include <cstring>

#include "config.h"
#include "types.h"
#include "rule.h"
#include "board.h"
#include "search.h"

using namespace std;

class AIAlgorithm;
class StateInfo;
class Node;

extern string tips;

// 棋局结构体，算法相关，包含当前棋盘数据
// 单独分离出来供AI判断局面用，生成置换表时使用
class Position
{
public:
    Position();
    virtual ~Position();

    // 拷贝构造函数
    Position(Position &);
    Position(const Position &);

    // 运算符重载
    Position &operator=(const Position &);
    Position &operator=(Position &);

    Board board;

    // 局面的哈希值
    hash_t hash {0};

    // 局面阶段标识
    enum phase_t phase {PHASE_NONE};

    // 轮流状态标识
    player_t sideToMove {PLAYER_NOBODY};
    int sideId {0};
    char chSide {'0'};
    //string turnStr;
    player_t opponent {PLAYER_NOBODY};
    int opponentId {0};
    char chOpponent {'0'};
    //string opponentStr;

    // 动作状态标识
    enum action_t action
    {
    };

    // 玩家剩余未放置子数
    int nPiecesInHand[COLOR_COUNT]{0};

    // 玩家盘面剩余子数, [0] 为两个玩家之和
    int nPiecesOnBoard[COLOR_COUNT] {0};

    // 尚待去除的子数
    int nPiecesNeedRemove {0};

    //////////////////////////////////////

    // 设置棋局状态和棋局，用于初始化
    bool setPosition(const struct Rule *rule,
                     step_t initialStep = 0,           // 默认起始步数为0
                     phase_t phase = PHASE_READY, player_t turn = PLAYER_BLACK, action_t action = ACTION_PLACE,
                     const char *locations = nullptr,   // 默认空棋盘
                     int nPiecesNeedRemove = 0      // 尚待去除的子数
    );

    // 获取棋盘数据
    location_t *getBoardLocations() const
    {
        return (location_t *)board.locations;
    }

    // 获取当前棋子位置点
    square_t getCurrentSquare() const
    {
        return currentSquare;
    }

    // 获取当前步数
    int getStep() const
    {
        return currentStep;
    }

    // 获取从上次吃子开始经历的移动步数
    int getMoveStep() const
    {
        return moveStep;
    }

    // 获取局面阶段标识
    enum phase_t getPhase() const
    {
        return phase;
    }

    // 获取动作状态标识
    enum action_t getAction() const
    {
        return action;
    }

    // 玩家1或玩家2的用时
    time_t getElapsedTime(int playerId);

    // 获取棋局的字符提示
    const string getTips() const
    {
        return tips;
    }

    // 获取当前着法
    const char *getCmdLine() const
    {
        return cmdline;
    }

    // 获得棋谱
    const vector<string> *getCmdList() const
    {
        return &cmdlist;
    }

    // 获取开局时间
    time_t getStartTimeb() const
    {
        return startTime;
    }

    // 重新设置开局时间
    void setStartTime(int stimeb)
    {
        startTime = stimeb;
    }

    // 玩家剩余未放置子数
    int getPiecesInHandCount(int playerId) const
    {
        return nPiecesInHand[playerId];
    }

    // 玩家盘面剩余子数
    int getPiecesOnBoardCount(int playerId) const
    {
        return nPiecesOnBoard[playerId];
    }

    // 尚待去除的子数
    int getNum_NeedRemove() const
    {
        return nPiecesNeedRemove;
    }

    // 计算玩家1和玩家2的棋子活动能力之差
    int getMobilityDiff(player_t turn, int nPiecesOnBoard[], bool includeFobidden);

    // 游戏重置
    bool reset();

    // 游戏开始
    bool start();

    // 选子，在第r圈第s个位置，为迎合日常，r和s下标都从1开始
    bool choose(int r, int s);

    // 落子，在第r圈第s个位置，为迎合日常，r和s下标都从1开始
    bool _place(int r, int s);

    // 去子，在第r圈第s个位置，为迎合日常，r和s下标都从1开始
    bool _capture(int r, int s);

    // 认输
    bool giveup(player_t loser);

    // 命令行解析函数
    bool command(const char *cmd);

    // 更新时间和状态，用内联函数以提高效率
    int update();

    // 是否分出胜负
    bool checkGameOverCondition(int8_t cp = 0);

    // 清除所有禁点
    void cleanForbiddenLocations();

    // 设置轮流
    void setSideToMove(player_t player);

    // 获取轮流
    player_t getSideToMove();

    // 改变轮流
    void changeSideToMove();

    // 设置提示
    void setTips();

    // 着法生成
    int generateMoves(Stack<move_t, MAX_MOVES> &moves);
    int generateNullMove(Stack<move_t, MAX_MOVES> &moves);

    bool doNullMove();
    bool undoNullMove();

    // 判断胜负
    player_t getWinner() const;

    // 下面几个函数没有算法无关判断和无关操作，节约算法时间
    bool doMove(move_t move);
    bool choose(square_t square);
    bool place(square_t square, int8_t cp = 0);
    bool capture(square_t square, int8_t cp = 0);

    // hash 相关
    hash_t getPosKey();
    hash_t revertHash(square_t square);
    hash_t updateHash(square_t square);
    hash_t updateHashMisc();
    hash_t getNextMainHash(move_t m);

    // 赢盘数
    int score[COLOR_COUNT] = { 0 };
    int score_draw { 0 };
    int nPlayed { 0 };

    int tm { -1 };

    // 棋谱
    vector <string> cmdlist;

    // 着法命令行用于棋谱的显示和解析, 当前着法的命令行指令，即一招棋谱
    char cmdline[64]{ '\0' };

    /*
        当前着法，AI会用到，如下表示
        0x   00    00
            square1  square2
        开局落子：0x00??，??为棋盘上的位置
        移子：0x__??，__为移动前的位置，??为移动后的位置
        去子：0xFF??，??取位置补码，即为负数

        31 ----- 24 ----- 25
        | \       |      / |
        |  23 -- 16 -- 17  |
        |  | \    |   / |  |
        |  |  15 08 09  |  |
        30-22-14    10-18-26
        |  |  13 12 11  |  |
        |  | /    |   \ |  |
        |  21 -- 20 -- 19  |
        | /       |     \  |
        29 ----- 28 ----- 27
    */
    move_t move { MOVE_NONE };

    // 选中的棋子在board中的位置
    square_t currentSquare{};

private:

    // 创建哈希值
    void constructHash();

    // 计算双方在棋盘上各有几个子
    int countPiecesOnBoard();

    // 计算双方手中各有几个字
    int countPiecesInHand();

    // 胜负标识
    player_t winner;

    // 当前步数
    step_t currentStep{};

    // 从走子阶段开始或上次吃子起的步数
    int moveStep{};

    // 游戏起始时间
    time_t startTime{};

    // 当前游戏时间
    time_t currentTime{};

    // 玩家用时（秒）
    time_t elapsedSeconds[COLOR_COUNT];
};

// 棋类（在数据模型内，玩家只分先后手，不分黑白）
// 注意：StateInfo 类不是线程安全的！
// 所以不能跨线程修改 StateInfo 类的静态成员变量，切记！
class StateInfo
{
    // AI友元类
    friend class AIAlgorithm;

public:

    StateInfo();
    virtual ~StateInfo();

    // 拷贝构造函数
    StateInfo(StateInfo &);
    StateInfo(const StateInfo &);

    // 运算符重载
    StateInfo &operator=(const StateInfo &);
    StateInfo &operator=(StateInfo &);

    Position *position { nullptr };
};

#endif /* POSITION_H */
