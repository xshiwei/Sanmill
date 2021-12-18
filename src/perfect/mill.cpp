/*********************************************************************
    Mill.cpp
    Copyright (c) Thomas Weber. All rights reserved.
    Copyright (C) 2021 The Sanmill developers (see AUTHORS file)
    Licensed under the GPLv3 License.
    https://github.com/madweasel/Muehle
\*********************************************************************/

#include "config.h"

#ifdef MADWEASEL_MUEHLE_PERFECT_AI

#include "mill.h"
#include <cassert>

//-----------------------------------------------------------------------------
// Mill()
// Mill class constructor
//-----------------------------------------------------------------------------
Mill::Mill()
{
    srand((unsigned)time(nullptr));

    moveLogFrom = nullptr;
    moveLogTo = nullptr;
    playerOneAI = nullptr;
    playerTwoAI = nullptr;
    movesDone = 0;

    winner = 0;
    beginningPlayer = 0;

    field.createBoard();
    initField.createBoard();
}

//-----------------------------------------------------------------------------
// ~Mill()
// Mill class destructor
//-----------------------------------------------------------------------------
Mill::~Mill()
{
    exit();
}

//-----------------------------------------------------------------------------
// deleteArrays()
// Deletes all arrays the Mill class has created.
//-----------------------------------------------------------------------------
void Mill::exit()
{
    SAFE_DELETE_ARRAY(moveLogFrom);
    SAFE_DELETE_ARRAY(moveLogTo);

    field.deleteBoard();
    initField.deleteBoard();
}

//-----------------------------------------------------------------------------
// resetGame()
// Reset the Mill object.
//-----------------------------------------------------------------------------
void Mill::resetGame()
{
    std::memset(moveLogFrom, 0, MOVE_COUNT_MAX);
    std::memset(moveLogTo, 0, MOVE_COUNT_MAX);
    initField.copyBoard(&field);

    winner = 0;
    movesDone = 0;
}

//-----------------------------------------------------------------------------
// beginNewGame()
// Reinitializes the Mill object.
//-----------------------------------------------------------------------------
void Mill::beginNewGame(MillAI *firstPlayerAI, MillAI *secondPlayerAI,
                        int curPlayer)
{
    // free memory
    exit();

    // create arrays
    field.createBoard();
    initField.createBoard();

    // calculate beginning player
    if (curPlayer == field.playerOne || curPlayer == field.playerTwo) {
        beginningPlayer = curPlayer;
    } else {
        beginningPlayer = (rand() % 2) ? field.playerOne : field.playerTwo;
    }

    field.curPlayer->id = beginningPlayer;
    field.oppPlayer->id = (field.curPlayer->id == field.playerTwo) ?
                              field.playerOne :
                              field.playerTwo;

    winner = 0;
    movesDone = 0;
    playerOneAI = firstPlayerAI;
    playerTwoAI = secondPlayerAI;
    moveLogFrom = new uint32_t[MOVE_COUNT_MAX];
    moveLogTo = new uint32_t[MOVE_COUNT_MAX];

    // remember initField
    field.copyBoard(&initField);
}

//-----------------------------------------------------------------------------
// startPlacingPhase()
//
//-----------------------------------------------------------------------------
bool Mill::startPlacingPhase(MillAI *firstPlayerAI, MillAI *secondPlayerAI,
                             int curPlayer, bool isPlacingPhase)
{
    beginNewGame(firstPlayerAI, secondPlayerAI, curPlayer);

    field.isPlacingPhase = isPlacingPhase;

    return true;
}

//-----------------------------------------------------------------------------
// setUpCalcPossibleMoves()
// Calculates and set the number of possible moves for the passed player
// considering the game state stored in the 'board' variable.
//-----------------------------------------------------------------------------
void Mill::setUpCalcPossibleMoves(Player *player)
{
    // locals
    uint32_t i, j, k, movingDirection;

    for (player->possibleMovesCount = 0, i = 0; i < SQUARE_NB; i++) {
        for (j = 0; j < SQUARE_NB; j++) {
            // is piece from player ?
            if (field.board[i] != player->id)
                continue;

            // is dest free ?
            if (field.board[j] != field.squareIsFree)
                continue;

            // when current player has only 3 pieces he is allowed to spring his
            // piece
            if (player->pieceCount > 3 || field.isPlacingPhase) {
                // determine moving direction
                for (k = 0, movingDirection = 4; k < 4; k++)
                    if (field.connectedSquare[i][k] == j)
                        movingDirection = k;

                // are both squares connected ?
                if (movingDirection == 4)
                    continue;
            }

            // everything is ok
            player->possibleMovesCount++;
        }
    }
}

