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

#ifndef __CaptureDeckLink__
#define __CaptureDeckLink__

#include "Capture.h"
#include "DeckLinkAPI.h"
#include <dispatch/dispatch.h>

class CustomDeckLinkVideoFrame;
@class CIFilter;
@class NSBitmapImageRep;

namespace Cap {
    class CaptureDeckLink : private IDeckLinkInputCallback, public Capture
    {
    public:
        BMDVideoInputFlags  mInputFlags;
        BMDDisplayMode      mDisplayMode;
        BMDPixelFormat      mPixelFormat;
        char                mDisplayModeName[kCaptureBufLen];
        
        CaptureDeckLink();
        ~CaptureDeckLink() override;
        
        bool init(void) override;
        void start(void)  override;
        void stop(void)  override;
        bool isConnected(void) override;
        cv::Mat& retrieve(int channel=0) override;
        CIImage* retrieveCIImage(int channel=0) override;   ///< See also cv::VideoCapture::read()
        bool lock(int channel=0) override;
        void unlock(int channel=0) override;
        
        CaptureType getCaptureType(void) override {return kCaptureTypeDeckLink;};
        bool hasHardwareTimer() override {return true;};
        int getNChannels(void) override {return nChannels;};
        float getFPS(void) override {return fps;};
        
    private:
        HRESULT STDMETHODCALLTYPE QueryInterface(REFIID iid, LPVOID *ppv) { return E_NOINTERFACE; };
        ULONG STDMETHODCALLTYPE AddRef(void);
        ULONG STDMETHODCALLTYPE Release(void);
        HRESULT STDMETHODCALLTYPE VideoInputFormatChanged(BMDVideoInputFormatChangedEvents, IDeckLinkDisplayMode*, BMDDetectedVideoInputFormatFlags);
        HRESULT STDMETHODCALLTYPE VideoInputFrameArrived(IDeckLinkVideoInputFrame*, IDeckLinkAudioInputPacket*);
        
        void cleanup(void);
        
        ULONG				m_refCount;
        dispatch_semaphore_t mSemaphore_refcount;
        dispatch_semaphore_t mSemaphore_init;
        dispatch_semaphore_t mSemaphore_imgL;
        dispatch_semaphore_t mSemaphore_imgR;
        CaptureState        mStarted;
        
        IDeckLinkIterator   *deckLinkIterator;
        IDeckLink           *deckLink;
        IDeckLinkInput      *deckLinkInput;
        IDeckLinkConfiguration *deckLinkConfig;
        
        CustomDeckLinkVideoFrame *mConversionFrameL;
        CustomDeckLinkVideoFrame *mConversionFrameR;
        IDeckLinkVideoConversion *mConversion;
        
        int     nChannels;
        float   fps;
        
        cv::Mat     mImageL;
        cv::Mat     mImageR;
        bool    mLockL, mLockR;
        CIImage *mCIImageL;
        CIImage *mCIImageR;
        CIFilter *mCMatrix;
        NSBitmapImageRep *mBitmapRepL;
        NSBitmapImageRep *mBitmapRepR;
        dispatch_queue_t mFilterQ;
    };
};

#endif
