/*=========================================================================

  This software is distributed WITHOUT ANY WARRANTY; without even
  the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
  PURPOSE.  See the above copyright notices for more information.

=========================================================================*/
/**
 * @file
 * Calibration Preview class implementations.
 */

#include "my_mainview.h"
#include <opencv2/core/core_c.h>
//#include "opencv2/video/tracking.hpp"
#include "opencv2/highgui/highgui.hpp"

#include <QPainter>

// Below is for test&debug purposes
#include <QtDebug>
#include <cassert>
#include "ApplicationStatus.h"
#include "timerSingleton.h"

extern kDrawMode gDrawMode;

MainView::MainView(QWidget* parent)
	: QGraphicsView(parent)
    , srcCenter(0,0)
    , srcWidth(0)
    , srcHeight(0)
    , largeClip(true)
	, image2Draw_mat(0)
    , destWidth(0)
    , destHeight(0)
    , resized(false)
    , prevMat(NULL)
{
    setContentsMargins(0, 0, 0, 0);
    setMinimumSize(1, 1);
    setAlignment(Qt::AlignHCenter);

    setObjectName(QString::fromUtf8("graphicsView"));

    srcRect.setX(-1);
    srcRect.setY(-1);
    
    image2Draw_mat = cvCreateMat(viewport()->height(), viewport()->width(), CV_8UC3);
    cvZero(image2Draw_mat);

//	mBkgndQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
}


MainView::~MainView()
{
    if (image2Draw_mat)
        cvReleaseMat(&image2Draw_mat);
}


// PUBLIC SLOTS ////////////////////////////////////////////////////////
//
// Handler for arrival of a new frame.
//

void MainView::onUpdateImage(cv::Mat& arr)
{
    switch (gDrawMode) {
        case kNativeYUVConversion_CvFlip:
            onUpdateImage1(arr);
            break;
        case kNativeYUVConversion_QtFlip:
            onUpdateImage4(arr);
           break;
        case kNativeYUVConversion_MyFlip:
            // FIXME: write code
            break;
        case kMyYUVConversion_CvCopy:
            onUpdateImage2(arr);
            break;
        case kMyYUVConversion_QtCopy:
            onUpdateImage3(arr);
            break;
        case kMyYUVConversion_MyCopy:
            // FIXME: write code
            break;
    }
}

void MainView::onUpdateImage1(const cv::Mat& arr)
{
    const CvMat *mat, stub=arr;
    CvMat stub2;
    
    mat = &stub;
    
    // Resize if necessary
    if (srcWidth != -1 && srcHeight != -1) {
        if (srcWidth  != srcRect.width() ||
            srcHeight != srcRect.height() ||
            srcCenter.x() - srcWidth/2  != srcRect.x() ||
            srcCenter.y() - srcHeight/2 != srcRect.y()) {
            srcRect = QRect(srcCenter.x() - srcWidth/2,
                            srcCenter.y() - srcHeight/2,
                            srcWidth, srcHeight);
        }
        QPoint topLeft = QPoint(srcRect.x() < 0? 0:srcRect.x(),
                                srcRect.y() < 0? 0:srcRect.y());
        QPoint bottomRight = QPoint(srcRect.bottomRight().x() >= mat->width?  mat->width  : srcRect.bottomRight().x(),
                                    srcRect.bottomRight().y() >= mat->height? mat->height : srcRect.bottomRight().y());
        srcVisRect = QRect(topLeft, bottomRight);
        if (srcVisRect.x() > 0 || srcVisRect.bottomRight().x() != mat->width) {
            cv::Mat mat1(mat);
            cv::Mat mat2 = mat1.colRange(srcVisRect.x(), srcVisRect.bottomRight().x()+1);
            stub2 = mat2;
            mat = &stub2;
        }
        if (srcVisRect.y() > 0 || srcVisRect.bottomRight().y() != mat->height) {
            cv::Mat mat1(mat);
            cv::Mat mat2 = mat1.rowRange(srcVisRect.y(), srcVisRect.bottomRight().y()+1);
            stub2 = mat2;
            mat = &stub2;
        }
    }
    
    if (!image2Draw_mat || !CV_ARE_SIZES_EQ(image2Draw_mat, mat) || cvGetElemType(image2Draw_mat) != cvGetElemType(mat)) {
        if (image2Draw_mat)
            cvReleaseMat(&image2Draw_mat);
        
        //the image in ipl (to do a deep copy with cvCvtColor)
        image2Draw_mat = cvCreateMat(mat->rows, mat->cols, cvGetElemType(mat));
        
        updateGeometry();
    }
    
    if (cvGetElemType(mat) == CV_8UC3) {
        cvConvertImage(mat, image2Draw_mat,  CV_CVTIMG_SWAP_RB);
    } else {
        cvFlip(mat, image2Draw_mat, 1);
    }
    viewport()->update();
}