//-----------------------------------------------------------------------------
// setUpSetWarningAndMill()
//
//-----------------------------------------------------------------------------
void Mill::setUpSetWarningAndMill(uint32_t piece, uint32_t firstNeighbor,
                                  uint32_t secondNeighbor)
{
    // locals
    int rowOwner = field.board[piece];

    // mill closed ?
    if (rowOwner != field.squareIsFree &&
        field.board[firstNeighbor] == rowOwner &&
        field.board[secondNeighbor] == rowOwner) {
        field.piecePartOfMillCount[piece]++;
        field.piecePartOfMillCount[firstNeighbor]++;
        field.piecePartOfMillCount[secondNeighbor]++;
    }
}

//-----------------------------------------------------------------------------
// putPiece()
// Put a piece onto the board during the placing phase.
//-----------------------------------------------------------------------------
bool Mill::putPiece(uint32_t pos, int player)
{
    // locals
    uint32_t i;
    uint32_t nCurPlayerMills = 0, nOpponentPlayerMills = 0;
    Player *myPlayer = (player == field.curPlayer->id) ? field.curPlayer :
                                                         field.oppPlayer;

    // check params
    if (player != fieldStruct::playerOne && player != fieldStruct::playerTwo)
        return false;
    if (pos >= SQUARE_NB)
        return false;
    if (field.board[pos] != field.squareIsFree)
        return false;

    // set piece
    field.board[pos] = player;
    myPlayer->pieceCount++;
    field.piecePlacedCount++;

    // placing phase finished ?
    if (field.piecePlacedCount == 18)
        field.isPlacingPhase = false;

    // calculate possible moves
    setUpCalcPossibleMoves(field.curPlayer);
    setUpCalcPossibleMoves(field.oppPlayer);

    // zero
    for (i = 0; i < SQUARE_NB; i++)
        field.piecePartOfMillCount[i] = 0;

    // go in every direction
    for (i = 0; i < SQUARE_NB; i++) {
        setUpSetWarningAndMill(i, field.neighbor[i][0][0],
                               field.neighbor[i][0][1]);
        setUpSetWarningAndMill(i, field.neighbor[i][1][0],
                               field.neighbor[i][1][1]);
    }

    // since every mill was detected 3 times
    for (i = 0; i < SQUARE_NB; i++)
        field.piecePartOfMillCount[i] /= 3;

    // count completed mills
    for (i = 0; i < SQUARE_NB; i++) {
        if (field.board[i] == field.curPlayer->id)
            nCurPlayerMills += field.piecePartOfMillCount[i];
        else
            nOpponentPlayerMills += field.piecePartOfMillCount[i];
    }
    nCurPlayerMills /= 3;
    nOpponentPlayerMills /= 3;

    // piecePlacedCount & removedPiecesCount
    if (field.isPlacingPhase) {
        // ... This calculation is not correct! It is possible that some mills
        // did not cause a piece removal.
        field.curPlayer->removedPiecesCount = nOpponentPlayerMills;
        field.oppPlayer->removedPiecesCount = nCurPlayerMills -
                                              field.pieceMustBeRemovedCount;
        field.piecePlacedCount = field.curPlayer->pieceCount +
                                 field.oppPlayer->pieceCount +
                                 field.curPlayer->removedPiecesCount +
                                 field.oppPlayer->removedPiecesCount;
    } else {
        field.piecePlacedCount = 18;
        field.curPlayer->removedPiecesCount = 9 - field.curPlayer->pieceCount;
        field.oppPlayer->removedPiecesCount = 9 - field.oppPlayer->pieceCount;
    }

    // when opponent is unable to move than current player has won
    if ((!field.curPlayer->possibleMovesCount) && (!field.isPlacingPhase) &&
        (!field.pieceMustBeRemovedCount) && (field.curPlayer->pieceCount > 3))
        winner = field.oppPlayer->id;
    else if ((field.curPlayer->pieceCount < 3) && (!field.isPlacingPhase))
        winner = field.oppPlayer->id;
    else if ((field.oppPlayer->pieceCount < 3) && (!field.isPlacingPhase))
        winner = field.curPlayer->id;
    else
        winner = 0;

    // everything is ok
    return true;
}

