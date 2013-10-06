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
#include "opencv2/highgui/highgui.hpp"

#include <iostream>
#include <ctype.h>
#include <strings.h>
#include <vector>

#include <unistd.h>

#include "CaptureCenter.h"
#include "Capture.h"
#include "CaptureUtils.h"
#include "CaptureQtKit.h"
#import "CvChromakey.h"
#include "QCvGLWidget.h"
#include <dispatch/dispatch.h>

extern int opterr;
extern int optind;
extern char *optarg;
char *progname;
double w = 640, h = 480, f = 5;
int minHueAngle = 220;
int maxHueAngle = 300;
int minValue = 20;

#define nCameras 2

static void usage(const char *progname)
{
    fprintf(stderr,
			"%s [-options]\n"
            "   [-w width]    default=%lf\n"
            "   [-h height]   default=%lf\n"
            "   [-f FPS]      default=%lf\n"
            "   [-m minHueDeg] (0-360) default=%d\n"
            "   [-M maxHueDeg] (0-360) default=%d\n"
            "   [-v minValue] (0-255) default=%d"
            "   [-u] Use internal cameras. default=false\n"
            , progname, w, h, f, minHueAngle, maxHueAngle, minValue
            );
}

dispatch_group_t group;
dispatch_queue_t mainq;

using namespace Cap;
using namespace cv;

CvChromakey *chromakey = nil;
QCvGLWidget *pwidget;

#define kForeImageWindowName "Image 1"


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
    CIImage *resultImg = nil;
    CIImage *img[nCameras];
    for (int i=0; i<nCameras; i++) {
        if (i == 0) {
            dispatch_async(mainq, ^{
                imshow(kForeImageWindowName, captures[i]->retrieve());
            });
        }
        img[i] = captures[i]->retrieveCIImage();
        captures[i]->lock();
    }
    resultImg = [chromakey updateFilter:img[0] withBkgnd:img[1]];
    dispatch_async(mainq, ^{
        pwidget->updateImage(resultImg);
        //pwidget->updateImage(img[1]);
    });
    for (int i=0; i<nCameras; i++) {
        captures[i]->unlock();
    }
}

void myCaptureCenter::stateChanged(Cap::Capture* capture)
{
    const QString* str = captureStateQString(capture->state, capture->mModelName);
    qDebug() << *str;
}

/*
 Local functions
 */
void MaxHueChanged(int val, void *ptr)
{
    chromakey.maxHueAngle = val;
}

void MinHueChanged(int val, void *ptr)
{
    chromakey.minHueAngle = val;
}

void MinValueChanged(int val, void *ptr)
{
    chromakey.minValue = val/255.0;
}


int main (int argc, char **argv)
{
    // It is to explicitly run the event loop -- see the bottom of main()
    QApplication app(argc,argv);
    QMainWindow window;

    // Analyze command options.
	if ((progname = rindex(argv[0], '/')) != nullptr)
		progname++;
    else
		progname = argv[0];
    
    bool useInternalCameras = false;
    int ch;
    opterr = 0;
    while ((ch = getopt(argc, argv, "?h:w:f:m:M:u")) != -1) {
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
            case 'm':
                minHueAngle = atof(optarg);
                break;
            case 'M':
                maxHueAngle = atof(optarg);
                break;
            case 'v':
                minValue = atof(optarg);
                break;
            case 'u':
                useInternalCameras = true;
                break;
            default:
                usage(progname);
                exit(0);
        }
    }
    
    pwidget = new QCvGLWidget;
    window.resize(w, h);
    window.setCentralWidget(pwidget);
    window.setWindowTitle(QString("Chroma Mix"));
    window.show();
    
    namedWindow(kForeImageWindowName);
    createTrackbar("Max Hue", kForeImageWindowName, &maxHueAngle, 360, MaxHueChanged);
    createTrackbar("Min Hue", kForeImageWindowName, &minHueAngle, 360, MinHueChanged);
    createTrackbar("Min Val", kForeImageWindowName, &minValue, 255, MinValueChanged);

    /*
#define BUFLEN 1024
    char winnamebuf[BUFLEN];
    char *p = winnamebuf;
    for (int i=0; i<nCameras; i++) {
        windownames.push_back(p);
        char buf[1024];
        sprintf(buf, "Cap %d", i);
        strlcpy(p, buf, BUFLEN-(p-winnamebuf)-1);
        p += (strnlen(buf, 1024) + 1);
    }
    
    // Prepare window
    for (int i=0; i<nCameras; i++) {
        namedWindow(windownames[i], CV_WINDOW_AUTOSIZE);
    }
     */

    
    //////////////////////////////////////////////////////////////////
    // Start
    myCaptureCenter capcenter;
    capcenter.setDesiredFPS(f);
    
    for (int i=0; i<nCameras; i++) {
        CaptureQtKit *cap;
        cap = (CaptureQtKit *)capcenter.addCapture(kCaptureTypeQtKit);
        if (cap == nullptr) {
            std::cerr << "Fail to create capture #" << i << std::endl;
            return -1-i;
        }
        
        cap->mUseInternalCameras = useInternalCameras;
        
        if (cap->init() == false) {
            std::cerr << "Fail to open capture #" << i << std::endl;
            return -1-i;
        }
        std::cerr << "Capture[" << i << "] : " << cap->mModelName << std::endl;
        cap->setDesiredSize(w, h);
    }
    
    // Prepare CvChromakey
    chromakey = [[CvChromakey alloc] initWithHueAngles:minHueAngle to:maxHueAngle withMinValue:minValue/256.0];
    
    group = dispatch_group_create();
    mainq = dispatch_get_main_queue();
    
    capcenter.start();
	app.exec();
    capcenter.stop();
    return 0;
}
