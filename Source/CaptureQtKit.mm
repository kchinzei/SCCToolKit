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
#include "CaptureQtKit.h"
#include "CaptureQtKit_private.h"

#include <iostream>

#define kCV_PIXEL_FMT kCVPixelFormatType_32BGRA // Looks like this alone was supported QT. kCVPixelFormatType_422YpCbCr8 also works.
#define kCI_PIXEL_FMT kCIFormatARGB8


static CIImage * makeCIImageFromMat(cv::Mat* mat)
{
    @autoreleasepool {
    //NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    CGSize siz = CGSizeMake(mat->cols, mat->rows);
    NSData *d = [NSData dataWithBytesNoCopy:mat->ptr() length:mat->step*mat->rows*mat->elemSize() freeWhenDone:NO];
    CIImage *img = [[CIImage alloc] initWithBitmapData:d bytesPerRow:mat->step size:siz format:kCI_PIXEL_FMT colorSpace:nil];
    //[pool drain];
    return img;
    }
}

@interface CaptureQtKitDelegate : NSObject

@property(nonatomic) bool lock;
@property(nonatomic) int newFrame;
@property(nonatomic) CVImageBufferRef mCurrentImageBuffer;
@property(nonatomic) cv::Mat* image;
@property(nonatomic, strong) CIImage* ciImage;
@property(nonatomic) Cap::Capture *capture;
@property(nonatomic) Cap::CaptureCenter *capcenter;
@property(nonatomic) BOOL actAsTimer;

- (void)captureOutput:(QTCaptureOutput *) captureOutput
  didOutputVideoFrame:(CVImageBufferRef) videoFrame
     withSampleBuffer:(QTSampleBuffer *) sampleBuffer
       fromConnection:(QTCaptureConnection *) connection;

- (void) captureOutput:(QTCaptureOutput *) captureOutput
didDropVideoFrameWithSampleBuffer:(QTSampleBuffer *) sampleBuffer
        fromConnection:(QTCaptureConnection *) connection;

- (void) updateImage;
- (cv::Mat&) getCvImage;
- (CIImage*) getCIImage;

@end

@implementation CaptureQtKitDelegate

@synthesize lock;
@synthesize newFrame;
@synthesize mCurrentImageBuffer;
@synthesize image, ciImage;
@synthesize capture, capcenter;
@synthesize actAsTimer;

- (id)init {
    self = [super init];
    if (self) {
        self.newFrame = 0;
        self.image = new cv::Mat(480, 640, CV_8UC4);
        self.ciImage = makeCIImageFromMat(self.image);
        self.capture = nullptr;
        self.capcenter = nullptr;
        self.actAsTimer = NO;
    }
    return self;
}

- (void) dealloc {
    CVPixelBufferUnlockBaseAddress(mCurrentImageBuffer, 0);
    CVBufferRelease(mCurrentImageBuffer);
    delete self.image;
    [ciImage release];
    [super dealloc];
}

- (void) captureOutput:(QTCaptureOutput *) captureOutput
   didOutputVideoFrame:(CVImageBufferRef) videoFrame
      withSampleBuffer:(QTSampleBuffer *) sampleBuffer
        fromConnection:(QTCaptureConnection *) connection
{
    (void)captureOutput;
    (void)sampleBuffer;
    (void)connection;
    
    if (self.lock == false) {
        CVImageBufferRef imageBufferToRelease  = self.mCurrentImageBuffer;
        if (imageBufferToRelease != videoFrame) {
            CVBufferRetain(videoFrame);
            CVPixelBufferLockBaseAddress(videoFrame, 0);
        }
        
        @synchronized (self) {
            self.mCurrentImageBuffer = videoFrame;
            self.newFrame = 1;
        }
        
        if (imageBufferToRelease != videoFrame) {
            CVPixelBufferUnlockBaseAddress(imageBufferToRelease, 0);
            CVBufferRelease(imageBufferToRelease);
        }
    }
    
    if (self.actAsTimer)
        self.capcenter->imagesArrived(self.capture);
}