//-----------------------------------------------------------------------------
// placingPhaseHasFinished()
// This function has to be called when the placing phase has finished.
//-----------------------------------------------------------------------------
bool Mill::placingPhaseHasFinished()
{
    // remember initField
    field.copyBoard(&initField);

    return true;
}

//-----------------------------------------------------------------------------
// getField()
// Copy the current board state into the array 'pField'.
//-----------------------------------------------------------------------------
bool Mill::getField(int *pField)
{
    uint32_t i;

    // if no log is available than no game is in progress and board is invalid
    if (moveLogFrom == nullptr)
        return false;

    for (i = 0; i < SQUARE_NB; i++) {
        if (field.warnings[i] != field.noWarning)
            pField[i] = (int)field.warnings[i];
        else
            pField[i] = field.board[i];
    }

    return true;
}

//-----------------------------------------------------------------------------
// getLog()
// Copy the whole history of moves into the passed arrays, which must be of size
// [MOVE_COUNT_MAX].
//-----------------------------------------------------------------------------
void Mill::getLog(uint32_t &nMovesDone, uint32_t *from, uint32_t *to)
{
    uint32_t i;

    nMovesDone = movesDone;

    for (i = 0; i < movesDone; i++) {
        from[i] = moveLogFrom[i];
        to[i] = moveLogTo[i];
    }
}

//-----------------------------------------------------------------------------
// setNextPlayer()
// Current player and opponent player are switched in the board struct.
//-----------------------------------------------------------------------------
void Mill::setNextPlayer()
{
    Player *tmpPlayer;

    tmpPlayer = field.curPlayer;
    field.curPlayer = field.oppPlayer;
    field.oppPlayer = tmpPlayer;
}

//-----------------------------------------------------------------------------
// isCurPlayerHuman()
// Returns true if the current player is not assigned to an AI.
//-----------------------------------------------------------------------------
bool Mill::isCurPlayerHuman()
{
    if (field.curPlayer->id == field.playerOne)
        return (playerOneAI == nullptr) ? true : false;
    else
        return (playerTwoAI == nullptr) ? true : false;
}

//-----------------------------------------------------------------------------
// isOpponentPlayerHuman()
// Returns true if the opponent player is not assigned to an AI.
//-----------------------------------------------------------------------------
bool Mill::isOpponentPlayerHuman()
{
    if (field.oppPlayer->id == field.playerOne)
        return (playerOneAI == nullptr) ? true : false;
    else
        return (playerTwoAI == nullptr) ? true : false;
}

//-----------------------------------------------------------------------------
// setAI()
// Assigns an AI to a player.
//-----------------------------------------------------------------------------
void Mill::setAI(int player, MillAI *AI)
{
    if (player == field.playerOne) {
        playerOneAI = AI;
    }
    if (player == field.playerTwo) {
        playerTwoAI = AI;
    }
}

//-----------------------------------------------------------------------------
// getChoiceOfSpecialAI()
// Returns the move the passed AI would do.
//-----------------------------------------------------------------------------
void Mill::getChoiceOfSpecialAI(MillAI *AI, uint32_t *pushFrom,
                                uint32_t *pushTo)
{
    fieldStruct theField;
    *pushFrom = SQUARE_NB;
    *pushTo = SQUARE_NB;
    theField.createBoard();
    field.copyBoard(&theField);
    if (AI != nullptr &&
        (field.isPlacingPhase || field.curPlayer->possibleMovesCount > 0) &&
        winner == 0)
        AI->play(&theField, pushFrom, pushTo);
    theField.deleteBoard();
}

