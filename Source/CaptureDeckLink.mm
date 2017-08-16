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

#include <cxcore.h>

#include "CaptureCenter.h"
#include "DeckLinkAPI.h"
#include "CaptureDeckLink.h"
#include "CustomDeckLinkVideoFrame.h"
#include <iostream>

#import <QuartzCore/QuartzCore.h>
#import <QuartzCore/CIImage.h>
#import <AppKit/AppKit.h>

#define kCV_PIXEL_FMT kCVPixelFormatType_32BGRA // Looks like this alone was supported by QT. kCVPixelFormatType_422YpCbCr8 also works.
#define kCI_PIXEL_FMT kCIFormatARGB8

using namespace Cap;
using namespace std;

static CustomDeckLinkVideoFrame *allocateConversionFrame(const IDeckLinkVideoFrame* videoFrame);
static CustomDeckLinkVideoFrame *allocateConversionFrame(long width, long height);
static void initMatWithVideoFrame(cv::Mat *image, const CustomDeckLinkVideoFrame *convFrame);
static void initCIImageWithMat(CIImage *image, const cv::Mat* mat, NSBitmapImageRep *bitmapRep);
static CIImage * makeCIImageFromMat(const cv::Mat* mat, NSBitmapImageRep **bitmapRep);
static float getFrameRate(const IDeckLinkDisplayMode *mode);

CaptureDeckLink::CaptureDeckLink()
    : Capture()
    , mInputFlags(bmdVideoInputFlagDefault)
    , mDisplayMode(bmdModeHD1080i5994)
    , mPixelFormat(bmdFormat8BitYUV)
    , m_refCount(0)
    , mStarted(kCaptureState_Inactive)
    , deckLinkIterator(nullptr)
    , deckLink(nullptr)
    , deckLinkInput(nullptr)
    , deckLinkConfig(nullptr)
    , mConversionFrameL(nullptr)
    , mConversionFrameR(nullptr)
    , mConversion(nullptr)
    , nChannels(1)
    , fps(0)
    , mLockL(false)
    , mLockR(false)
    , mCIImageL(nil)
    , mCIImageR(nil)
    , mCMatrix(nil)
    , mBitmapRepL(nil)
    , mBitmapRepR(nil)
{
    mSemaphore_refcount = dispatch_semaphore_create(1);
    mSemaphore_init = dispatch_semaphore_create(1);
    mSemaphore_imgL = dispatch_semaphore_create(1);
    mSemaphore_imgR = dispatch_semaphore_create(1);
    AddRef();
    mDisplayModeName[0] = '\0';
    mImageL = cv::Mat(desiredHeight, desiredWidth, CV_8UC4);
    mImageR = cv::Mat(desiredHeight, desiredWidth, CV_8UC4);
    // ARC
    NSBitmapImageRep *tmpRep = nil;
    mCIImageL = makeCIImageFromMat(&mImageL, &tmpRep); mBitmapRepL = tmpRep;
    mCIImageR = makeCIImageFromMat(&mImageR, &tmpRep); mBitmapRepR = tmpRep;
    mFilterQ = dispatch_queue_create("jp.go.aist.filterQ.left", DISPATCH_QUEUE_SERIAL);
    dispatch_sync(mFilterQ, ^{
        mCMatrix = [CIFilter filterWithName:@"CIColorMatrix"
                              keysAndValues:
                    @"inputRVector", [CIVector vectorWithX:0 Y:0 Z:1 W:0],
                    @"inputGVector", [CIVector vectorWithX:0 Y:1 Z:0 W:0],
                    @"inputBVector", [CIVector vectorWithX:1 Y:0 Z:0 W:0],
                    @"inputAVector", [CIVector vectorWithX:0 Y:0 Z:0 W:1],
                    @"inputBiasVector", [CIVector vectorWithX:0 Y:0 Z:0 W:0],
                    nil];
    });
}

CaptureDeckLink::~CaptureDeckLink()
{
    stop();
    cleanup();
	if (deckLinkIterator != nullptr)
		deckLinkIterator->Release();
    // ARC
    dispatch_release(mSemaphore_imgL);
    dispatch_release(mSemaphore_imgR);
    dispatch_release(mSemaphore_init);
    dispatch_release(mSemaphore_refcount);
    [mCIImageL release];
    [mCIImageR release];
    [mCMatrix release];
    [mBitmapRepL release];
    [mBitmapRepR release];
    dispatch_release(mFilterQ);
}

