/*=========================================================================
 
 Program:   Small Computings for Clinicals Project
 Module:    $HeadURL: $
 Date:      $Date: $
 Version:   $Revision: $
 URL:       http://scc.pj.aist.go.jp
 
 (c) 2013- Kiyoyuki Chinzei, Ph.D., AIST Japan, All rights reserved.
 
 Acknowledgement: This work is/was supported by many research fundings.
 See Acknowledgement.txt
 
 This software is distributed WITHOUT ANY WARRANTY; without even
 the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
 PURPOSE.  See License.txt for license terms.
 
 =========================================================================*/

#include "CaptureCenter.h"
//#include "CaptureCv.h"
#include "CaptureDeckLink.h"
#include "CaptureQtKit.h"
#include <dispatch/dispatch.h>

using namespace Cap;

static float desiredFPS = 30;
static dispatch_source_t watchDogTimer = 0;
static dispatch_queue_t	 watchDogQueue = 0;
static dispatch_source_t captureTimer = 0;
static dispatch_queue_t	 captureQueue = 0;
static bool captureTimerSuspended = true;

#define kNoTimer ((Capture *)(-1))

CaptureCenter::CaptureCenter()
    : useSoftwareTimer(true)
    , activeTimer(kNoTimer)
{
    captures.clear();
    
    // OSX dependent
    // Prepare the watchdog. Priority can be low.
    watchDogQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    watchDogTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_queue_create("watchdog timer queue", nullptr));
    dispatch_source_set_event_handler(watchDogTimer, ^{
        dispatch_async(watchDogQueue, ^{
            periodicActivation();
        });
    });
    dispatch_source_set_timer(watchDogTimer, dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC) , NSEC_PER_SEC/2, NSEC_PER_SEC/5);
    
    
    // This timer may be used when there is no active hardware timer.
    captureQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    captureTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_queue_create("capture timer queue", nullptr));
    dispatch_source_set_timer(captureTimer, dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC) , NSEC_PER_SEC/desiredFPS, NSEC_PER_SEC/60);
    dispatch_source_set_event_handler(captureTimer, ^{
        imagesArrived(nullptr);
    });
}

CaptureCenter::~CaptureCenter()
{
    stop();
    /*
    dispatch_release(captureTimer);
    dispatch_release(captureQueue);
    dispatch_release(watchDogTimer);
    dispatch_release(watchDogQueue);
     */
    CapturePtrVec::iterator cap = captures.begin();
    while (cap != captures.end()) {
        delete *cap++;
    }
}

Capture* CaptureCenter::addCapture(CaptureType capture_type)
{
    Capture *cap = nullptr;
    switch (capture_type) {
        case kCaptureTypeOpenCV:
            //cap = new CaptureCv;
            break;
        case kCaptureTypeQtKit:
            cap = new CaptureQtKit;
            break;
        case kCaptureTypeDeckLink:
            cap = new CaptureDeckLink;
            break;
        default:
            break;
    }
    if (cap) {
        captures.push_back(cap);
        cap->setCaptureCenter(this);
    }
    return cap;
}

void CaptureCenter::periodicActivation(void)
{
    Capture *newActiveTimer = nullptr;
    
    CapturePtrVec::iterator cap = captures.begin();
    while (cap != captures.end()) {
        Capture *c = (*cap++);
        c->init();
        if (!useSoftwareTimer && c->hasHardwareTimer() && c->isReady() && newActiveTimer == nullptr)
            newActiveTimer = c;
    }
    
    // We must change the timer.
    if (newActiveTimer != activeTimer) {
        cap = captures.begin();
        while (cap != captures.end()) {
            Capture *c = (*cap++);
            c->setActAsTimer(false);
        }
        if (activeTimer == nullptr) {
            if (captureTimerSuspended == false) {
                dispatch_suspend(captureTimer);
                captureTimerSuspended = true;
            }
        }
        
        activeTimer = newActiveTimer;
        
        // Take some time
        dispatch_time_t t = dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC/4);
        dispatch_after(t, captureQueue, ^{
            if (activeTimer == nullptr) {
                if (captureTimerSuspended) {
                    dispatch_resume(captureTimer);
                    captureTimerSuspended = false;
                }
            } else
                activeTimer->setActAsTimer(true);
        });
    }
}

void CaptureCenter::start(void)
{
    // Prepare our own timer.
    dispatch_source_set_timer(captureTimer, dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC) , NSEC_PER_SEC/desiredFPS, NSEC_PER_SEC/60);
    
    // Start our timer if no hardware timer has been set.
    periodicActivation();
    if (activeTimer == nullptr) {
        if (captureTimerSuspended) {
            dispatch_resume(captureTimer);
            captureTimerSuspended = false;
        }
    }
    CapturePtrVec::iterator cap = captures.begin();
    while (cap != captures.end()) {
        (*cap++)->start();
    }

    // Start watchdog.
    dispatch_resume(watchDogTimer);
}

void CaptureCenter::stop(void)
{
    if (captureTimerSuspended == false) {
        dispatch_suspend(captureTimer);
        captureTimerSuspended = true;
    }
    dispatch_suspend(watchDogTimer);
    CapturePtrVec::iterator cap = captures.begin();
    while (cap != captures.end()) {
        (*cap++)->stop();
    }
}

void CaptureCenter::setDesiredFPS(float FPS)
{
    useSoftwareTimer = (FPS > 0);
    if (useSoftwareTimer) desiredFPS = FPS;
}

float CaptureCenter::getDesiredFPS()
{
    return desiredFPS;
}