//-----------------------------------------------------------------------------
// getComputersChoice()
// Returns the move the AI of the current player would do.
//-----------------------------------------------------------------------------
void Mill::getComputersChoice(uint32_t *pushFrom, uint32_t *pushTo)
{
    fieldStruct theField;
    *pushFrom = SQUARE_NB;
    *pushTo = SQUARE_NB;
    theField.createBoard();
    // assert(theField.oppPlayer->id >= -1 && theField.oppPlayer->id <= 1);

    field.copyBoard(&theField);

    // assert(theField.oppPlayer->id >= -1 && theField.oppPlayer->id <= 1);

    if ((field.isPlacingPhase || field.curPlayer->possibleMovesCount > 0) &&
        winner == 0) {
        if (field.curPlayer->id == field.playerOne) {
            if (playerOneAI != nullptr)
                playerOneAI->play(&theField, pushFrom, pushTo);
            // assert(theField.oppPlayer->id >= -1 && theField.oppPlayer->id
            // <=1);
        } else {
            if (playerTwoAI != nullptr)
                playerTwoAI->play(&theField, pushFrom, pushTo);
            // assert(theField.oppPlayer->id >= -1 && theField.oppPlayer->id <=
            // 1);
        }
    }

    if (*pushFrom == 24 && *pushTo == 24) {
        assert(false);
    }

    theField.deleteBoard();
}

//-----------------------------------------------------------------------------
// isNormalMovePossible()
// 'Normal' in this context means, by moving the piece along a connection
// without jumping.
//-----------------------------------------------------------------------------
bool Mill::isNormalMovePossible(uint32_t from, uint32_t to, Player *player)
{
    // locals
    uint32_t movingDirection, i;

    // param ok ?
    if (from >= SQUARE_NB)
        return false;
    if (to >= SQUARE_NB)
        return false;

    // is piece from player ?
    if (field.board[from] != player->id)
        return false;

    // is dest free ?
    if (field.board[to] != field.squareIsFree)
        return false;

    // when current player has only 3 pieces he is allowed to spring his piece
    if (player->pieceCount > 3 || field.isPlacingPhase) {
        // determine moving direction
        for (i = 0, movingDirection = 4; i < 4; i++)
            if (field.connectedSquare[from][i] == to)
                movingDirection = i;

        // are both squares connected ?
        if (movingDirection == 4)
            return false;
    }

    // everything is ok
    return true;
}

//-----------------------------------------------------------------------------
// generateMoves()
// ...
//-----------------------------------------------------------------------------
void Mill::generateMoves(Player *player)
{
    // locals
    uint32_t i;
    Square from, to;
    MoveDirection md;

    // zero
    for (i = 0; i < POSIBILE_MOVE_COUNT_MAX; i++) {
        player->posTo[i] = SQUARE_NB;
    }

    for (i = 0; i < POSIBILE_MOVE_COUNT_MAX; i++) {
        player->posFrom[i] = SQUARE_NB;
    }

    // calculate
    for (player->possibleMovesCount = 0, from = SQ_0; from < SQUARE_NB;
         ++from) {
        for (to = SQ_0; to < SQUARE_NB; ++to) {
            if (isNormalMovePossible(from, to, player)) {
                player->posFrom[player->possibleMovesCount] = from;
                player->posTo[player->possibleMovesCount] = to;
                player->possibleMovesCount++;
            }
        }
    }

    // isPieceMovable
    for (from = SQ_0; from < SQUARE_NB; ++from) {
        for (md = MD_BEGIN; md < MD_NB; ++md) {
            if (field.board[from] == player->id) {
                field.isPieceMovable[from][md] = isNormalMovePossible(
                    from, field.connectedSquare[from][md], player);
            } else {
                field.isPieceMovable[from][md] = false;
            }
        }
    }
}

//-----------------------------------------------------------------------------
// setWarningAndMill()
//
//-----------------------------------------------------------------------------
void Mill::setWarningAndMill(uint32_t piece, uint32_t firstNeighbor,
                             uint32_t secondNeighbor, bool isNewPiece)
{
    // locals
    int rowOwner = field.board[piece];
    uint32_t rowOwnerWarning = (rowOwner == field.playerOne) ?
                                   field.playerOneWarning :
                                   field.playerTwoWarning;

    // mill closed ?
    if (rowOwner != field.squareIsFree &&
        field.board[firstNeighbor] == rowOwner &&
        field.board[secondNeighbor] == rowOwner) {
        field.piecePartOfMillCount[piece]++;
        field.piecePartOfMillCount[firstNeighbor]++;
        field.piecePartOfMillCount[secondNeighbor]++;
        if (isNewPiece)
            field.pieceMustBeRemovedCount = 1;
    }

    // warning ?
    if (rowOwner != field.squareIsFree &&
        field.board[firstNeighbor] == field.squareIsFree &&
        field.board[secondNeighbor] == rowOwner)
        field.warnings[firstNeighbor] |= rowOwnerWarning;

    if (rowOwner != field.squareIsFree &&
        field.board[secondNeighbor] == field.squareIsFree &&
        field.board[firstNeighbor] == rowOwner)
        field.warnings[secondNeighbor] |= rowOwnerWarning;
}

