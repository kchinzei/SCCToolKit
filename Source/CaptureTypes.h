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

#ifndef __CaptureTypes__
#define __CaptureTypes__

namespace Cap {
    enum CaptureType {
        kCaptureTypeUndefined = 0,
        kCaptureTypeOpenCV,
        kCaptureTypeQtKit,
        kCaptureTypeDeckLink
    };

    enum CaptureState {
        // Note that isReady(), isConnected() depends on the order of these definitions.
        kCaptureState_Active = 0,       // started and signal arriving
        kCaptureState_NoSignal,         // started but no signal detected.
        kCaptureState_Activating,       // try starting but wait for init() success
        kCaptureState_Inactive,         // stopped
        kCaptureState_Uninitialized,    // init() not yet successfully completed
        
        kCaptureState_DriverNotFound,
        kCaptureState_DeviceNotFound,
        kCaptureState_DeviceNotForCapture,
        kCaptureState_PixelModeUnsupported,
        kCaptureState_DisplayModeUnsupported,
        kCaptureState_3DUnsupported,
        kCaptureState_DeviceBusy,
        kCaptureState_DeviceMemoryError,
        kCaptureState_DeviceError
    };
    
    enum PaintMode {
        kPaintModeNoScalling,       ///< No scaling. The content is painted at the center of the view. The content may be clipped if necessary.
        kPaintModeScaleToFill,      ///< Scales the content to fit the size of itself by changing the aspect ratio of the content if necessary.
        kPaintModeScaleAspectFit,  ///< Scales the content to fit the size of the view by maintaining the aspect ratio. Remaining area is not painted.
        kPaintModeScaleAspectFill  ///< Scales the content to fill the size of the view. Some portion of the content may be clipped to fill the view’s bounds.
    };
};

#endif
