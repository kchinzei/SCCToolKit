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

#import "QCvGLWidget_private.h"
#import <AppKit/NSOpenGL.h>

#define kClearCounterMax 1

@interface QCvGLWidget_CIImageDrower()
@property (nonatomic, strong) CIContext *context;
@property (nonatomic) int clearCounter;
//@property (nonatomic) int debugCounter;
@end

@implementation QCvGLWidget_CIImageDrower
@synthesize context;
@synthesize clearCounter;
//@synthesize debugCounter;

- (id) init {
    self = [super init];
    if (self) {
        {
            /*
            const NSOpenGLPixelFormatAttribute attr[] = {
                NSOpenGLPFAAccelerated,
                NSOpenGLPFANoRecovery,
                NSOpenGLPFAColorSize, 32,
#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_5
                NSOpenGLPFAAllowOfflineRenderers,  // allow use of offline renderers
#endif
                0
            };
            NSOpenGLPixelFormat *pf = [[NSOpenGLPixelFormat alloc] initWithAttributes:(void *)attr];
            context = [CIContext contextWithCGLContext: CGLGetCurrentContext()
                                           pixelFormat: [pf CGLPixelFormatObj]
                                            colorSpace: nil
                                               options: nil];
            */
            CGLContextObj co = CGLGetCurrentContext();
            CGLPixelFormatObj pfo = CGLGetPixelFormat(co);
            context = [CIContext contextWithCGLContext: co
                                           pixelFormat: pfo
                                            colorSpace: nil
                                               options: nil];
            // contextWithCGLContext:pixelFormat:colorSpace:options: ref says don't release pf.
            // [pf release];
            clearCounter = 0;
//            debugCounter = 0;
        }
    }
    return self;
}

/*
- (void) dealloc {
    [context release];
    [super dealloc];
}
*/

- (void) drawImageWithScaleToFill:(CIImage *) ciImage
                           inRect:(CGRect)destRect
                    withPointSize:(float)pointSize
{
    CGRect imgRect = [ciImage extent];

    float dx = - imgRect.origin.x;
    float dy = - imgRect.origin.y;
    if (dx > 0) {
        imgRect.origin.x = 0;
        imgRect.size.width -= 2*dx;
    }
    if (dy > 0) {
        imgRect.origin.y = 0;
        imgRect.size.height -= 2*dy;
    }

    destRect.size.width  *= pointSize;
    destRect.size.height *= pointSize;
    [context drawImage:ciImage inRect:destRect fromRect:imgRect];
    
    if (clearCounter++ > kClearCounterMax) {
        [context clearCaches];
        clearCounter = 0;
    }
//    debugCounter++;
}

- (void) drawImageWithoutScaling:(CIImage *) ciImage
                          inRect:(CGRect)destRect
                   withPointSize:(float)pointSize
{
    CGRect inRect, frRect;
    CGRect imgRect = [ciImage extent];

    float dx = - imgRect.origin.x;
    float dy = - imgRect.origin.y;
    if (dx > 0) {
        imgRect.origin.x = 0;
        imgRect.size.width -= 2*dx;
    }
    if (dy > 0) {
        imgRect.origin.y = 0;
        imgRect.size.height -= 2*dy;
    }

    int w = imgRect.size.width;
    int h = imgRect.size.height;
    
    int x = (destRect.size.width - w) / 2;
    if (x >= 0) {
        inRect.origin.x = x*pointSize;
        frRect.origin.x = 0;
        inRect.size.width = w * pointSize;
        frRect.size.width = w;
    } else {
        inRect.origin.x = 0;
        frRect.origin.x = -x;
        inRect.size.width = destRect.size.width * pointSize;
        frRect.size.width = destRect.size.width;
    }
    int y = (destRect.size.height - h) / 2;
    if (y >= 0) {
        inRect.origin.y = y * pointSize;
        frRect.origin.y = 0;
        inRect.size.height = h * pointSize;
        frRect.size.height = h;
    } else {
        inRect.origin.y = 0;
        frRect.origin.y = -y;
        inRect.size.height = destRect.size.height * pointSize;
        frRect.size.height = destRect.size.height;
    }
    [context drawImage:ciImage inRect:inRect fromRect:frRect];
    
    if (clearCounter++ > kClearCounterMax) {
        [context clearCaches];
        clearCounter = 0;
    }
    //    debugCounter++;
}

- (void) drawImageWithScaleAspectFit:(CIImage *) ciImage
                              inRect:(CGRect)destRect
                       withPointSize:(float)pointSize
{
    CGRect imgRect = [ciImage extent];
    
    float dx = - imgRect.origin.x;
    float dy = - imgRect.origin.y;
    if (dx > 0) {
        imgRect.origin.x = 0;
        imgRect.size.width -= 2*dx;
    }
    if (dy > 0) {
        imgRect.origin.y = 0;
        imgRect.size.height -= 2*dy;
    }
    
    double rw = (double) destRect.size.width / imgRect.size.width;
    double rh = (double) destRect.size.height/ imgRect.size.height;
    
    if (rw < rh) {
        float h =  destRect.size.height;
        destRect.size.height = imgRect.size.height * rw;
        destRect.origin.y    = (h - destRect.size.height)/2;
    } else {
        float w = destRect.size.width;
        destRect.size.width  = imgRect.size.width * rh;
        destRect.origin.x    = (w - destRect.size.width) / 2;
    }
    destRect.origin.x *= pointSize;
    destRect.origin.y *= pointSize;
    destRect.size.width  *= pointSize;
    destRect.size.height *= pointSize;
    [context drawImage:ciImage inRect:destRect fromRect:imgRect];
    
    if (clearCounter++ > kClearCounterMax) {
        [context clearCaches];
        clearCounter = 0;
    }
}

- (void) drawImageWithScaleAspectFill:(CIImage *) ciImage
                               inRect:(CGRect)destRect
                        withPointSize:(float)pointSize
{
    CGRect imgRect = [ciImage extent];

    float dx = - imgRect.origin.x;
    float dy = - imgRect.origin.y;
    if (dx > 0) {
        imgRect.origin.x = 0;
        imgRect.size.width -= 2*dx;
    }
    if (dy > 0) {
        imgRect.origin.y = 0;
        imgRect.size.height -= 2*dy;
    }

    double rw = (double) imgRect.size.width  / destRect.size.width;
    double rh = (double) imgRect.size.height / destRect.size.height;
    
    if (rw < rh) {
        float h = imgRect.size.height;
        imgRect.size.height = destRect.size.height * rw;
        imgRect.origin.y    = (h - imgRect.size.height) / 2;
    } else {
        float w = imgRect.size.width;
        imgRect.size.width  = destRect.size.width * rh;
        imgRect.origin.x    = (w - imgRect.size.width) / 2;
    }
    destRect.origin.x *= pointSize;
    destRect.origin.y *= pointSize;
    destRect.size.width  *= pointSize;
    destRect.size.height *= pointSize;
    [context drawImage:ciImage inRect:destRect fromRect:imgRect];
    
    if (clearCounter++ > kClearCounterMax) {
        [context clearCaches];
        clearCounter = 0;
    }
}

@end
