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

#include <cv.h>
#include <highgui.h>
#include <ctype.h>
#include <stdio.h>
#include <unistd.h>
#include <strings.h>

extern int opterr;
extern int optind;
extern char *optarg;
char *progname;
double w = 320, h = 240, f = 30;
int cameraID = 0;

void   Print(const IplImage *frame);

static void usage(const char *progname)
{
    fprintf(stderr,
			"%s [-options]\n"
            "   [-w width]    default=%lf\n"
            "   [-h height]   default=%lf\n"
            "   [-f FPS]      default=%lf\n"
            "   [cameraid]    default=%d\n", progname, w, h, f, cameraID
            );
}

int
main (int argc, char **argv)
{
	CvCapture *capture = 0;
	IplImage *frame = 0;
	double param;
	int c;
	char dummy[5];
	double *pdummy;
	if ((progname = rindex(argv[0], '/')) != NULL)
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
    if (argc - optind == 1) {
        cameraID = atoi(argv[optind]);
    }
  
	capture = cvCaptureFromCAM (cameraID);

	cvSetCaptureProperty(capture, CV_CAP_PROP_FRAME_WIDTH, w);
	cvSetCaptureProperty(capture, CV_CAP_PROP_FRAME_HEIGHT, h);
	cvSetCaptureProperty(capture, CV_CAP_PROP_FPS, f);

	param = cvGetCaptureProperty(capture, CV_CAP_PROP_POS_MSEC);
	fprintf(stderr, "CV_CAP_PROP_POS_MSEC= %lf\n", param);
  
	param = cvGetCaptureProperty(capture, CV_CAP_PROP_POS_FRAMES);
	fprintf(stderr, "CV_CAP_PROP_POS_FRAMES= %lf\n", param);

	param = cvGetCaptureProperty(capture, CV_CAP_PROP_FRAME_WIDTH);
	fprintf(stderr, "CV_CAP_PROP_FRAME_WIDTH= %lf\n", param);

	param = cvGetCaptureProperty(capture, CV_CAP_PROP_FRAME_HEIGHT);
	fprintf(stderr, "CV_CAP_PROP_FRAME_HEIGHT= %lf\n", param);

	param = cvGetCaptureProperty(capture, CV_CAP_PROP_FPS);
	fprintf(stderr, "CV_CAP_PROP_FPS= %lf\n", param);

	pdummy = (double *)dummy;
	*pdummy = cvGetCaptureProperty(capture, CV_CAP_PROP_FOURCC);
	dummy[4] = '\0';
	fprintf(stderr, "CV_CAP_PROP_FOURCC= %s\n", dummy);

	param = cvGetCaptureProperty(capture, CV_CAP_PROP_FRAME_COUNT);
	fprintf(stderr, "CV_CAP_PROP_FRAME_COUNT= %lf\n", param);

	param = cvGetCaptureProperty(capture, CV_CAP_PROP_BRIGHTNESS);
	fprintf(stderr, "CV_CAP_PROP_BRIGHTNESS= %lf\n", param);
	
	param = cvGetCaptureProperty(capture, CV_CAP_PROP_CONTRAST);
	fprintf(stderr, "CV_CAP_PROP_CONTRAST= %lf\n", param);

	param = cvGetCaptureProperty(capture, CV_CAP_PROP_SATURATION);
	fprintf(stderr, "CV_CAP_PROP_SATURATION= %lf\n", param);

	param = cvGetCaptureProperty(capture, CV_CAP_PROP_HUE);
	fprintf(stderr, "CV_CAP_PROP_HUE= %lf\n", param);

	cvNamedWindow ("Capture", CV_WINDOW_AUTOSIZE|CV_WINDOW_KEEPRATIO);

	frame = cvQueryFrame (capture);
	cvShowImage ("Capture", frame);
	Print(frame);
  
	int roop = 1;
	int stop = 0;
	while (roop) {
		if (!stop) {
			frame = cvQueryFrame (capture);
			cvShowImage ("Capture", frame);
		}
	  
		c = cvWaitKey (20);
		switch (c) {
		case '\x1b':
			roop = 0;
			break;
		case '0':
			cvReleaseCapture(&capture);
			stop = 1;
			break;
		case '1':
			capture = cvCaptureFromCAM (cameraID);
			break;
		}
	}

	//cvReleaseCapture (&capture);
	cvDestroyWindow ("Capture");

	return 0;
}

void   Print(const IplImage *frame)
{
	printf("ID        : %d\n", frame->ID);
	printf("cChannels : %d\n", frame->nChannels);
	printf("depth     : %d\n", frame->depth);
	printf("dataOrder : %d\n", frame->dataOrder);
	printf("dataOrder : %d\n", frame->dataOrder);
}
