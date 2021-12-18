/*********************************************************************
    CyclicArray.cpp
    Copyright (c) Thomas Weber. All rights reserved.
    Copyright (C) 2021 The Sanmill developers (see AUTHORS file)
    Licensed under the GPLv3 License.
    https://github.com/madweasel/Muehle
\*********************************************************************/

#include "config.h"

#ifdef MADWEASEL_MUEHLE_PERFECT_AI

#include "cyclicArray.h"

//-----------------------------------------------------------------------------
// CyclicArray()
// Creates a cyclic array. The passed file is used as temporary data buf for
// the cyclic array.
//-----------------------------F------------------------------------------------
CyclicArray::CyclicArray(uint32_t blockSizeInBytes, uint32_t nBlocks,
                         const char *fileName)
{
    // Init blocks
    blockSize = blockSizeInBytes;
    blockCount = nBlocks;
    readingBlock = new unsigned char[blockSize];
    writingBlock = new unsigned char[blockSize];
    curReadingPtr = writingBlock;
    curWritingPtr = writingBlock;
    readWriteInSameRound = true;
    curReadingBlock = 0;
    curWritingBlock = 0;

    // Open Database-File (FILE_FLAG_NO_BUFFERING | FILE_FLAG_WRITE_THROUGH |
    // FILE_FLAG_RANDOM_ACCESS)
    hFile = CreateFileA(fileName, GENERIC_READ | GENERIC_WRITE,
                        FILE_SHARE_READ | FILE_SHARE_WRITE, nullptr,
                        OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, nullptr);

    // opened file successfully
    if (hFile == INVALID_HANDLE_VALUE) {
        hFile = nullptr;
        return;
    }
}

//-----------------------------------------------------------------------------
// ~RandomAI()
// RandomAI class destructor
//-----------------------------------------------------------------------------
CyclicArray::~CyclicArray()
{
    // delete arrays
    delete[] readingBlock;
    delete[] writingBlock;

    // close file
    if (hFile != nullptr)
        CloseHandle(hFile);
}

//-----------------------------------------------------------------------------
// writeDataToFile()
// Writes 'sizeInBytes'-bytes to the position 'offset' to the file.
//-----------------------------------------------------------------------------
void CyclicArray::writeDataToFile(HANDLE fd, int64_t offset,
                                  uint32_t sizeInBytes, void *pData)
{
    DWORD dwBytesWritten;
    LARGE_INTEGER liDistanceToMove;
    uint32_t restingBytes = sizeInBytes;

    liDistanceToMove.QuadPart = offset;

    while (!SetFilePointerEx(fd, liDistanceToMove, nullptr, FILE_BEGIN))
        cout << std::endl << "SetFilePointerEx  failed!";

    while (restingBytes > 0) {
        if (WriteFile(fd, pData, sizeInBytes, &dwBytesWritten, nullptr) ==
            TRUE) {
            restingBytes -= dwBytesWritten;
            pData = (void *)(((unsigned char *)pData) + dwBytesWritten);
            if (restingBytes > 0)
                cout << std::endl << "Still " << restingBytes << " to write!";
        } else {
            cout << std::endl << "WriteFile Failed!";
        }
    }
}

//-----------------------------------------------------------------------------
// readDataFromFile()
// Reads 'sizeInBytes'-bytes from the position 'offset' of the file.
//-----------------------------------------------------------------------------
void CyclicArray::readDataFromFile(HANDLE fd, int64_t offset,
                                   uint32_t sizeInBytes, void *pData)
{
    DWORD dwBytesRead;
    LARGE_INTEGER liDistanceToMove;
    uint32_t restingBytes = sizeInBytes;

    liDistanceToMove.QuadPart = offset;

    while (!SetFilePointerEx(fd, liDistanceToMove, nullptr, FILE_BEGIN))
        cout << std::endl << "SetFilePointerEx failed!";

    while (restingBytes > 0) {
        if (ReadFile(fd, pData, sizeInBytes, &dwBytesRead, nullptr) == TRUE) {
            restingBytes -= dwBytesRead;
            pData = (void *)(((unsigned char *)pData) + dwBytesRead);
            if (restingBytes > 0)
                cout << std::endl << "Still " << restingBytes << " to read!";
        } else {
            cout << std::endl << "ReadFile Failed!";
        }
    }
}