void CaptureDeckLink::cleanup()
{
    if (deckLinkConfig != nullptr)
        deckLinkConfig->Release();
    deckLinkConfig = nullptr;
    
    if (deckLinkInput != nullptr)
        deckLinkInput->Release();
    deckLinkInput = nullptr;
    
    if (deckLink != nullptr)
        deckLink->Release();
    deckLink = nullptr;
    
    if (mConversion)
        mConversion->Release();
    mConversion = nullptr;
}

ULONG CaptureDeckLink::AddRef(void)
{
    dispatch_semaphore_wait(mSemaphore_refcount, DISPATCH_TIME_FOREVER);
	m_refCount++;
	dispatch_semaphore_signal(mSemaphore_refcount);
                    
	return (ULONG)m_refCount;
}

ULONG CaptureDeckLink::Release(void)
{
    dispatch_semaphore_wait(mSemaphore_refcount, DISPATCH_TIME_FOREVER);
	m_refCount--;
	dispatch_semaphore_signal(mSemaphore_refcount);

	if (m_refCount == 0) {
		delete this;
		return 0;
	}

	return (ULONG)m_refCount;
}

HRESULT CaptureDeckLink::VideoInputFrameArrived(IDeckLinkVideoInputFrame* videoFrame, IDeckLinkAudioInputPacket* audioFrame)
{
	IDeckLinkVideoFrame*             rightEyeFrame = nullptr;
	IDeckLinkVideoFrame3DExtensions* threeDExtensions = nullptr;
    HRESULT result = S_OK;
    CaptureState tmpstate = state;
	
	// Handle Video Frame
	if (videoFrame) {
		// If 3D mode is enabled we retreive the 3D extensions interface which gives.
		// us access to the right eye frame by calling GetFrameForRightEye() .
		if (nChannels != 2 ||
            videoFrame->QueryInterface(IID_IDeckLinkVideoFrame3DExtensions, (void **) &threeDExtensions) != S_OK ||
            threeDExtensions->GetFrameForRightEye(&rightEyeFrame) != S_OK) {
			rightEyeFrame = nullptr;
		}

        if (mLockL == false) {
            if (videoFrame->GetFlags() & bmdFrameHasNoInputSource) {
                // Frame received but no input signal detected.
                tmpstate = kCaptureState_NoSignal;
            }
            else {
                // YUV >> RGB conversion.
                if (mConversionFrameL == nullptr) {
                    mConversionFrameL = allocateConversionFrame(videoFrame);
                    if (mConversionFrameL) {
                        dispatch_semaphore_wait(mSemaphore_imgL, DISPATCH_TIME_FOREVER);
                        initMatWithVideoFrame(&mImageL, mConversionFrameL);
                        initCIImageWithMat(mCIImageL, &mImageL, mBitmapRepL);
                        dispatch_semaphore_signal(mSemaphore_imgL);
                    } else {
                        // Fail to create a conversion buffer.
                        result = E_FAIL;
                        goto bail_arrived;
                    }
                }
                dispatch_semaphore_wait(mSemaphore_imgL, DISPATCH_TIME_FOREVER);
                HRESULT result = mConversion->ConvertFrame(videoFrame, mConversionFrameL);
                dispatch_semaphore_signal(mSemaphore_imgL);
                switch (result) {
                    case E_FAIL:
                        // YUV >> RGB conversion failed
                        tmpstate = kCaptureState_DeviceError;
                        break;
                    case E_NOTIMPL:
                        // This YUV >> RGB conversion is not implemented
                        tmpstate = kCaptureState_DeviceError;
                        break;
                    default:
                        break;
                }
            }
        }
        if (rightEyeFrame && mLockR == false) {
            if (!(rightEyeFrame->GetFlags() & bmdFrameHasNoInputSource)) {
                // YUV >> RGB conversion.
                if (mConversionFrameR == nullptr) {
                    mConversionFrameR = allocateConversionFrame(rightEyeFrame);
                    if (mConversionFrameR) {
                        dispatch_semaphore_wait(mSemaphore_imgR, DISPATCH_TIME_FOREVER);
                        initMatWithVideoFrame(&mImageR, mConversionFrameR);
                        initCIImageWithMat(mCIImageR, &mImageR, mBitmapRepR);
                        dispatch_semaphore_signal(mSemaphore_imgR);
                    } else {
                        // Fail to create a conversion buffer.
                        tmpstate = kCaptureState_DeviceMemoryError;
                        result = E_FAIL;
                        goto bail_arrived;
                    }
                }
                dispatch_semaphore_wait(mSemaphore_imgR, DISPATCH_TIME_FOREVER);
                result = mConversion->ConvertFrame(rightEyeFrame, mConversionFrameR);
                dispatch_semaphore_signal(mSemaphore_imgR);
                switch (result) {
                    case E_FAIL:
                        // YUV >> RGB conversion failed
                        tmpstate = kCaptureState_DeviceError;
                        break;
                    case E_NOTIMPL:
                        // This YUV >> RGB conversion is not implemented
                        tmpstate = kCaptureState_DeviceError;
                        break;
                    default:
                        break;
                }
            }
        }
    }

bail_arrived:
    if (actAsTimer) capcenter->imagesArrived(this);
    
    if (state != tmpstate) {
        state = tmpstate;
        capcenter->stateChanged(this);
    } else {
        state = tmpstate;
    }
    
    if (rightEyeFrame)
        rightEyeFrame->Release();
    if (threeDExtensions)
        threeDExtensions->Release();
    return result;
}