//-----------------------------------------------------------------------------
// updateMillsAndWarnings()
//
//-----------------------------------------------------------------------------
void Mill::updateMillsAndWarnings(uint32_t newPiece)
{
    // locals
    uint32_t i;
    bool atLeastOnePieceRemoveAble;

    // zero
    for (i = 0; i < SQUARE_NB; i++)
        field.piecePartOfMillCount[i] = 0;

    for (i = 0; i < SQUARE_NB; i++)
        field.warnings[i] = field.noWarning;

    field.pieceMustBeRemovedCount = 0;

    // go in every direction
    for (i = 0; i < SQUARE_NB; i++) {
        setWarningAndMill(i, field.neighbor[i][0][0], field.neighbor[i][0][1],
                          i == newPiece);
        setWarningAndMill(i, field.neighbor[i][1][0], field.neighbor[i][1][1],
                          i == newPiece);
    }

    // since every mill was detected 3 times
    for (i = 0; i < SQUARE_NB; i++)
        field.piecePartOfMillCount[i] /= 3;

    // no piece must be removed if each belongs to a mill
    for (atLeastOnePieceRemoveAble = false, i = 0; i < SQUARE_NB; i++)
        if (field.piecePartOfMillCount[i] == 0 &&
            field.board[i] == field.oppPlayer->id)
            atLeastOnePieceRemoveAble = true;
    if (!atLeastOnePieceRemoveAble)
        field.pieceMustBeRemovedCount = 0;
}

//-----------------------------------------------------------------------------
// doMove()
//
//-----------------------------------------------------------------------------
bool Mill::doMove(uint32_t pushFrom, uint32_t pushTo)
{
    // avoid index override
    if (movesDone >= MOVE_COUNT_MAX)
        return false;

    // is game still running ?
    if (winner)
        return false;

    // handle the remove of a piece
    if (field.pieceMustBeRemovedCount) {
        // param ok ?
        if (pushFrom >= SQUARE_NB)
            return false;

        // is it piece from the opponent ?
        if (field.board[pushFrom] != field.oppPlayer->id)
            return false;

        // is piece not part of mill?
        if (field.piecePartOfMillCount[pushFrom])
            return false;

        // remove piece
        moveLogFrom[movesDone] = pushFrom;
        moveLogTo[movesDone] = SQUARE_NB;
        field.board[pushFrom] = field.squareIsFree;
        field.oppPlayer->removedPiecesCount++;
        field.oppPlayer->pieceCount--;
        field.pieceMustBeRemovedCount--;
        movesDone++;

        // is the game finished ?
        if ((field.oppPlayer->pieceCount < 3) && (!field.isPlacingPhase))
            winner = field.curPlayer->id;

        // update warnings & mills
        updateMillsAndWarnings(SQUARE_NB);

        // calculate possibilities
        generateMoves(field.curPlayer);
        generateMoves(field.oppPlayer);

        // is opponent unable to move ?
        if (field.oppPlayer->possibleMovesCount == 0 && !field.isPlacingPhase)
            winner = field.curPlayer->id;

        // next player
        if (!field.pieceMustBeRemovedCount)
            setNextPlayer();

        // everything is ok
        return true;

        // handle placing phase
    } else if (field.isPlacingPhase) {
        // param ok ?
        if (pushTo >= SQUARE_NB)
            return false;

        // is dest free ?
        if (field.board[pushTo] != field.squareIsFree)
            return false;

        // set piece
        moveLogFrom[movesDone] = SQUARE_NB;
        moveLogTo[movesDone] = pushTo;
        field.board[pushTo] = field.curPlayer->id;
        field.curPlayer->pieceCount++;
        field.piecePlacedCount++;
        movesDone++;

        // update warnings & mills
        updateMillsAndWarnings(pushTo);

        // calculate possibilities
        generateMoves(field.curPlayer);
        generateMoves(field.oppPlayer);

        // placing phase finished ?
        if (field.piecePlacedCount == 18)
            field.isPlacingPhase = false;

        // is opponent unable to move ?
        if (field.oppPlayer->possibleMovesCount == 0 && !field.isPlacingPhase)
            winner = field.curPlayer->id;

        // next player
        if (!field.pieceMustBeRemovedCount)
            setNextPlayer();

        // everything is ok
        return true;

        // normal move
    } else {
        // is move possible ?
        if (!isNormalMovePossible(pushFrom, pushTo, field.curPlayer))
            return false;

        // move piece
        moveLogFrom[movesDone] = pushFrom;
        moveLogTo[movesDone] = pushTo;
        field.board[pushFrom] = field.squareIsFree;
        field.board[pushTo] = field.curPlayer->id;
        movesDone++;

        // update warnings & mills
        updateMillsAndWarnings(pushTo);

        // calculate possibilities
        generateMoves(field.curPlayer);
        generateMoves(field.oppPlayer);

        // is opponent unable to move ?
        if (field.oppPlayer->possibleMovesCount == 0 && !field.isPlacingPhase)
            winner = field.curPlayer->id;

        // next player
        if (!field.pieceMustBeRemovedCount)
            setNextPlayer();

        // everything is ok
        return true;
    }
}

