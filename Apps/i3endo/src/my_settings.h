/*=========================================================================

  This software is distributed WITHOUT ANY WARRANTY; without even
  the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
  PURPOSE.  See the above copyright notices for more information.

=========================================================================*/

#ifndef _SETTINGS_H_
#define _SETTINGS_H_

/*
  These definitions are used in QSettings class.
  http://doc.qt.nokia.com/4.6/qsettings.html
 */

// Used before construct QSettings.
#define kSettingsKey_Organization		"Intelligent Surgical Instruments Project"
#define kSettingsKey_Domain				"intelli-si.org"
#define kSettingsKey_Application		"cvstereoqt"

// OpenCV properties
#define kSettingsKey_CameraName			"OpenCV/CameraName"
#define kSettingsKey_CameraIndex		"OpenCV/CameraIndex"

// Decklink Properties
#define kSettingsKey_DeckLink_DeviceName    "DeckLink/DeviceName"
#define kSettingsKey_DeckLink_InputFormat   "DeckLink/InputFormat"
#define kSettingsKey_DeckLink_InputPixel    "DeckLink/InputPixel"

#define kSettingsKey_AlgorithmIndex     "algorithmIndex"
#define kSettingsKey_nCouncurrentTasks  "nCouncurrentTasks"

#endif