static CustomDeckLinkVideoFrame *allocateConversionFrame(const IDeckLinkVideoFrame* videoFrame)
{
    CustomDeckLinkVideoFrame *cFrame = nullptr;
    if (videoFrame) {
        long width = const_cast<IDeckLinkVideoFrame *>(videoFrame)->GetWidth();
        long height = const_cast<IDeckLinkVideoFrame *>(videoFrame)->GetHeight();
        cFrame = allocateConversionFrame(width, height);
    }
    return cFrame;
}

static CustomDeckLinkVideoFrame *allocateConversionFrame(long width, long height)
{
    CustomDeckLinkVideoFrame *cFrame = new CustomDeckLinkVideoFrame();
    if (cFrame) {
        if (cFrame->AllocateVideoFrame(width, height, bmdFormat8BitBGRA, bmdVideoOutputFlagDefault) != S_OK) {
            delete cFrame;
            cFrame = nullptr;
        }
    }
    return cFrame;
}


static void initMatWithVideoFrame(cv::Mat *image, const CustomDeckLinkVideoFrame *convFrame)
{
    long width, height, rowBytes;
    void *pfb;
    const_cast<CustomDeckLinkVideoFrame *>(convFrame)->GetBytes(&pfb);
    width = const_cast<CustomDeckLinkVideoFrame *>(convFrame)->GetWidth();
    height = const_cast<CustomDeckLinkVideoFrame *>(convFrame)->GetHeight();
    rowBytes = const_cast<CustomDeckLinkVideoFrame *>(convFrame)->GetRowBytes();
    *image = cv::Mat(height, width, CV_8UC4, pfb, rowBytes);
}

static void initCIImageWithMat(CIImage *img, const cv::Mat* mat, NSBitmapImageRep *bitmapRep)
{
    //@autoreleasepool {
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
/*
    CGSize siz = CGSizeMake(mat->cols, mat->rows);
    NSData *d = [NSData dataWithBytesNoCopy:const_cast<cv::Mat *>(mat)->ptr() length:mat->step*mat->rows*mat->elemSize() freeWhenDone:NO];
    [img initWithBitmapData:d bytesPerRow:mat->step size:siz format:kCI_PIXEL_FMT colorSpace:nil];
 */
    unsigned char *plane = const_cast<cv::Mat *>(mat)->ptr();
    BOOL hasAlpha;
    int bitsPerSample, samplesPerPixel, bitmapFormat;
    switch (mat->type()) {
        case CV_8UC3:
            bitsPerSample = 8;
            samplesPerPixel = 3;
            hasAlpha = NO;
            bitmapFormat = 0;
            break;
        case CV_8UC4:
            bitsPerSample = 8;
            samplesPerPixel = 4;
            hasAlpha = YES;
            bitmapFormat = 0;
            break;
    }
    [bitmapRep initWithBitmapDataPlanes:&plane
                             pixelsWide:mat->cols
                             pixelsHigh:mat->rows
                          bitsPerSample:bitsPerSample
                        samplesPerPixel:samplesPerPixel
                               hasAlpha:hasAlpha
                               isPlanar:NO
                         colorSpaceName:NSCalibratedRGBColorSpace
                           bitmapFormat:bitmapFormat
                            bytesPerRow:mat->step
                           bitsPerPixel:bitsPerSample*samplesPerPixel];
    [img initWithBitmapImageRep:bitmapRep];
    [pool drain];
    //}
}