//-----------------------------------------------------------------------------
// setCurGameState()
// Set an arbitrary game state as the current one.
//-----------------------------------------------------------------------------
bool Mill::setCurGameState(fieldStruct *curState)
{
    curState->copyBoard(&field);

    winner = 0;
    movesDone = 0;

    if ((field.curPlayer->pieceCount < 3) && (!field.isPlacingPhase))
        winner = field.oppPlayer->id;

    if ((field.oppPlayer->pieceCount < 3) && (!field.isPlacingPhase))
        winner = field.curPlayer->id;

    if ((field.curPlayer->possibleMovesCount == 0) && (!field.isPlacingPhase))
        winner = field.oppPlayer->id;

    return true;
}

//-----------------------------------------------------------------------------
// compareWithField()
// Compares the current 'board' variable with the passed one. 'isPieceMovable[]'
// is ignored.
//-----------------------------------------------------------------------------
bool Mill::compareWithField(fieldStruct *compareField)
{
    uint32_t i, j;
    bool ret = true;

    if (!comparePlayers(field.curPlayer, compareField->curPlayer)) {
        cout << "error - curPlayer differs!" << std::endl;
        ret = false;
    }

    if (!comparePlayers(field.oppPlayer, compareField->oppPlayer)) {
        cout << "error - oppPlayer differs!" << std::endl;
        ret = false;
    }

    if (field.piecePlacedCount != compareField->piecePlacedCount) {
        cout << "error - piecePlacedCount differs!" << std::endl;
        ret = false;
    }

    if (field.isPlacingPhase != compareField->isPlacingPhase) {
        cout << "error - isPlacingPhase differs!" << std::endl;
        ret = false;
    }

    if (field.pieceMustBeRemovedCount !=
        compareField->pieceMustBeRemovedCount) {
        cout << "error - pieceMustBeRemovedCount differs!" << std::endl;
        ret = false;
    }

    for (i = 0; i < SQUARE_NB; i++) {
        if (field.board[i] != compareField->board[i]) {
            cout << "error - board[] differs!" << std::endl;
            ret = false;
        }

        if (field.warnings[i] != compareField->warnings[i]) {
            cout << "error - warnings[] differs!" << std::endl;
            ret = false;
        }

        if (field.piecePartOfMillCount[i] !=
            compareField->piecePartOfMillCount[i]) {
            cout << "error - piecePart[] differs!" << std::endl;
            ret = false;
        }

        for (j = 0; j < 4; j++) {
            if (field.connectedSquare[i][j] !=
                compareField->connectedSquare[i][j]) {
                cout << "error - connectedSquare[] differs!" << std::endl;
                ret = false;
            }

            // if (board.isPieceMovable[i][j] !=
            // compareField->isPieceMovable[i][j])
            //     { cout << "error - isPieceMovable differs!" << endl; ret =
            //     false; }

            if (field.neighbor[i][j / 2][j % 2] !=
                compareField->neighbor[i][j / 2][j % 2]) {
                cout << "error - neighbor differs!" << std::endl;
                ret = false;
            }
        }
    }

    return ret;
}

