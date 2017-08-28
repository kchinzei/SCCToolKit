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

#include "CaptureUtils.h"
#include "CaptureUtils_private.h"

#include <QObject>
#include <QString>

static QString str;

namespace Cap {
	const QString* CaptureStateStringGenerator::stateQString(CaptureState state, const char *deviceName)
	{
		bool deviceNamed = (deviceName != nullptr && deviceName[0] != '\0');

		switch (state) {
		case kCaptureState_Active:       // started and signal arriving
			if (deviceNamed)
				str = QString(tr("Device %1 currently capturing.")).arg(QString(deviceName));
			else
				str = QString(tr("Device currently capturing."));
			break;

        case kCaptureState_NoSignal:     // started but no signal detected.
			if (deviceNamed)
				str = QString(tr("No signal detected for device %1.")).arg(QString(deviceName));
			else
				str = QString(tr("No signal detected."));
			break;

		case kCaptureState_Activating:   // try starting but wait for init() success
			if (deviceNamed)
				str = QString(tr("Device %1 preparing for capture.")).arg(QString(deviceName));
			else
				str = QString(tr("Device preparing for capture."));
			break;

		case kCaptureState_Inactive:     // stopped
			if (deviceNamed)
				str = QString(tr("Device %1 currently stopped.")).arg(QString(deviceName));
			else
				str = QString(tr("Device currently stopped."));
			break;

		case kCaptureState_Uninitialized: // init() not yet successfully completed
			if (deviceNamed)
				str = QString(tr("Device %1 uninitialized.")).arg(QString(deviceName));
			else
				str = QString(tr("Device uninitialized."));
			break;
        
		case kCaptureState_DriverNotFound:
			if (deviceNamed)
				str = QString(tr("Driver software for %1 is not installed.")).arg(QString(deviceName));
			else
				str = QString(tr("Driver software is not installed."));
			break;

		case kCaptureState_DeviceNotFound:
			if (deviceNamed)
				str = QString(tr("Device %1 is not found.")).arg(QString(deviceName));
			else
				str = QString(tr("Device is not found."));
			break;

		case kCaptureState_DeviceNotForCapture:
			if (deviceNamed)
				str = QString(tr("Device %1 is not capable of capturing.")).arg(QString(deviceName));
			else
				str = QString(tr("Device is not capable of capturing."));
			break;

		case kCaptureState_PixelModeUnsupported:
			if (deviceNamed)
				str = QString(tr("Device %1 does not support specified pixel format.")).arg(QString(deviceName));
			else
				str = QString(tr("Device does not support specified pixel format."));
			break;

		case kCaptureState_DisplayModeUnsupported:
			if (deviceNamed)
				str = QString(tr("Device %1 does not support specified display mode")).arg(QString(deviceName));
			else
				str = QString(tr("Device does not support specified display mode"));
			break;

		case kCaptureState_3DUnsupported:
			if (deviceNamed)
				str = QString(tr("Device %1 does not support 3D mode")).arg(QString(deviceName));
			else
				str = QString(tr("Device does not support 3D mode"));
			break;

		case kCaptureState_DeviceBusy:
			if (deviceNamed)
				str = QString(tr("Device %1 is used by other software.")).arg(QString(deviceName));
			else
				str = QString(tr("Device is used by other software."));
			break;

		case kCaptureState_DeviceMemoryError:
			if (deviceNamed)
				str = QString(tr("Device %1 had memory error.")).arg(QString(deviceName));
			else
				str = QString(tr("Device had memory error."));
			break;

		case kCaptureState_DeviceError:
			if (deviceNamed)
				str = QString(tr("Device %1 had some error.")).arg(QString(deviceName));
			else
				str = QString(tr("Device had some error."));
			break;
		}
		return &str;
	}
};


const QString* captureStateQString(Cap::CaptureState state, const char *deviceName)
{
	static Cap::CaptureStateStringGenerator generator;

	return generator.stateQString(state, deviceName);
}
