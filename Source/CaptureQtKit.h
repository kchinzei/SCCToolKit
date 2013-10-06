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

#ifndef __Cap__CaptureQtKit__
#define __Cap__CaptureQtKit__

#include "Capture.h"


namespace Cap {
    struct CaptureQtKit_private;

    class CaptureQtKit : public Capture
    {
    public:
        CaptureQtKit();
        ~CaptureQtKit() override;
        
        bool init(void) override;
        void start(void)  override;
        void stop(void)  override;
        bool isConnected(void) override;
        cv::Mat& retrieve(int channel=0) override;
        virtual CIImage* retrieveCIImage(int channel=0) override;   ///< See also cv::VideoCapture::read()
        bool lock(int channel=0) override;
        void unlock(int channel=0) override;
        
        void setDesiredSize(int dWidth, int dHeight) override;
        void setDesiredWidth(int dWidth) override;
        void setDesiredHeight(int dHeight) override;
        
        CaptureType getCaptureType(void) override {return kCaptureTypeQtKit;};
        bool hasHardwareTimer() override {return true;};
        int getNChannels(void) override {return 1;};
        float getFPS(void) override {return fps;};
        
        // Specific members
        bool mUseInternalCameras;
        
    private:
        Cap::CaptureQtKit_private* priv;

        int mCameraID;
        CaptureState mStarted;
        
        float   fps;
        bool    mLock;

        void cleanup(void);
        bool isOpen(void);
    };
};

#endif
