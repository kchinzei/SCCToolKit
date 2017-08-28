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

/**
 * @file
 */

#ifndef APPLICATIONSTATUH_H_
#define APPLICATIONSTATUH_H_

struct ApplicationStatus
{
    bool adjustChromaMode;
    float desiredFPS;
    float hueMin, hueMax, valMin, valMax;

	ApplicationStatus()
    : adjustChromaMode(false)
    , desiredFPS(0)
    , hueMin(180)
    , hueMax(260)
    , valMin(3)
    , valMax(252)
		{}
};

#endif // APPLICATIONSTATUH_H_

