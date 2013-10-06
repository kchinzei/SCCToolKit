//
//  timerSingleton.cpp
//  cvstereoqt
//
//  Created by 鎮西 清行 on 13/03/23.
//
//

#include "timerSingleton.h"
#include <dispatch/dispatch.h>

timerSingleton::timerSingleton()
{
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        tReset();
    });
}

void timerSingleton::tReset()
{
    nCount = 0;
    tSum = 0;
    tLatest = 0;
    startMeasure = measuring = false;
}

void timerSingleton::tStart()
{
    if (startMeasure) {
        measuring = true;
        gettimeofday(&time1, NULL);
    }
}

void timerSingleton::tStop()
{
    if (measuring) {
        timeval time2;
        gettimeofday(&time2, NULL);
        
        double millis1 = time1.tv_sec * 1000.0 + time1.tv_usec / 1000.0;
        double millis2 = time2.tv_sec * 1000.0 + time2.tv_usec / 1000.0;
        
        tLatest = millis2 - millis1;
        tSum += tLatest;
        nCount++;
        
        measuring = false;
        startMeasure = false;
    }
}

double timerSingleton::avgTime()
{
    if (nCount > 0)
        return tSum / nCount;
    else
        return 0.0;
}