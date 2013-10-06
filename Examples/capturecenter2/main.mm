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

#include <QtGui>
#include <QtDebug>
#include "opencv2/video/tracking.hpp"
#include "opencv2/imgproc/imgproc.hpp"
#include "opencv2/highgui/highgui.hpp"

#include <iostream>
#include <ctype.h>
#include <strings.h>
#include <vector>

#include <unistd.h>

#include "CaptureCenter.h"
#include "Capture.h"
#include "CaptureUtils.h"

#include <dispatch/dispatch.h>

extern int opterr;
extern int optind;
extern char *optarg;
char *progname;
double w = 640, h = 480, f = 10;

using namespace cv;

static void usage(const char *progname)
{
    fprintf(stderr,
			"%s [-options]\n"
            "   [-w width]    default=%lf\n"
            "   [-h height]   default=%lf\n"
            "   [-f FPS]      default=%lf\n", progname, w, h, f
            );
}

using namespace Cap;
std::vector<char *> windownames;
int nCaptures = 0;

/*
 Implement CaptureCenter.
 */
namespace Cap {
    class myCaptureCenter : public CaptureCenter {
        void imagesArrived(Capture *capture);
        void stateChanged(Capture* capture);
    };
};

void myCaptureCenter::imagesArrived(Capture *capture)
{
    CapturePtrVec::iterator cap = captures.begin();
    std::vector<char *>::iterator windowname = windownames.begin();
    
    while (cap != captures.end()) {
        int nChannels = (*cap)->getNChannels();
        for (int n=0; n<nChannels; n++) {
            char *wname = *windowname++;
            cv::Mat frame = (*cap)->retrieve(n);
            dispatch_async(dispatch_get_main_queue(), ^{
                (*cap)->lock();
                imshow(wname, frame);
                (*cap)->unlock();
            });
        }
        cap++;
    }
}

void myCaptureCenter::stateChanged(Cap::Capture* capture)
{
    const QString* str = captureStateQString(capture->state, capture->mModelName);
    qDebug() << *str;
}


int main (int argc, char **argv)
{
    // It is to explicitly run the event loop -- see the bottom of main()
    QApplication app(argc,argv);

    // Analyze command options.
	if ((progname = rindex(argv[0], '/')) != nullptr)
		progname++;
    else
		progname = argv[0];
    
    int ch;
    opterr = 0;
    while ((ch = getopt(argc, argv, "?h:w:f:")) != -1) {
        switch (ch) {
            case 'h':
                h = atoi(optarg);
                break;
            case 'w':
                w = atoi(optarg);
                break;
            case 'f':
                f = atoi(optarg);
                break;
            default:
                usage(progname);
                exit(0);
        }
    }
    
#define BUFLEN 1024
    char winnamebuf[BUFLEN];
    char *p = winnamebuf;

    //////////////////////////////////////////////////////////////////
    // Start
    myCaptureCenter capcenter;
    capcenter.setDesiredFPS(f);
    
    for (int i=0; i<2; i++) {
        Capture *cap;
        if (i == 0)
            cap = capcenter.addCapture(kCaptureTypeDeckLink);
        else
            cap = capcenter.addCapture(kCaptureTypeQtKit);
        if (cap == nullptr) {
            std::cerr << "Fail to create capture #" << i << std::endl;
            return -1-i;
        }
        if (cap->init() == false) {
            std::cerr << "Fail to open capture #" << i << std::endl;
            return -1-i;
        }
        std::cerr << "Capture[" << i << "] : " << cap->mModelName << std::endl;
        cap->setDesiredSize(w, h);
        int nChannels = cap->getNChannels();
        
        // Prepare window name
        for (int n=0; n<nChannels; n++) {
            windownames.push_back(p);
            char buf[1024];
            sprintf(buf, "Cap %d (%d)", i, n+1);
            strlcpy(p, buf, BUFLEN-(p-winnamebuf)-1);
            p += (strnlen(buf, 1024) + 1);
        }
        nCaptures += nChannels;
    }
    
    // Prepare window
    for (int i=0; i<nCaptures; i++) {
        namedWindow(windownames[i], CV_WINDOW_AUTOSIZE);
    }
    
    capcenter.start();
	app.exec();
    capcenter.stop();
    return 0;
}