static CIImage * makeCIImageFromMat(const cv::Mat* mat, NSBitmapImageRep **bitmapRep)
{
    *bitmapRep = [NSBitmapImageRep alloc];
    CIImage *img = [CIImage alloc];
    initCIImageWithMat(img, mat, *bitmapRep);
    return img;
}

/*
static CIImage * CIImageFromVideoFrame(CustomDeckLinkVideoFrame *convFrame)
{
    long width, height, rowBytes;
    void *pfb;
    convFrame->GetBytes(&pfb);
    width = convFrame->GetWidth();
    height = convFrame->GetHeight();
    rowBytes = convFrame->GetRowBytes();
    
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    CGSize siz = CGSizeMake(width, height);
    NSData *d = [NSData dataWithBytesNoCopy:pfb length:(NSUInteger)(rowBytes*height) freeWhenDone:NO];
    CIImage *img = [CIImage imageWithBitmapData:d bytesPerRow:rowBytes size:siz format:kCIFormatARGB8 colorSpace:nil];
    [pool drain];
    return img;
}
*/


HRESULT CaptureDeckLink::VideoInputFormatChanged(BMDVideoInputFormatChangedEvents events, IDeckLinkDisplayMode *mode, BMDDetectedVideoInputFormatFlags)
{
    if (mode) {
        fps = getFrameRate(mode);
        long w = mode->GetWidth();
        long h = mode->GetHeight();
        
        CustomDeckLinkVideoFrame *newFrame = allocateConversionFrame(w, h);
        if (newFrame) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                dispatch_semaphore_wait(mSemaphore_imgL, DISPATCH_TIME_FOREVER);
                CustomDeckLinkVideoFrame *frameToRelease = mConversionFrameL;
                initMatWithVideoFrame(&mImageL, newFrame);
                initCIImageWithMat(mCIImageL, &mImageL, mBitmapRepL);
                mConversionFrameL = newFrame;
                if (frameToRelease)
                    frameToRelease->Release();
                dispatch_semaphore_signal(mSemaphore_imgL);
            });
        } else {
            return E_FAIL;
        }
        if (mConversionFrameR) {
            newFrame = allocateConversionFrame(w, h);
            if (newFrame) {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                    dispatch_semaphore_wait(mSemaphore_imgR, DISPATCH_TIME_FOREVER);
                    CustomDeckLinkVideoFrame *frameToRelease = mConversionFrameR;
                    initMatWithVideoFrame(&mImageR, newFrame);
                    initCIImageWithMat(mCIImageR, &mImageR, mBitmapRepR);
                    mConversionFrameR = newFrame;
                    if (frameToRelease)
                        frameToRelease->Release();
                    dispatch_semaphore_signal(mSemaphore_imgR);
                });
            } else {
                return E_FAIL;
            }
        }
    }
    return S_OK;
}

static float getFrameRate(const IDeckLinkDisplayMode *mode)
{
    if (mode) {
        BMDTimeValue timeValue, timeScale;
        const_cast<IDeckLinkDisplayMode *>(mode)->GetFrameRate(&timeValue, &timeScale);
        return ((float)timeValue)/timeScale;
    }
    else
        return 0.0;
}

