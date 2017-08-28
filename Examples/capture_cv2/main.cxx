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
#include <dispatch/dispatch.h>
#include "opencv2/video/tracking.hpp"
#include "opencv2/imgproc/imgproc.hpp"
#include "opencv2/highgui/highgui.hpp"

#include <iostream>
#include <ctype.h>

#include <strings.h>
#include <sys/time.h>
#include <string>
#include <sstream>
#include <vector>

using namespace cv;
using namespace std;

extern int opterr;
extern int optind;
extern char *optarg;
char *progname;
int fps = 30;
int kCameras = 3;
int w = 640;
int h = 480;

static void usage(const char *progname)
{
    fprintf(stderr,
			"%s [-options] [exclude_camera_id ...]\n"
            "   [-m maxcameras] maximum cameras: default=%d\n"
            "   [-f FPS] desired frame per second: default=%d\n"
            "   [-w width]  desired width:  default=%d\n"
            "   [-h height] desired height: default=%d\n"
            "   [exclude_cameraid] default=none\n", progname, kCameras, fps, w, h);
}

int main(int argc, char** argv)
{
    // As a standard unix main()...
    int wDesired = 0;
    int hDesired = 0;
    int ch;
    opterr = 0;
	if ((progname = rindex(argv[0], '/')) != NULL)
		progname++;
    else
		progname = argv[0];

    // QApplication is used for handring the event loop
	QApplication app(argc, argv);
    
    // Command line parse as a standard unix main()...
    while ((ch = getopt(argc, argv, "f:m:w:h:")) != -1) {
        switch (ch) {
            case 'f':
                fps = atoi(optarg);
                break;
            case 'm':
                kCameras = atoi(optarg);
                break;
            case 'w':
                wDesired = atoi(optarg);
                break;
            case 'h':
                hDesired = atoi(optarg);
                break;
            default:
                usage(progname);
                exit(0);
        }
    }
    
    // Grand Central Dispatch staff. OSX dependent.
    static dispatch_once_t once;
	dispatch_queue_t mainQueue = dispatch_get_main_queue();
    //dispatch_queue_t highQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
	dispatch_queue_t theQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
	dispatch_source_t theTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_queue_create("timer queue",NULL));
    dispatch_group_t theGroup = dispatch_group_create();
    
    // Vectors are better in C++ than classic array because it's C++, and block ^{} accepts vectors.
    __block vector<VideoCapture> caps;
    __block vector<Mat> frames;
    vector<string> names;
	vector<int> camids;
    
    // Initialize vectors.
    for (int i=0; i<kCameras; i++) {
        stringstream ss;
        ss << "test" << i;
        names.push_back(ss.str());
        camids.push_back(1);
        caps.push_back(VideoCapture());
        frames.push_back(Mat());
    }
    
    // Rest of command line arguments are assumed as integers, that means 'don't open these IDs'
    for (int i=optind; i<argc; i++) {
        if (i-optind == kCameras) break;
        int camid = atoi(argv[i]);
        if (0 <= camid && camid < kCameras)
            camids[camid] = 0;
    }
    
    // Prepare OpenCV windows.
    for (int i=0; i<kCameras; i++) {
        if (camids[i]) {
            namedWindow(names[i]);
        }
    }
    
    // Now the main part about start.
    // All things are in a periodical timer by theTimer.
    dispatch_source_set_event_handler(theTimer, ^{
        // 
        // Initialization is in timer also, because we wanted to try caps[i].open()
        // in theQueue other than mainQueue.
        // Doing it outside the event loop will cause deadlock.
        dispatch_once(&once, ^{
            for (int i=0; i<kCameras; i++) {
                if (camids[i]) {
                    dispatch_group_async(theGroup, theQueue, ^{
                        cerr << "1. open cap" << i << endl;
                        caps[i].open(i);
                        if (!caps[i].isOpened()) {
                            cerr << "   fail open cap" << i << endl;
                            return;
                        }
                        double wNow = caps[i].get(CV_CAP_PROP_FRAME_WIDTH);
                        double hNow = caps[i].get(CV_CAP_PROP_FRAME_HEIGHT);
                        if (wDesired > 0) {
                            w = wDesired;
                            h = wDesired * hNow / wNow;
                        } else if (hDesired > 0) {
                            h = hDesired;
                            w = hDesired * wNow / hNow;
                        } else {
                            h = w * hNow / wNow;
                        }
                        caps[i].set(CV_CAP_PROP_FRAME_WIDTH, w);
                        caps[i].set(CV_CAP_PROP_FRAME_HEIGHT, h);
                    });
                }
            }
            dispatch_group_wait(theGroup, DISPATCH_TIME_FOREVER);
            
            /*
            for (int i=0; i<kCameras; i++) {
                if (camids[i] == 0) continue;
                cerr << "2. release cap" << i << " and reuse" << endl;
                caps[i].release();
                caps[i].open(i);
                if (!caps[i].isOpened()) {
                    cerr << "2. fail open cap" << i << " again" << endl;
                    return 0;
                }
                caps[i].set(CV_CAP_PROP_FRAME_WIDTH, 640);
                caps[i].set(CV_CAP_PROP_FRAME_HEIGHT, 480);
            }
             */
        });
        
        //cerr << endl<< endl << "3. try display it" << endl;
        for (int i=0; i<kCameras; i++) {
            if (camids[i])  {
                dispatch_async(theQueue, ^{
                   if (caps[i].grab() && caps[i].retrieve(frames[i], 0)) {
                        dispatch_async(mainQueue, ^{
                            imshow(names[i].c_str(), frames[i]);
                        });
                    }
                });
            }
        }
    });
    dispatch_source_set_cancel_handler(theTimer, ^{
	});
	
	dispatch_source_set_timer(theTimer, dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC) , NSEC_PER_SEC/fps, NSEC_PER_SEC/5);
	dispatch_resume(theTimer);
	
    return app.exec();

}
