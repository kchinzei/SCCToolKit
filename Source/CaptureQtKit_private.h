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

#ifndef _CaptureQtKit_private_h
#define _CaptureQtKit_private_h

#import <QTKit/QTKit.h>
#include <dispatch/dispatch.h>

@class CaptureQtKitDelegate;

namespace Cap {
    struct CaptureQtKit_private {
        QTCaptureSession            *mCaptureSession;
        QTCaptureDeviceInput        *mCaptureDeviceInput;
        QTCaptureDecompressedVideoOutput *mCaptureDecompressedVideoOutput;
        CaptureQtKitDelegate        *capture;
        
        dispatch_semaphore_t mSemaphore;
        
        CaptureQtKit_private ()
            : mCaptureSession(nil)
            , mCaptureDeviceInput(nil)
            , mCaptureDecompressedVideoOutput(nil)
            , capture(nil)
        {
            mSemaphore = dispatch_semaphore_create(1);
        };
    };
}

#endif