//-----------------------------------------------------------------------------
// addBytes()
// Add the passed data to the cyclic array. If the writing pointer reaches the
// end of a block,
//       the data of the whole block is written to the file and the next block
//       is considered for writing.
//-----------------------------------------------------------------------------
bool CyclicArray::addBytes(uint32_t nBytes, unsigned char *pData)
{
    // locals
    uint32_t bytesWritten = 0;

    // write each byte
    while (bytesWritten < nBytes) {
        // store byte in current reading block
        *curWritingPtr = *pData;
        curWritingPtr++;
        bytesWritten++;
        pData++;

        // when block is full then save current one to file and begin new one
        if (curWritingPtr == writingBlock + blockSize) {
            // copy data into reading block?
            if (curReadingBlock == curWritingBlock) {
                memcpy(readingBlock, writingBlock, blockSize);
                curReadingPtr = readingBlock + (curReadingPtr - writingBlock);
            }

            // will reading block be overwritten?
            if (curReadingBlock == curWritingBlock && !readWriteInSameRound)
                return false;

            // store bock in file
            writeDataToFile(hFile,
                            ((int64_t)blockSize) * ((int64_t)curWritingBlock),
                            blockSize, writingBlock);

            // set pointer to beginning of writing block
            curWritingPtr = writingBlock;
            curWritingBlock = (curWritingBlock + 1) % blockCount;

            if (curWritingBlock == 0)
                readWriteInSameRound = false;
        }
    }

    // everything ok
    return true;
}

//-----------------------------------------------------------------------------
// bytesAvailable()
//
//-----------------------------------------------------------------------------
bool CyclicArray::bytesAvailable()
{
    if (curReadingBlock == curWritingBlock && curReadingPtr == curWritingPtr &&
        readWriteInSameRound)
        return false;
    else
        return true;
}

//-----------------------------------------------------------------------------
// takeBytes()
// Load data from the cyclic array. If the reading pointer reaches the end of a
// block,
//       the data of the next whole block is read from the file.
//-----------------------------------------------------------------------------
bool CyclicArray::takeBytes(uint32_t nBytes, unsigned char *pData)
{
    // locals
    uint32_t bytesRead = 0;

    // read each byte
    while (bytesRead < nBytes) {
        // was current reading byte already written ?
        if (curReadingBlock == curWritingBlock &&
            curReadingPtr == curWritingPtr && readWriteInSameRound)
            return false;

        // read current byte
        *pData = *curReadingPtr;
        curReadingPtr++;
        bytesRead++;
        pData++;

        // load next block?
        if (curReadingPtr == readingBlock + blockSize) {
            // go to next block
            curReadingBlock = (curReadingBlock + 1) % blockCount;
            if (curReadingBlock == 0)
                readWriteInSameRound = true;

            // writing block reached ?
            if (curReadingBlock == curWritingBlock) {
                curReadingPtr = writingBlock;
            } else {
                // set pointer to beginning of reading block
                curReadingPtr = readingBlock;

                // read whole block from file
                readDataFromFile(
                    hFile, ((int64_t)blockSize) * ((int64_t)curReadingBlock),
                    blockSize, readingBlock);
            }
        }
    }

    // everything ok
    return true;
}

