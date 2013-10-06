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

#include "huetool.h"

using namespace cv;

extern "C" {

static float rgbToHue(float r, float g, float b);

cv::Mat *createHueImage(const cv::Mat& image)
{
    
    if (image.elemSize1() < 3) return nullptr;
    
    Mat *result = new Mat(image.rows, image.cols, CV_32FC1);

    Mat_<int>::const_iterator img = image.begin<int>();
    Mat_<float>::iterator res = result->begin<float>();
    
    for (; res!=result->end<float>(); img++, res++) {
        float r = img[2];
        float g = img[1];
        float b = img[0];
        float hue = rgbToHue(r, g, b);
        *res = hue;
    }
    
    return result;
}

bool evalHueImage(const cv::Mat hueimage, float& hueavg, float& huestdev, int& huemin, int& huemax)
{
    if (hueimage.depth() != CV_32F) return false;
    int n = 0;
    huemax = -1;
    huemin = 400;
    float x = 0;
    float x2 = 0;
    for (Mat_<float>::const_iterator res = hueimage.begin<float>(); res!=hueimage.end<float>(); res++) {
        float hue = (*res);
        if (hue > huemax) huemax = hue;
        if (hue < huemin) huemin = hue;
        x += hue;
        x2 += hue*hue;
        n++;
    }
    hueavg = x / n;
    huestdev = sqrt((x2 - 2*hueavg*x + hueavg*hueavg) / (n-1));
    
    return true;
}
    
bool evalImage(const cv::Mat image, float& hueavg, float& huestdev, int& huemin, int& huemax)
{
    Mat *hueimg = createHueImage(image);
    bool ret = evalHueImage(*hueimg, hueavg, huestdev, huemin, huemax);
    delete hueimg;
    return ret;
}

static float rgbToHue(float r, float g, float b)
{
    float hue;
    
    // Equation from http://ja.wikipedia.org/wiki/HSV色空間
    float min, max, f1;
    f1 = (r < g)? r : g;
    min = (f1 < b)? f1 : b;
    f1 = (r > g)? r : g;
    max = (f1 > b)? f1 : b;
    
    if (min != max) {
        if (max == r)
            hue = 60 * (g - b) / (max - min);
        else if (max == g)
            hue = 60 * (b - r) / (max - min) + 120;
        else
            hue = 60 * (r - g) / (max - min) + 240;
        if (hue < 0)
            hue += 360;
    }
    else
        hue = -1;
    return hue;
}

}
