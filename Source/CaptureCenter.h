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

#ifndef ____CaptureCenter__
#define ____CaptureCenter__

#include "Capture.h"
#include <vector>

namespace Cap {
    typedef std::vector<Cap::Capture*> CapturePtrVec;
    	
    class CaptureCenter {
        friend class Capture;
        
    public:
        CaptureCenter();
        ~CaptureCenter();
        Capture* addCapture(CaptureType capture_type);
        void start(void);
        void stop(void);

		void setDesiredFPS(float FPS);
		float getDesiredFPS();
		float getFPS();
        
        virtual void imagesArrived(Cap::Capture* capture) {};
        virtual void stateChanged(Cap::Capture* capture) {};

    protected:
        CapturePtrVec captures;
        bool useSoftwareTimer;
        Capture *activeTimer;
        void periodicActivation(void);
    private:
    };
};

#endif /* defined(____CaptureCenter__) */