bool CaptureDeckLink::init(void)
{
    IDeckLinkDisplayModeIterator *displayModeIterator = nullptr;
    IDeckLinkDisplayMode *displayMode = nullptr;
    bool foundDisplayMode = false;
    
    if (isReady() && isConnected())
        return true;
    
	HRESULT result = E_FAIL;
    CaptureState tmpstate = kCaptureState_Uninitialized;
    
    dispatch_semaphore_wait(mSemaphore_init, DISPATCH_TIME_FOREVER);

    if (deckLinkIterator == nullptr) {
        deckLinkIterator = CreateDeckLinkIteratorInstance();
        if (deckLinkIterator == nullptr) {
            // Perhaps you forget to install the driver.
            tmpstate = kCaptureState_DriverNotFound;
            goto bail;
        }
    }

	/* Connect to the first DeckLink instance */
    if (deckLink == nullptr) {
        CFStringRef cfstr;
        result = deckLinkIterator->Next(&deckLink);
        if (result != S_OK) {
            // Device is not connected.
            // Device not found is not an error for us.
            deckLink = nullptr;
            result = S_OK;
            tmpstate = kCaptureState_DeviceNotFound;
            goto bail; 
        }
        
        // Get model name
        mModelName[0] = '\0';
        result = deckLink->GetModelName(&cfstr);
        if (result == S_OK) {
            if (CFStringGetCString(cfstr, mModelName, kCaptureBufLen, kCFStringEncodingUTF8) == false)
                mModelName[0] = '\0';
        }
    }
    
    if (deckLinkInput == nullptr) {
        result = deckLink->QueryInterface(IID_IDeckLinkInput, (void**)&deckLinkInput);
        if (result != S_OK) {
            // It's not input capable.
            tmpstate = kCaptureState_DeviceNotForCapture;
            goto bail;
        }
        deckLinkInput->SetCallback(this);
    }
 
    // Obtain an IDeckLinkDisplayModeIterator to enumerate the display modes supported on input
    result = deckLinkInput->GetDisplayModeIterator(&displayModeIterator);
    if (result != S_OK) {
        // Could not obtain the video input display mode iterator
        tmpstate = kCaptureState_DeviceError;
        goto bail;
    }
    
    while (displayModeIterator->Next(&displayMode) == S_OK) {
        BMDDisplayMode dMode = displayMode->GetDisplayMode();
        if (dMode == mDisplayMode) {
            BMDDisplayModeSupport modeSupport;
            
            deckLinkInput->DoesSupportVideoMode(dMode, mPixelFormat, bmdVideoInputFlagDefault, &modeSupport, nullptr);
            if (modeSupport == bmdDisplayModeNotSupported) {
                // This combination of the display mode and the pixel format not supported
                tmpstate = kCaptureState_DisplayModeUnsupported;
                result = bmdDisplayModeNotSupported;
                goto bail;
            }
            
            if (mInputFlags & bmdVideoInputDualStream3D) {
                if (!(displayMode->GetFlags() & bmdDisplayModeSupports3D)) {
                    // 3D mode is not supported.
                    tmpstate = kCaptureState_3DUnsupported;
                    goto bail;
                }
                nChannels = 2;
            }

            CFStringRef dstr;
            displayMode->GetName(&dstr);
            CFStringGetCString(dstr, mDisplayModeName, kCaptureBufLen, kCFStringEncodingUTF8);
            
            fps = getFrameRate(displayMode);
            
            foundDisplayMode = true;
            displayMode->Release();
            break;
        }
        displayMode->Release();
    }
    displayModeIterator->Release();
    
    if (!foundDisplayMode) {
        tmpstate = kCaptureState_DisplayModeUnsupported;
        goto bail;
    }
    
    if (deckLinkConfig == nullptr) {
        result = deckLink->QueryInterface(IID_IDeckLinkConfiguration, (void **)&deckLinkConfig);
        if (result != S_OK) {
            // Fail to obtain attribute of the DeckLink device
            tmpstate = kCaptureState_DeviceError;
            goto bail;
        }
        
        if (mInputFlags & bmdVideoInputEnableFormatDetection) {
            /*
             Allowing this needs complex mutex to process VideoInputFormatChanged. Don't do.
            bool flag;
            result = deckLinkConfig->GetFlag(BMDDeckLinkSupportsInputFormatDetection, &flag);
            if (result != S_OK) {
                // Fail to obtain attribute
                tmpstate = kCaptureState_DeviceError;
                goto bail;
            }
            if (flag == false) {
                // This hardware does not support detection of input format change
                // Just we ignore this.
                tmpstate = kCaptureState_DisplayModeUnsupported;
                mInputFlags -= bmdVideoInputEnableFormatDetection;
            }
             */
            mInputFlags -= bmdVideoInputEnableFormatDetection;
        }
    }
    
    result = deckLinkInput->EnableVideoInput(mDisplayMode, mPixelFormat, mInputFlags);
    if (result != S_OK) {
		// Failed to enable video input. Is another application using the DeckLink device?
        tmpstate = kCaptureState_DeviceBusy;
        goto bail;
    }

	// All Okay.
    if (mConversion == nullptr)
        mConversion = CreateVideoConversionInstance();
    tmpstate = kCaptureState_Inactive;

bail:
    dispatch_semaphore_signal(mSemaphore_init);

    bool statehaschanged = (state != tmpstate);
	state = tmpstate;
    if (result == S_OK) {
        if (mStarted == kCaptureState_Activating && state == kCaptureState_Inactive)
            start();
		else if (statehaschanged)
			capcenter->stateChanged(this);
        return true;
    } else {
		if (statehaschanged)
			capcenter->stateChanged(this);
        cleanup();
        return false;
    }
}

