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

#ifndef __chromakey__huetool__
#define __chromakey__huetool__

#include <iostream>
#include <opencv2/core/core.hpp>

extern "C" {
    cv::Mat *createHueImage(const cv::Mat& image);
    bool evalHueImage(const cv::Mat hueimage, float& hueavg, float& huestdev, int& huemin, int& huemax);
    bool evalImage(const cv::Mat image, float& hueavg, float& huestdev, int& huemin, int& huemax);
};

#endif /* defined(__testcc_chromakey__huetool__) */
