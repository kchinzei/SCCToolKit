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

#include "Capture.h"

Cap::Capture::Capture()
        : state(kCaptureState_Uninitialized)
        , desiredWidth(640)
        , desiredHeight(480)
        , actAsTimer(false)
        , capcenter(nullptr)
{
    mModelName[0] = '\0';
    mUniqueID[0]  = '\0';
}

void Cap::Capture::setDesiredSize(int dWidth, int dHeight)
{
    desiredWidth = dWidth;
    desiredHeight = dHeight;
};

void Cap::Capture::setDesiredWidth(int dWidth)
{
    desiredWidth = dWidth;
}

void Cap::Capture::setDesiredHeight(int dHeight)
{
    desiredHeight = dHeight;
}

long Cap::Capture::getDesiredWidth()
{
    return desiredWidth;
}

long Cap::Capture::getDesiredHeight()
{
    return desiredHeight;
}

void Cap::Capture::setActAsTimer(bool asTimer)
{
    actAsTimer = asTimer;
}

void Cap::Capture::setCaptureCenter(Cap::CaptureCenter *cc)
{
    capcenter = cc;
};