- (void) captureOutput:(QTCaptureOutput *) captureOutput
didDropVideoFrameWithSampleBuffer:(QTSampleBuffer *) sampleBuffer
        fromConnection:(QTCaptureConnection *) connection
{
    (void)captureOutput;
    (void)sampleBuffer;
    (void)connection;
    std::cerr << "Camera dropped frame!" << std::endl;
}

- (void) updateImage {
    if (self.newFrame == 0)
        return;
    
    @synchronized (self) {
        @autoreleasepool {
        self.newFrame = 0;
        
        CVPixelBufferRef pixels = self.mCurrentImageBuffer;
        uint32_t* baseaddress = (uint32_t*)CVPixelBufferGetBaseAddress(pixels);
        
        size_t width = CVPixelBufferGetWidth(pixels);
        size_t height = CVPixelBufferGetHeight(pixels);
        size_t rowBytes = CVPixelBufferGetBytesPerRow(pixels);
        
        if (rowBytes != 0) {
            *(self.image) = cv::Mat(height, width, CV_8UC4, baseaddress, rowBytes);
            ciImage = (CIImage*)[ciImage initWithCVImageBuffer:mCurrentImageBuffer];
        }
        }
    }
}

-(cv::Mat&) getCvImage {
    [self updateImage];
    return *(self.image);
}

- (CIImage*) getCIImage
{
    [self updateImage];
    return ciImage;
}

@end









using namespace cv;
using namespace Cap;

static const char* kCaptureQtKit_excludeModelNameList[] = {
    "Blackmagic",
    nullptr
};
static const char* kCaptureQtKit_internalCameraNameList[] = {
    "FaceTime",
    "iSight",
    nullptr
};

static bool nameContainsExcludeModelName(const NSString* str, bool useInternalCameras)
{
    @autoreleasepool {
    bool result = false;
    //NSAutoreleasePool* localpool = [[NSAutoreleasePool alloc] init];

    for (const char* *p=kCaptureQtKit_excludeModelNameList; *p!=nullptr; p++) {
        NSString *excludeModelName = [NSString stringWithUTF8String:*p];
        result = [str hasPrefix:excludeModelName];
        if (result) goto name_match;
        result = [str hasSuffix:excludeModelName];
        if (result) goto name_match;
    }
    for (const char* *p=kCaptureQtKit_internalCameraNameList; *p!=nullptr && !useInternalCameras; p++) {
        NSString *excludeModelName = [NSString stringWithUTF8String:*p];
        result = [str hasPrefix:excludeModelName];
        if (result) goto name_match;
        result = [str hasSuffix:excludeModelName];
        if (result) goto name_match;
    }
name_match:
    //[localpool drain];
    return result;
    }
}

CaptureQtKit::CaptureQtKit()
    : Capture()
    , mUseInternalCameras(false)
    , mCameraID(-1)
    , mStarted(kCaptureState_Inactive)
    , fps(0)
    , mLock(false)
{
    mModelName[0] = '\0';
    priv = new CaptureQtKit_private;

    static int cameraIndexPool;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        cameraIndexPool = 0;
    });
    mCameraID = cameraIndexPool++;
}

CaptureQtKit::~CaptureQtKit()
{
    stop();
    cleanup();
    [priv->capture release];
    dispatch_release(priv->mSemaphore);
    delete priv;
}

void CaptureQtKit::cleanup()
{
    @autoreleasepool {
    //NSAutoreleasePool* localpool = [[NSAutoreleasePool alloc] init];
    
    [priv->mCaptureSession stopRunning];
    
    QTCaptureDevice *device = [priv->mCaptureDeviceInput device];
    if ([device isOpen])  [device close];
    
    [priv->mCaptureSession release];
    [priv->mCaptureDeviceInput release];
    
    [priv->mCaptureDecompressedVideoOutput setDelegate:priv->mCaptureDecompressedVideoOutput];
    [priv->mCaptureDecompressedVideoOutput release];
    //[localpool drain];
    
    priv->mCaptureSession = nil;
    priv->mCaptureDeviceInput = nil;
    priv->mCaptureDecompressedVideoOutput = nil;
    }
}