//-----------------------------------------------------------------------------
// comparePlayers()
// Compares the two passed players and returns false if they differ.
//-----------------------------------------------------------------------------
bool Mill::comparePlayers(Player *playerA, Player *playerB)
{
    // uint32_t i;
    bool ret = true;

    if (playerA->removedPiecesCount != playerB->removedPiecesCount) {
        cout << "error - removedPiecesCount differs!" << std::endl;
        ret = false;
    }

    if (playerA->pieceCount != playerB->pieceCount) {
        cout << "error - pieceCount differs!" << std::endl;
        ret = false;
    }

    if (playerA->id != playerB->id) {
        cout << "error - id differs!" << std::endl;
        ret = false;
    }

    if (playerA->warning != playerB->warning) {
        cout << "error - warning differs!" << std::endl;
        ret = false;
    }

    if (playerA->possibleMovesCount != playerB->possibleMovesCount) {
        cout << "error - possibleMovesCount differs!" << std::endl;
        ret = false;
    }

#if 0
    for (i = 0; i < POSIBILE_MOVE_COUNT_MAX; i++)
        if (playerA->posFrom[i] = playerB->posFrom[i])
            return false;
    for (i = 0; i < POSIBILE_MOVE_COUNT_MAX; i++)
        if (playerA->posTo[i] = playerB->posTo[i])
            return false;
#endif
    return ret;
}

//-----------------------------------------------------------------------------
// printBoard()
// Calls the printBoard() function of the current board.
//       Prints the current game state on the screen.
//-----------------------------------------------------------------------------
void Mill::printBoard()
{
    field.printBoard();
}

//-----------------------------------------------------------------------------
// undoMove()
// Sets the initial board as the current one and apply all (minus one) moves
// from the move history.
//-----------------------------------------------------------------------------
void Mill::undoMove(void)
{
    // locals
    uint32_t *moveLogFrom_bak = new uint32_t[movesDone];
    uint32_t *moveLogTo_bak = new uint32_t[movesDone];
    uint32_t movesDone_bak = movesDone;
    uint32_t i;

    // at least one move must be done
    if (movesDone) {
        // make backup of log
        for (i = 0; i < movesDone; i++) {
            moveLogFrom_bak[i] = moveLogFrom[i];
            moveLogTo_bak[i] = moveLogTo[i];
        }

        // reset
        initField.copyBoard(&field);
        winner = 0;
        movesDone = 0;

        // and play again
        for (i = 0; i < movesDone_bak - 1; i++) {
            doMove(moveLogFrom_bak[i], moveLogTo_bak[i]);
        }
    }

    // free mem
    delete[] moveLogFrom_bak;
    delete[] moveLogTo_bak;
}

//-----------------------------------------------------------------------------
// calcRestingPieceCount()
//
//-----------------------------------------------------------------------------
void Mill::calcRestingPieceCount(int &nWhitePiecesResting,
                                 int &nBlackPiecesResting)
{
    if (getCurPlayer() == fieldStruct::playerTwo) {
        nWhitePiecesResting = fieldStruct::piecePerPlayerCount -
                              field.curPlayer->removedPiecesCount -
                              field.curPlayer->pieceCount;
        nBlackPiecesResting = fieldStruct::piecePerPlayerCount -
                              field.oppPlayer->removedPiecesCount -
                              field.oppPlayer->pieceCount;
    } else {
        nWhitePiecesResting = fieldStruct::piecePerPlayerCount -
                              field.oppPlayer->removedPiecesCount -
                              field.oppPlayer->pieceCount;
        nBlackPiecesResting = fieldStruct::piecePerPlayerCount -
                              field.curPlayer->removedPiecesCount -
                              field.curPlayer->pieceCount;
    }
}

#endif // MADWEASEL_MUEHLE_PERFECT_AI
