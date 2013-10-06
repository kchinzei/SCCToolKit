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

#ifndef __Capture__
#define __Capture__

#include <opencv2/core/core.hpp>
#include "CaptureTypes.h"

@class CIImage;

namespace Cap {
    typedef void (CaptureReadCapturesProc)(void);
    class CaptureCenter;
        
#define kCaptureBufLen 1024
    class Capture {
    public:
        CaptureState state;
        char mModelName[kCaptureBufLen];
        char mUniqueID[kCaptureBufLen];

        Capture();
        virtual ~Capture() {};
        
        /*!
         Returns true when initializattion is successful or hardware is not found. It returns false otherwise.
         False value means that something wrong in configuration so that the program cannot run without fixing it.
         init() assumes that "expeced hardware is not attached now" is not an error.
         Status of initialization is found in \param state.
         */
        virtual bool init(void) = 0;
        virtual void start(void) {};
        virtual void stop(void) {};
        
        /*!
         Returns true when hardware is ready for capture, i.e., the hardware is found and successfully initialized
         at the latest invocation of init(). This may not be realtime accurate.
         */
        bool isReady(void) { return state <= kCaptureState_Inactive; };
        virtual bool isConnected(void) = 0;     ///< Examines if device is connected for our App. Calling it too often may have performance problem.
        virtual cv::Mat& retrieve(int channel=0) = 0;   ///< See also cv::VideoCapture::read()
        virtual CIImage* retrieveCIImage(int channel=0) = 0;   ///< See also cv::VideoCapture::read()
        virtual bool lock(int channel=0) = 0;   ///< Notify that cv::Mat obtained by retrieve() is in use. It returns false when it is currently locked.
        virtual void unlock(int channel=0) = 0;
        
        virtual void setDesiredSize(int dWidth, int dHeight);
        virtual void setDesiredWidth( int dWidth);
        virtual void setDesiredHeight(int dHeight);
		long getDesiredWidth();
		long getDesiredHeight();

		virtual CaptureType getCaptureType() = 0;
        virtual bool hasHardwareTimer() = 0;
		virtual int getNChannels(void) = 0; // Should call after init() success.
        virtual float getFPS(void) = 0;     // Should call after init() success.
        
        void setActAsTimer(bool asTimer);
        void setCaptureCenter(CaptureCenter *cc);
        
    protected:
		long desiredWidth, desiredHeight;
        bool actAsTimer;
        CaptureCenter *capcenter;
    };
};

#endif /* defined(__Capture__) */
