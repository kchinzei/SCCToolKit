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

#ifndef _SETTINGS_H_
#define _SETTINGS_H_

/*
  These definitions are used in QSettings class.
  http://doc.qt.nokia.com/4.6/qsettings.html
 */

// Used before construct QSettings.
#define kSettingsKey_Organization		"Small Computings for Clinicals"
#define kSettingsKey_Domain				"aist.go.jp"
#define kSettingsKey_Application		"chromakey2"

// CaptureCenter properties
#define kSettingsKey_Cap_DesiredFPS     "Cap/DesiredFPS"

// UniqueID is used as an array. See QSettings::beginReadArray()
#define kSettingsKey_Capture            "Capture"
#define kSettingsKey_Cap_CaptureType    "CaptureType"
#define kSettingsKey_Cap_UniqueIDStr    "UniqueID"

#define kSettingsKey_ChromaHueMin       "Chroma/HueMin"
#define kSettingsKey_ChromaHueMax       "Chroma/HueMax"
#define kSettingsKey_ChromaValMin       "Chroma/ValMin"
#define kSettingsKey_ChromaValMax       "Chroma/ValMax"

#endif
