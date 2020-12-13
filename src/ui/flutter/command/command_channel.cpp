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

#include <stdlib.h>
#include "command_queue.h"
#include "command_channel.h"

CommandChannel *CommandChannel::instance = NULL;

CommandChannel::CommandChannel()
{
    commandQueue = new CommandQueue();
    responseQueue = new CommandQueue();
}

CommandChannel *CommandChannel::getInstance()
{
    if (instance == NULL) {
        instance = new CommandChannel();
    }

    return instance;
}

void CommandChannel::release()
{
    if (instance != NULL) {
        delete instance;
        instance = NULL;
    }
}

CommandChannel::~CommandChannel()
{
    if (commandQueue != NULL) {
        delete commandQueue;
        commandQueue = NULL;
    }

    if (responseQueue != NULL) {
        delete responseQueue;
        responseQueue = NULL;
    }
}

bool CommandChannel::pushCommand(const char *cmd)
{
    return commandQueue->write(cmd);
}

bool CommandChannel::popupCommand(char *buffer)
{
    return commandQueue->read(buffer);
}

bool CommandChannel::pushResponse(const char *resp)
{
    return responseQueue->write(resp);
}

bool CommandChannel::popupResponse(char *buffer)
{
    return responseQueue->read(buffer);
}
