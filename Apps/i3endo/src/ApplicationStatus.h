/*=========================================================================

  This software is distributed WITHOUT ANY WARRANTY; without even
  the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
  PURPOSE.  See the above copyright notices for more information.

=========================================================================*/
/**
 * @file
 */

#ifndef APPLICATIONSTATUH_H_
#define APPLICATIONSTATUH_H_

typedef enum {
    kNativeYUVConversionBit = 1,
    kCvFlipBit  = 2,
    kQtFlipBit  = 4,
    kCvCopyBit  = 8,
    kQtCopyBit  = 16,
} kDrawModeBit;

typedef enum {
    kNativeYUVConversion_CvFlip = kNativeYUVConversionBit | kCvFlipBit,
    kNativeYUVConversion_QtFlip = kNativeYUVConversionBit | kQtFlipBit,
    kNativeYUVConversion_MyFlip = kNativeYUVConversionBit,
    kMyYUVConversion_CvCopy = kCvCopyBit,
    kMyYUVConversion_QtCopy = kQtCopyBit,
    kMyYUVConversion_MyCopy = 0
} kDrawMode;

struct ApplicationStatus
{
    QPoint srcCenterL;
    QSize  srcSizeL;
    QPoint srcCenterR;
    QSize  srcSizeR;
    
    kDrawMode drawMode;
    unsigned inputPixelMode;
    unsigned inputFormatMode;
    int nConcurrentTasks;
    int endoAxis;

	ApplicationStatus()
    : srcCenterL(0,0)
    , srcSizeL(0,0)
    , srcCenterR(0,0)
    , srcSizeR(0,0)
    , drawMode(kNativeYUVConversion_CvFlip)
    , inputPixelMode(0)
    , inputFormatMode(0)
    , nConcurrentTasks(4)
    , endoAxis(90)
		{}
};

#endif // APPLICATIONSTATUH_H_

