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
//#include "opencv2/video/tracking.hpp"
//#include "opencv2/imgproc.hpp"
#include "opencv2/videoio.hpp"
#include "opencv2/highgui.hpp"

#include <iostream>
#include <ctype.h>

using namespace cv;
using namespace std;

//#include <cv.h>
//#include <highgui.h>
//#include <stdio.h>
//#include <unistd.h>
//#include <strings.h>

double w = 320, h = 240, f = 30;
int cameraID = 0;

void   Print(const Mat& frame);

const String keys =
	"{w width  |320| width of image}"
	"{h height |240| heiht of image}"
	"{f fps FPS| 30| frame per second}"
	"{@CameraID|  0| OpenCV Camera ID}";

int
main (int argc, char **argv)
{
	VideoCapture capture;
	CommandLineParser parser(argc, argv, keys);
	Mat frame;
	double param;

	if (!parser.check()) {
		parser.printErrors();
		parser.printMessage();
		return -1;
	}
	
	h = parser.get<int>("h");
	w = parser.get<int>("w");
	f = parser.get<int>("f");
	cameraID = parser.get<int>("@CameraID");
  
	capture.open(cameraID);
	capture.set(CAP_PROP_FRAME_WIDTH, w);
	capture.set(CAP_PROP_FRAME_HEIGHT, h);
	capture.set(CAP_PROP_FPS, f);

	param = capture.get(CAP_PROP_POS_MSEC);
	cerr << "CAP_PROP_POS_MSEC= " << param << endl;
  
	param = capture.get(CAP_PROP_POS_FRAMES);
	cerr << "CAP_PROP_POS_FRAMES= " << param << endl;

	param = capture.get(CAP_PROP_FRAME_WIDTH);
	cerr << "CAP_PROP_FRAME_WIDTH= " << (int)param << endl;

	param = capture.get(CAP_PROP_FRAME_HEIGHT);
	cerr << "CAP_PROP_FRAME_HEIGHT= " << (int)param << endl;

	param = capture.get(CAP_PROP_FPS);
	cerr << "CAP_PROP_FPS= " << (int)param << endl;

	namedWindow ("Capture", CV_WINDOW_AUTOSIZE|CV_WINDOW_KEEPRATIO);

	capture >> frame;
	imshow ("Capture", frame);
	Print(frame);
  
	int loop = 1;
	int stop = 0;
	while (loop) {
		if (!stop) {
			capture >> frame;
			imshow ("Capture", frame);
		}
	  
		char c = (char)waitKey (20);
		switch (c) {
		case '\x1b':
		case 'q':
			loop = 0;
			break;
		case '0':
			capture.release();
			stop = 1;
			break;
		case '1':
			capture.open(cameraID);
			break;
		}
	}

	return 0;
}

void   Print(const Mat& frame)
{
	cout << "Cols       : " << frame.cols << endl;
	cout << "Dims       : " << frame.dims << endl;
	cout << "Flags      : " << frame.flags << endl;
	cout << "Rows       : " << frame.rows << endl;
	cout << "Size       : " << frame.size << endl;
	cout << "Step       : " << frame.step << endl;
}
