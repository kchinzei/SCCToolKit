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

#include <dispatch/dispatch.h>
#include <QApplication>
#include <QMainWindow>
#include "opencv2/imgproc/imgproc.hpp"
#include "CaptureCenter.h"
#include "QCvGLWidget.h"

QCvGLWidget *pwidget;

class myCaptureCenter : public Cap::CaptureCenter {
    void imagesArrived(Cap::Capture *capture) override;
};

void myCaptureCenter::imagesArrived(Cap::Capture *capture)
{
    Cap::CapturePtrVec::iterator cap = captures.begin();
    if (cap != captures.end()) {
        dispatch_async(dispatch_get_main_queue(), ^{
            cv::Mat frame = (*cap)->retrieve(0);
            (*cap)->lock();
            pwidget->updateImage(frame);
            (*cap)->unlock();
        });
    }
}

int main (int argc, char **argv)
{
    QApplication app(argc,argv);
    QMainWindow window;
    pwidget = new QCvGLWidget;
    pwidget->paintMode = Cap::kPaintModeScaleAspectFill;
    window.resize(640, 480);
    window.setCentralWidget(pwidget);
    window.show();

    myCaptureCenter capcenter;
	capcenter.addCapture(Cap::kCaptureTypeDeckLink);
    capcenter.start();
	app.exec();
    capcenter.stop();
    return 0;
}