void MainView::onUpdateImage4(const cv::Mat& arr)
{
    const CvMat *mat, stub=arr;
    CvMat stub2;
    
    mat = &stub;
    
    // Resize if necessary
    if (srcWidth != -1 && srcHeight != -1) {
        if (srcWidth  != srcRect.width() ||
            srcHeight != srcRect.height() ||
            srcCenter.x() - srcWidth/2  != srcRect.x() ||
            srcCenter.y() - srcHeight/2 != srcRect.y()) {
            srcRect = QRect(srcCenter.x() - srcWidth/2,
                            srcCenter.y() - srcHeight/2,
                            srcWidth, srcHeight);
        }
        QPoint topLeft = QPoint(srcRect.x() < 0? 0:srcRect.x(),
                                srcRect.y() < 0? 0:srcRect.y());
        QPoint bottomRight = QPoint(srcRect.bottomRight().x() >= mat->width?  mat->width  : srcRect.bottomRight().x(),
                                    srcRect.bottomRight().y() >= mat->height? mat->height : srcRect.bottomRight().y());
        srcVisRect = QRect(topLeft, bottomRight);
        if (srcVisRect.x() > 0 || srcVisRect.bottomRight().x() != mat->width) {
            cv::Mat mat1(mat);
            cv::Mat mat2 = mat1.colRange(srcVisRect.x(), srcVisRect.bottomRight().x()+1);
            stub2 = mat2;
            mat = &stub2;
        }
        if (srcVisRect.y() > 0 || srcVisRect.bottomRight().y() != mat->height) {
            cv::Mat mat1(mat);
            cv::Mat mat2 = mat1.rowRange(srcVisRect.y(), srcVisRect.bottomRight().y()+1);
            stub2 = mat2;
            mat = &stub2;
        }
    }
    
    QImage::Format fmt = QImage::Format_RGB888;
    if (cvGetElemType(mat) == CV_8UC4)
        fmt = QImage::Format_ARGB32_Premultiplied;

    QImage qmat = QImage(mat->data.ptr, mat->cols, mat->rows, mat->step, fmt);
    
    if (cvGetElemType(mat) == CV_8UC3) {
        image2Draw_qt = qmat.rgbSwapped();
    } else {
        image2Draw_qt = qmat.mirrored(true, false);
    }
    viewport()->update();
}

void MainView::onUpdateImage2(const cv::Mat& arr)
{
    CvMat *mat, stub=arr;
    
    mat = &stub;
    
    if (!image2Draw_mat || !CV_ARE_SIZES_EQ(image2Draw_mat, mat) || cvGetElemType(image2Draw_mat) != cvGetElemType(mat)) {
        if (image2Draw_mat)
            cvReleaseMat(&image2Draw_mat);
        
        //the image in ipl (to do a deep copy with cvCvtColor)
        image2Draw_mat = cvCreateMat(mat->rows, mat->cols, cvGetElemType(mat));
        
        updateGeometry();
    }
    
    cvCopy(mat, image2Draw_mat);
    viewport()->update();
}

void MainView::onUpdateImage3(cv::Mat& arr)
{
    QImage::Format fmt = QImage::Format_RGB888;
    if (arr.type() == CV_8UC4)
        fmt = QImage::Format_ARGB32_Premultiplied;
    
    image2Draw_qt = QImage(arr.data, arr.cols, arr.rows, arr.step, fmt);
    if (prevMat) delete prevMat;
    prevMat = &arr;
    
    viewport()->update();
}


