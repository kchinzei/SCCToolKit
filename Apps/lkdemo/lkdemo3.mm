#include <dispatch/dispatch.h>
#include <QtGui>
#include "opencv2/video/tracking.hpp"
#include "opencv2/imgproc/imgproc.hpp"
#include "opencv2/highgui/highgui.hpp"
#include "CaptureCenter.h"
#include "CaptureQtKit.h"
#include "QCvGraphicsView.h"

QCvGraphicsView *pview;

#include <iostream>
#include <ctype.h>

using namespace cv;
using namespace std;

static void help()
{
    // print a welcome message, and the OpenCV version
    cout << "\nThis is a demo of Lukas-Kanade optical flow lkdemo(),\n"
            "Using OpenCV version %s\n" << CV_VERSION << "\n"
            << endl;

    cout << "\nHot keys: \n"
            "\tESC - quit the program\n"
            "\tr - auto-initialize tracking\n"
            "\tc - delete all the points\n"
            "\tn - switch the \"night\" mode on/off\n"
            "To add/remove a feature point click it\n" << endl;
}

Point2f point;
bool addRemovePt = false;

/*
static void onMouse( int event, int x, int y, int flags, void* param )
{
    if( event == CV_EVENT_LBUTTONDOWN )
    {
        point = Point2f((float)x,(float)y);
        addRemovePt = true;
    }
}
*/

class myCaptureCenter : public Cap::CaptureCenter {
    void imagesArrived(Cap::Capture *capture) override;
};

int main( int argc, char** argv )
{
//    VideoCapture cap;

/*
    if( argc == 1 || (argc == 2 && strlen(argv[1]) == 1 && isdigit(argv[1][0])))
        cap.open(argc == 2 ? argv[1][0] - '0' : 0);
    else if( argc == 2 )
        cap.open(argv[1]);

    if( !cap.isOpened() )
    {
        cout << "Could not initialize capturing...\n";
        return 0;
    }
*/

    myCaptureCenter capcenter;
    Cap::CaptureQtKit *cap = (Cap::CaptureQtKit*) capcenter.addCapture(Cap::kCaptureTypeQtKit);
    cap->mUseInternalCameras = true;
    
    help();

/*
 Add
 */
    argc = 0;
    QApplication app(argc,argv);
    QMainWindow window;
    pview = new QCvGraphicsView;
    window.resize(640, 480);
    window.setCentralWidget(pview);
    window.show();

/*
    namedWindow( "LK Demo", 1 );
    setMouseCallback( "LK Demo", onMouse, 0 );
*/

    capcenter.start();
    app.exec();
    capcenter.stop();
    return 0;
}

TermCriteria termcrit(CV_TERMCRIT_ITER|CV_TERMCRIT_EPS,20,0.03);
cv::Size subPixWinSize(10,10), winSize(31,31);

const int MAX_COUNT = 500;
bool needToInit = true;
bool nightMode = false;

Mat prevGray;
vector<Point2f> points[2];

void myCaptureCenter::imagesArrived(Cap::Capture *capture)
{
    Cap::CapturePtrVec::iterator cap = captures.begin();
    if (cap != captures.end()) {
        Mat gray, image;

        cv::Mat frame = (*cap)->retrieve(0);
        (*cap)->lock();
        frame.copyTo(image);
        (*cap)->unlock();

        cvtColor(image, gray, CV_BGR2GRAY);

        if( nightMode )
            image = Scalar::all(0);

        if( needToInit )
        {
            // automatic initialization
            goodFeaturesToTrack(gray, points[1], MAX_COUNT, 0.01, 10, Mat(), 3, 0, 0.04);
            cornerSubPix(gray, points[1], subPixWinSize, cv::Size(-1,-1), termcrit);
            addRemovePt = false;
        }
        else if( !points[0].empty() )
        {
            vector<uchar> status;
            vector<float> err;
            if(prevGray.empty())
                gray.copyTo(prevGray);
            calcOpticalFlowPyrLK(prevGray, gray, points[0], points[1], status, err, winSize,
                                 3, termcrit, 0, 0.001);
            size_t i, k;
            for( i = k = 0; i < points[1].size(); i++ )
            {
                if( addRemovePt )
                {
                    if( norm(point - points[1][i]) <= 5 )
                    {
                        addRemovePt = false;
                        continue;
                    }
                }

                if( !status[i] )
                    continue;

                points[1][k++] = points[1][i];
                circle( image, points[1][i], 3, Scalar(0,255,0), -1, 8);
            }
            points[1].resize(k);
        }

        if( addRemovePt && points[1].size() < (size_t)MAX_COUNT )
        {
            vector<Point2f> tmp;
            tmp.push_back(point);
            cornerSubPix( gray, tmp, winSize, cvSize(-1,-1), termcrit);
            points[1].push_back(tmp[0]);
            addRemovePt = false;
        }

        needToInit = false;
/*
        imshow("LK Demo", image);
*/
        pview->updateImage(image);

        char c = (char)waitKey(10);
/*
        if( c == 27 )
            break;
*/
        switch( c )
        {
        case 'r':
            needToInit = true;
            break;
        case 'c':
            points[1].clear();
            break;
        case 'n':
            nightMode = !nightMode;
            break;
        default:
            ;
        }

        std::swap(points[1], points[0]);
        swap(prevGray, gray);
    }
}