void CaptureDeckLink::start()
{
    if (isConnected() && deckLinkInput) {
		CaptureState tmpstate = state;
        if (mStarted != kCaptureState_Active)
            (void) deckLinkInput->StartStreams();
        mStarted = tmpstate = kCaptureState_Active;
		if (state != tmpstate) {
			state = tmpstate;
            capcenter->stateChanged(this); // too noisy?
		}
    } else {
        mStarted = kCaptureState_Activating;
    }
}

void CaptureDeckLink::stop()
{
    if (isConnected() && deckLinkInput) {
		CaptureState tmpstate = state;
        (void) deckLinkInput->StopStreams();
        (void) deckLinkInput->FlushStreams();
        tmpstate = kCaptureState_Inactive;
		if (state != tmpstate) {
			state = tmpstate;
            capcenter->stateChanged(this); // too noisy?
		}
    }
    mStarted = kCaptureState_Inactive;
}

bool CaptureDeckLink::isConnected(void)
{
    if (deckLinkConfig != nullptr) {
        HRESULT result;
        int64_t stub;
        
        result = deckLinkConfig->GetInt(bmdDeckLinkConfigVideoInputConnection, &stub);
        if (result != S_OK) {
            CaptureState tmpstate = kCaptureState_DeviceNotFound;
            if (state != tmpstate) {
                state = tmpstate;
                capcenter->stateChanged(this);
            } else {
                state = tmpstate;
            }
            if (mStarted == kCaptureState_Active)
                mStarted = kCaptureState_Activating;
            cleanup();
            return false;
        }
        else
            return true;
    }
    return false;
}

CIImage* CaptureDeckLink::retrieveCIImage(int channel)
{
    __block CIImage *result;
    if (channel == 0) {
        dispatch_sync(mFilterQ, ^{
            dispatch_semaphore_wait(mSemaphore_imgL, DISPATCH_TIME_FOREVER);
            initCIImageWithMat(mCIImageL, &mImageL, mBitmapRepL);
            [mCMatrix setValue:mCIImageL forKey:kCIInputImageKey];
            result = [mCMatrix valueForKey:kCIOutputImageKey];
            dispatch_semaphore_signal(mSemaphore_imgL);
        });
    } else {
        dispatch_sync(mFilterQ, ^{
            dispatch_semaphore_wait(mSemaphore_imgR, DISPATCH_TIME_FOREVER);
            initCIImageWithMat(mCIImageR, &mImageR, mBitmapRepR);
            [mCMatrix setValue:mCIImageR forKey:kCIInputImageKey];
            result = [mCMatrix valueForKey:kCIOutputImageKey];
            dispatch_semaphore_signal(mSemaphore_imgR);
        });
     }
    return result;
}

cv::Mat& CaptureDeckLink::retrieve(int channel)
{
    if (channel == 0)
        return mImageL;
    else
        return mImageR;
}

bool CaptureDeckLink::lock(int channel)
{
    if (channel == 0) {
        if (mLockL == true)
            return false;
        mLockL = true;
    } else {
        if (mLockR == true)
            return false;
        mLockR = true;
    }
    return true;
}

void CaptureDeckLink::unlock(int channel)
{
    if (channel == 0)
        mLockL = false;
    else
        mLockR = false;
}
