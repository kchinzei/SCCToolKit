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

#include <QApplication>
#include <QMainWindow>
#include <QtDebug>
#include "opencv2/video/tracking.hpp"
#include "opencv2/imgproc/imgproc.hpp"
#include "opencv2/highgui/highgui.hpp"

#include <iostream>
#include <ctype.h>
#include <strings.h>
#include <vector>

#include <unistd.h>

#include "QCvGraphicsView.h"
#include "QCvGLWidget.h"
#include "CaptureCenter.h"
#include "Capture.h"
#include "CaptureUtils.h"
#include "CaptureQtKit.h"
#include <dispatch/dispatch.h>

extern int opterr;
extern int optind;
extern char *optarg;
char *progname;

double w = 640, h = 480, f = 30;
int nCameras = 1;
int mode = 0;
bool useInternalCameras = false;
bool useDecklink = false;
bool screenFit = false;

dispatch_group_t group;
dispatch_queue_t mainq;

using namespace std;
using namespace cv;
using namespace Cap;

QCvGraphicsView *pview;
QCvGLWidget *pwidget;

static void usage(const char *progname)
{
    fprintf(stderr,
			"%s [-options]\n"
            "   [-w width]    default=%lf\n"
            "   [-h height]   default=%lf\n"
            "   [-f FPS]      default=%lf\n"
            "   [-g|-G] Use OpenGL default=%d\n"
            "   [-u] Use internal cameras. default=%d\n"
            "   [-d] Use DeckLink. default=%d\n"
            "   [-s] Fit window. default=%d\n"
            , progname, w, h, f, mode, useInternalCameras, useDecklink, screenFit
            );
}

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
    for (int i=0; i<nCameras; i++) {
        captures[i]->lock();
        dispatch_async(mainq, ^{
            switch (mode) {
                case 0:
                    pview->updateImage(captures[i]->retrieve());
                    break;
                case 1:
                    pwidget->updateImage(captures[i]->retrieve());
                    break;
                case 2:
                    pwidget->updateImage(captures[i]->retrieveCIImage());
                    break;
            }
        });
        captures[i]->unlock();
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
    QMainWindow window;
    
    // Analyze command options.
	if ((progname = rindex(argv[0], '/')) != nullptr) progname++;
    else progname = argv[0];
    
    int ch;
    opterr = 0;
    while ((ch = getopt(argc, argv, "?h:w:f:ugGds")) != -1) {
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
            case 'u':
                useInternalCameras = true;
                break;
            case 'g':
                mode = 1;
                break;
            case 'G':
                mode = 2;
                break;
            case 'd':
                useDecklink= true;
                break;
            case 's':
                screenFit = true;
                break;
            default:
                usage(progname);
                exit(0);
        }
    }

    window.resize(w, h);
    pview = new QCvGraphicsView;
    pwidget = new QCvGLWidget;
    pwidget->paintMode = Cap::kPaintModeScaleAspectFit;
    
    switch (mode) {
        case 0:
            window.setCentralWidget(pview);
            window.setWindowTitle(QString("Using QCvGraphcsView"));
            break;
        case 1:
            window.setCentralWidget(pwidget);
            window.setWindowTitle(QString("Using QCvGLWidget (Qpaint)"));
            break;
        case 2:
            window.setCentralWidget(pwidget);
            window.setWindowTitle(QString("Using QCvGLWidget (CIContext)"));
            break;
    }
    window.show();
    
    //////////////////////////////////////////////////////////////////
    // Start
    myCaptureCenter capcenter;
    capcenter.setDesiredFPS(f);
    
    for (int i=0; i<nCameras; i++) {
        Capture *cap;
        if (useDecklink)
            cap = capcenter.addCapture(kCaptureTypeDeckLink);
        else
            cap = capcenter.addCapture(kCaptureTypeQtKit);
        if (cap == nullptr) {
            std::cerr << "Fail to create capture #" << i << std::endl;
            return -1-i;
        }
        
        if (!useDecklink)
            ((CaptureQtKit *)cap)->mUseInternalCameras = useInternalCameras;
        if (cap->init() == false) {
            std::cerr << "Fail to open capture #" << i << std::endl;
            return -1-i;
        }
        std::cerr << "Capture[" << i << "] : " << cap->mModelName << std::endl;
        cap->setDesiredSize(w, h);
    }
    
    group = dispatch_group_create();
    mainq = dispatch_get_main_queue();
    
    capcenter.start();
	app.exec();
    capcenter.stop();
    return 0;
}