bool CaptureQtKit::init(void)
{
    // This we did at every invocation of init() as there's no other occasion to do it. Load is negligeable.
    priv->capture.capcenter  = capcenter;
    priv->capture.capture    = this;
    priv->capture.actAsTimer = actAsTimer;

    // Assumption: if hardware is connected and
    if (isReady() && isConnected())
        return true;
    
    @autoreleasepool {
    //NSAutoreleasePool* localpool = [[NSAutoreleasePool alloc] init];
    
    dispatch_semaphore_wait(priv->mSemaphore, DISPATCH_TIME_FOREVER);

    CaptureState tmpstate = state;
    bool result = true;
    // int cameraNum = 0;

    NSError                     *error = nil;
    NSArray                     *devices;
    QTCaptureDevice             *device = nil;
    NSDictionary                *pixelBufferOptions;

    if (priv->capture == nil)
        priv->capture = [[CaptureQtKitDelegate alloc] init];
        
    device = [priv->mCaptureDeviceInput device];
    if (device == nil) {
        if (mUniqueID[0] != '\0') {
            NSString *uniqueID = [NSString stringWithCString:mUniqueID encoding:NSASCIIStringEncoding];
            device = [QTCaptureDevice deviceWithUniqueID:uniqueID];
            if (device == nil || [device isConnected] == false) {
                // Specified device is not connected or found at all.
                tmpstate = kCaptureState_DeviceNotFound;
                result = true;
                goto bail;
            }
        } else {
            /*
             Look for mCameraID'th device that IS NOT OPENED NOR USED BY OTHER APP.
             */
            devices = [[QTCaptureDevice inputDevicesWithMediaType:QTMediaTypeVideo]
                       arrayByAddingObjectsFromArray:[QTCaptureDevice inputDevicesWithMediaType:QTMediaTypeMuxed]];
            
            if ([devices count] == 0) {
                // QTKit didn't find any attached Video Input Devices
                tmpstate = kCaptureState_DeviceNotFound;
                result = true;
                goto bail;
            }
            
            for (QTCaptureDevice *d in devices) {
                //NSLog(@"Device id = %@, name = %@", [d uniqueID], [d localizedDisplayName]);
                // FIXME: 130622 K. Chinzei; I forget why I had the following one line. Just comment out.
                //if (cameraNum++ < mCameraID) continue;
                if (![d isOpen] && ![d isInUseByAnotherApplication] && !nameContainsExcludeModelName([d localizedDisplayName], mUseInternalCameras)
) {
                    device = d;
                    break;
                }
            }
            if (device == nil) {
                // No free Video Input Devices found.
                tmpstate = kCaptureState_DeviceNotFound;
                result = true;
                goto bail;
            }
        }
    }
    if (![device isOpen]) {
        result = [device open:&error];
        if (!result) {
            // QTKit failed to open a Video Capture Device, even thouth there is one
            tmpstate = kCaptureState_DeviceError;
            result = false;
            goto bail;
        }
    }
    
    if (priv->mCaptureDeviceInput == nil)
        priv->mCaptureDeviceInput = [[QTCaptureDeviceInput alloc] initWithDevice:device] ;
    else if ([priv->mCaptureDeviceInput device] != device)
        priv->mCaptureDeviceInput = [priv->mCaptureDeviceInput initWithDevice:device] ;

    if (priv->mCaptureSession == nil)
        priv->mCaptureSession = [[QTCaptureSession alloc] init] ;
    result = [priv->mCaptureSession addInput:priv->mCaptureDeviceInput error:&error];
    if (result == false) {
        // QTKit failed to start capture session with opened Capture Device
        tmpstate = kCaptureState_DeviceError;
        goto bail;
    }
    
    if (priv->mCaptureDecompressedVideoOutput == nil) {
        priv->mCaptureDecompressedVideoOutput = [[QTCaptureDecompressedVideoOutput alloc] init];
        [priv->mCaptureDecompressedVideoOutput setDelegate:priv->capture];
        if (desiredWidth > 0 && desiredHeight > 0) {
            pixelBufferOptions = [NSDictionary dictionaryWithObjectsAndKeys:
                                  [NSNumber numberWithDouble:1.0*desiredWidth],  (id)kCVPixelBufferWidthKey,
                                  [NSNumber numberWithDouble:1.0*desiredHeight], (id)kCVPixelBufferHeightKey,
                                  [NSNumber numberWithUnsignedInt:kCV_PIXEL_FMT], (id)kCVPixelBufferPixelFormatTypeKey,
                                  nil];
        } else {
            pixelBufferOptions = [NSDictionary dictionaryWithObjectsAndKeys:
                                  [NSNumber numberWithUnsignedInt:kCV_PIXEL_FMT], (id)kCVPixelBufferPixelFormatTypeKey,
                                  nil];
        }
        [priv->mCaptureDecompressedVideoOutput setPixelBufferAttributes:pixelBufferOptions];
        [priv->mCaptureDecompressedVideoOutput setAutomaticallyDropsLateVideoFrames:YES];
    }
    
    result = [priv->mCaptureSession addOutput:priv->mCaptureDecompressedVideoOutput error:&error];
    if (result == false) {
        // QTKit failed to add Output to Capture Session
        tmpstate = kCaptureState_DeviceError;
        goto bail;
    }
    tmpstate = kCaptureState_Inactive;

    [[device uniqueID] getCString:mUniqueID
                        maxLength:kCaptureBufLen
                         encoding:NSASCIIStringEncoding];
    [[device localizedDisplayName] getCString:mModelName
                                    maxLength:kCaptureBufLen
     // FIXME : thhis may cause mojibake.
                                     //encoding:NSShiftJISStringEncoding];
                                     encoding:NSUTF8StringEncoding];

bail:
	dispatch_semaphore_signal(priv->mSemaphore);
    //[localpool drain];

	bool statehaschanged = (state != tmpstate);
	state = tmpstate;
    if (result == true) {
        if (mStarted == kCaptureState_Activating && state == kCaptureState_Inactive)
            start();
		else if (statehaschanged)
			capcenter->stateChanged(this);

        // Basically Success (device may not be connected)

        // We must do it after drain. We want to keep uniqueID.

        // Below for debugging.
        /*
        NSArray *formats = [device formatDescriptions];
        for (QTFormatDescription *fd in formats) {
            NSLog(@"Model = %s", mModelName);
            NSString *s = [fd localizedFormatSummary];
            NSLog(@"Format = %@", s);
        }
         */
        return true;
    } else {
        // Something incomplete.
		if (statehaschanged)
			capcenter->stateChanged(this);
        cleanup();
        return false;
    }
    }
}