//-----------------------------------------------------------------------------
// loadFile()
// Load the passed file into the cyclic array.
//       The passed filename must be different than the passed filename to the
//       constructor cyclicarray().
//-----------------------------------------------------------------------------
bool CyclicArray::loadFile(const char *fileName, LONGLONG &nBytesLoaded)
{
    // locals
    HANDLE hLoadFile;
    unsigned char *dataInFile;
    LARGE_INTEGER largeInt;
    LONGLONG maxFileSize = ((LONGLONG)blockSize) * ((LONGLONG)blockCount);
    LONGLONG curOffset = 0;
    uint32_t nblocksInFile;
    uint32_t curBlock;
    uint32_t nBytesInLastBlock;
    nBytesLoaded = 0;

    // cyclic array file must be open
    if (hFile == nullptr)
        return false;

    // Open Database-File (FILE_FLAG_NO_BUFFERING | FILE_FLAG_WRITE_THROUGH |
    // FILE_FLAG_RANDOM_ACCESS)
    hLoadFile = CreateFileA(fileName, GENERIC_READ, FILE_SHARE_READ, nullptr,
                            OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, nullptr);

    // opened file successfully
    if (hLoadFile == INVALID_HANDLE_VALUE) {
        return false;
    }

    // does data of file fit into cyclic array ?
    GetFileSizeEx(hLoadFile, &largeInt);

    if (maxFileSize < largeInt.QuadPart) {
        CloseHandle(hLoadFile);
        return false;
    }

    // reset
    curReadingPtr = writingBlock;
    curWritingPtr = writingBlock;
    readWriteInSameRound = true;
    curReadingBlock = 0;
    curWritingBlock = 0;

    nblocksInFile = (uint32_t)(largeInt.QuadPart / ((LONGLONG)blockSize)) + 1;
    nBytesInLastBlock = (uint32_t)(largeInt.QuadPart % ((LONGLONG)blockSize));
    dataInFile = new unsigned char[blockSize];

    //
    for (curBlock = 0; curBlock < nblocksInFile - 1;
         curBlock++, curOffset += blockSize) {
        // load data from file
        readDataFromFile(hLoadFile, curOffset, blockSize, dataInFile);

        // put block in cyclic array
        addBytes(blockSize, dataInFile);
    }

    // last block
    readDataFromFile(hLoadFile, curOffset, nBytesInLastBlock, dataInFile);
    addBytes(nBytesInLastBlock, dataInFile);
    curOffset += nBytesInLastBlock;
    nBytesLoaded = curOffset;

    // everything ok
    delete[] dataInFile;
    CloseHandle(hLoadFile);
    return true;
}

//-----------------------------------------------------------------------------
// saveFile()
// Writes the whole current content of the cyclic array to the passed file.
//       The passed filename must be different than the passed filename to the
//       constructor cyclicarray().
//-----------------------------------------------------------------------------
bool CyclicArray::saveFile(const char *fileName)
{
    // locals
    unsigned char *dataInFile;
    HANDLE hSaveFile;
    LONGLONG curOffset;
    uint32_t curBlock;
    uint32_t bytesToWrite;
    void *ptr;

    // cyclic array file must be open
    if (hFile == nullptr) {
        return false;
    }

    // Open Database-File
    // (FILE_FLAG_NO_BUFFERING | FILE_FLAG_WRITE_THROUGH |
    // FILE_FLAG_RANDOM_ACCESS)
    hSaveFile = CreateFileA(fileName, GENERIC_WRITE, FILE_SHARE_WRITE, nullptr,
                            OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, nullptr);

    // opened file successfully
    if (hSaveFile == INVALID_HANDLE_VALUE) {
        return false;
    }

    // alloc mem
    curOffset = 0;
    curBlock = curReadingBlock;
    dataInFile = new unsigned char[blockSize];

    do {
        // copy current block
        if (curBlock == curWritingBlock && curBlock == curReadingBlock) {
            ptr = curReadingPtr;
            bytesToWrite = (uint32_t)(curWritingPtr - curReadingPtr);
        } else if (curBlock == curWritingBlock) {
            ptr = writingBlock;
            bytesToWrite = (uint32_t)(curWritingPtr - writingBlock);
        } else if (curBlock == curReadingBlock) {
            ptr = curReadingPtr;
            bytesToWrite = blockSize - (uint32_t)(curReadingPtr - readingBlock);
        } else {
            readDataFromFile(hFile, ((int64_t)curBlock) * ((int64_t)blockSize),
                             blockSize, dataInFile);
            ptr = dataInFile;
            bytesToWrite = blockSize;
        }

        // save data to file
        writeDataToFile(hSaveFile, curOffset, bytesToWrite, ptr);
        curOffset += bytesToWrite;

        // exit?
        if (curBlock == curWritingBlock)
            break;
        else
            curBlock = (curBlock + 1) % blockCount;
    } while (true);

    // everything ok
    delete[] dataInFile;
    CloseHandle(hSaveFile);
    return true;
}

#endif // MADWEASEL_MUEHLE_PERFECT_AI
