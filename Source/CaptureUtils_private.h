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

#ifndef __CaptureUtils_private__
#define __CaptureUtils_private__

#include <QObject>
#include <QString>

#include "CaptureUtils.h"

namespace Cap {
	class CaptureStateStringGenerator : public QObject
	{
		Q_OBJECT

		public:
		CaptureStateStringGenerator() {};
		~CaptureStateStringGenerator() {};
		const QString* stateQString(CaptureState state, const char *deviceName);
	};
};

#endif