void CaptureQtKit::start()
{
    if (isReady() && isOpen()) {
		CaptureState tmpstate = state;
        if (mStarted != kCaptureState_Active)
            [priv->mCaptureSession startRunning];
        if ([priv->mCaptureSession isRunning])
            mStarted = tmpstate = kCaptureState_Active;
        else {
            mStarted = kCaptureState_Activating;
            tmpstate = kCaptureState_DeviceError;
        }
		if (state != tmpstate) {
			state = tmpstate;
            capcenter->stateChanged(this); // too noisy?
		}
    } else {
        mStarted = kCaptureState_Activating;
    }
}

void CaptureQtKit::stop()
{
	CaptureState tmpstate = state;
    if (isReady() && isOpen()) {
        [priv->mCaptureSession stopRunning];
        tmpstate = kCaptureState_Inactive;
    }
	if (state != tmpstate) {
		state = tmpstate;
		capcenter->stateChanged(this); // too noisy?
	}
    mStarted = kCaptureState_Inactive;
}

bool CaptureQtKit::isConnected(void)
{
    @autoreleasepool {
//    NSAutoreleasePool* localpool = [[NSAutoreleasePool alloc] init];
    QTCaptureDevice *device = [priv->mCaptureDeviceInput device];
    bool result = [device isConnected] && ![device isInUseByAnotherApplication];
//    [localpool drain];

    if (result == false) {
        CaptureState tmpstate = kCaptureState_DeviceNotFound;
        if (mStarted == kCaptureState_Active)
            mStarted = kCaptureState_Activating;
        if (state != tmpstate) {
            state = tmpstate;
            capcenter->stateChanged(this);
        }
        cleanup();
    }
    return result;
    }
}

