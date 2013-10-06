//
//  timerSingleton.h
//  cvstereoqt
//
//  Created by 鎮西 清行 on 13/03/23.
//
//

#ifndef __cvstereoqt__timerSingleton__
#define __cvstereoqt__timerSingleton__

#include <iostream>
#include <sys/time.h>

class timerSingleton {
public:
    static timerSingleton* sharedInstance()
    {
    	static timerSingleton instance;
    	return &instance;
    }

    double tLatest;
    
    bool startMeasure;
    void tStart();
    void tStop();
    void tReset();
    double avgTime();
    
private:
    // These are hidden from others.
    timerSingleton();
    timerSingleton(const timerSingleton& rhs) {};
    timerSingleton& operator=(const timerSingleton& rhs) {timerSingleton *r = sharedInstance(); return *r;};

    bool measuring;
    timeval time1;
    int nCount;
    double tSum;
};

#endif /* defined(__cvstereoqt__timerSingleton__) */