// PROTECTED METHODS ///////////////////////////////////////////////////
//
// Paint event handler.
//
void MainView::paintEvent(QPaintEvent* event)
{
	// Call base class handler to draw the bounding box of this frame.

    QPainter myPainter(viewport());
    //myPainter.setWorldTransform(param_matrixWorld);
    myPainter.setBackgroundMode(Qt::OpaqueMode);

    if (resized) {
        updateOvalClip(&myPainter);
    }
    
    switch (gDrawMode) {
        case kNativeYUVConversion_CvFlip:
            draw2D1(&myPainter);
            break;
        case kNativeYUVConversion_QtFlip:
            draw2D4(&myPainter);
            break;
        case kNativeYUVConversion_MyFlip:
            // FIXME: write code
            break;
        case kMyYUVConversion_CvCopy:
            draw2D2(&myPainter);
            break;
        case kMyYUVConversion_QtCopy:
            draw2D3(&myPainter);
            break;
        case kMyYUVConversion_MyCopy:
            // FIXME: write code
            break;
    }
 
    //myPainter.setWorldMatrixEnabled(false);
    timerSingleton *t = timerSingleton::sharedInstance();
    t->tStop();
}

void MainView::draw2D1(QPainter *painter)
{
    QImage::Format fmt = QImage::Format_RGB888;
    if (cvGetElemType(image2Draw_mat) == CV_8UC4)
        fmt = QImage::Format_ARGB32_Premultiplied;
    
    image2Draw_qt = QImage(image2Draw_mat->data.ptr, image2Draw_mat->cols, image2Draw_mat->rows,image2Draw_mat->step, fmt);
    
    // First Align srcRect to destRect
    // Then we use size of srcVisRect
    QRect drawRect = QRect((destWidth  - srcWidth) /2 + (srcVisRect.x() - srcRect.x()),
                           (destHeight - srcHeight)/2 + (srcVisRect.y() - srcRect.y()),
                           srcVisRect.size().width(),
                           srcVisRect.size().height());
    painter->drawImage(drawRect,image2Draw_qt);
}

void MainView::draw2D4(QPainter *painter)
{
    // First Align srcRect to destRect
    // Then we use size of srcVisRect
    QRect drawRect = QRect((destWidth  - srcWidth) /2 + (srcVisRect.x() - srcRect.x()),
                           (destHeight - srcHeight)/2 + (srcVisRect.y() - srcRect.y()),
                           srcVisRect.size().width(),
                           srcVisRect.size().height());
    painter->drawImage(drawRect,image2Draw_qt);
}

void MainView::draw2D2(QPainter *painter)
{
    QImage::Format fmt = QImage::Format_RGB888;
    if (cvGetElemType(image2Draw_mat) == CV_8UC4)
        fmt = QImage::Format_ARGB32_Premultiplied;
    
    image2Draw_qt = QImage(image2Draw_mat->data.ptr, image2Draw_mat->cols, image2Draw_mat->rows,image2Draw_mat->step, fmt);
    
    draw2D3(painter);
}

void MainView::draw2D3(QPainter *painter)
{
    // Always draw image2Draw_qt at the center of me.
    int w = image2Draw_qt.width();
    int h = image2Draw_qt.height();
    QRect drawRect = QRect((destWidth  - w) / 2, (destHeight - h) / 2, w, h);
    painter->drawImage(drawRect, image2Draw_qt);
}


void MainView::updateOvalClip(QPainter *painter)
{
    int x0, y0, diameter;
    
    if (largeClip) {
        diameter = (destWidth > destHeight)? destWidth : destHeight;
    } else {
        diameter = (destWidth < destHeight)? destWidth : destHeight;
    }
    x0 = (destWidth - diameter) / 2;
    y0 = (destHeight - diameter) / 2;

    setBackgroundRole(QPalette::Shadow);
    QRegion rgn(x0, y0, diameter, diameter, QRegion::Ellipse);
    painter->setClipRegion(rgn);
    painter->setClipping(true);
    resized = false;
}

void MainView::resizeEvent ( QResizeEvent * event )
{
    destWidth  = viewport()->width();
    destHeight = viewport()->height();
    if (srcWidth  == 0 && srcHeight == 0) {
        srcWidth  = destWidth;
        srcHeight = destHeight;
        srcCenter = QPoint(srcWidth / 2, srcHeight / 2);
        srcRect = QRect(0, 0, srcWidth, srcHeight);
    }
    resized = true;
}

QSize MainView::sizeHint() const
{
	return QGraphicsView::sizeHint();
}