bool CaptureQtKit::isOpen(void)
{
    QTCaptureDevice *device = [priv->mCaptureDeviceInput device];
    return [device isOpen];
}

Mat& CaptureQtKit::retrieve(int channel)
{
    return [priv->capture getCvImage];
}

CIImage* CaptureQtKit::retrieveCIImage(int channel)
{
    return [priv->capture getCIImage];
}

bool CaptureQtKit::lock(int channel)
{
    if (mLock == true)
        return false;
    mLock = true;
    priv->capture.lock = true;
    return true;
}

void CaptureQtKit::unlock(int channel)
{
    mLock = false;
    priv->capture.lock = false;
}

void CaptureQtKit::setDesiredSize(int dWidth, int dHeight)
{
    if (dWidth > 0 && dHeight > 0) {
        @autoreleasepool {
        //NSAutoreleasePool* localpool = [[NSAutoreleasePool alloc] init];
        NSDictionary* pixelBufferOptions = [NSDictionary dictionaryWithObjectsAndKeys:
                                            [NSNumber numberWithDouble:1.0*dWidth],  (id)kCVPixelBufferWidthKey,
                                            [NSNumber numberWithDouble:1.0*dHeight], (id)kCVPixelBufferHeightKey,
                                            [NSNumber numberWithUnsignedInt:kCV_PIXEL_FMT], (id)kCVPixelBufferPixelFormatTypeKey,
                                            nil];
        
        [priv->mCaptureDecompressedVideoOutput setPixelBufferAttributes:pixelBufferOptions];
        //[localpool drain];
        desiredWidth = dWidth;
        desiredHeight = dHeight;
        }
    }
}

void CaptureQtKit::setDesiredWidth(int dWidth)
{
    if (dWidth > 0) {
        @autoreleasepool {
		float w = 0;
		float h = 0;
		int dHeight = 0;
		
        //NSAutoreleasePool* localpool = [[NSAutoreleasePool alloc] init];
        NSDictionary* pixelBufferOptions = [priv->mCaptureDecompressedVideoOutput pixelBufferAttributes];	
		if (pixelBufferOptions != nil) {
			NSNumber *wNum = [pixelBufferOptions valueForKey:(NSString *)kCVPixelBufferWidthKey];
			NSNumber *hNum = [pixelBufferOptions valueForKey:(NSString *)kCVPixelBufferHeightKey];
			if (wNum != nil) w = [wNum floatValue];
			if (hNum != nil) h = [hNum floatValue];
		}
		//[localpool drain];

		if (w != 0 && h != 0) {
			// dWidth : dHeight = w : h
			dHeight = dWidth * h / w;
		} else {
			dHeight = dWidth * (float) desiredHeight / desiredWidth;
		}
		setDesiredSize(dWidth, dHeight);
        }
    }
}

void CaptureQtKit::setDesiredHeight(int dHeight)
{
	if (dHeight > 0) {
        @autoreleasepool {
		float w = 0;
		float h = 0;
		int dWidth = 0;
		
        //NSAutoreleasePool* localpool = [[NSAutoreleasePool alloc] init];
        NSDictionary* pixelBufferOptions = [priv->mCaptureDecompressedVideoOutput pixelBufferAttributes];	
		if (pixelBufferOptions != nil) {
			NSNumber *wNum = [pixelBufferOptions valueForKey:(NSString *)kCVPixelBufferWidthKey];
			NSNumber *hNum = [pixelBufferOptions valueForKey:(NSString *)kCVPixelBufferHeightKey];
			if (wNum != nil) w = [wNum floatValue];
			if (hNum != nil) h = [hNum floatValue];
		}
		//[localpool drain];

		if (w != 0 && h != 0) {
			// dWidth : dHeight = w : h
			dWidth = dHeight * w / h;
		} else {
			dWidth = dHeight * (float) desiredWidth / desiredHeight;
		}
		setDesiredSize(dWidth, dHeight);
        }
    }
}
