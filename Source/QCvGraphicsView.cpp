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

/**
 * @file
 * Calibration Preview class implementations.
 */

#include "QCvGraphicsView.h"
#include <opencv2/core/core_c.h>

#include <QPainter>

// Below is for test&debug purposes
#include <QtDebug>
#include <cassert>

QCvGraphicsView::QCvGraphicsView(QWidget* parent)
	: QGraphicsView(parent)
    , paintMode(Cap::kPaintModeNoScalling)
{
    setContentsMargins(0, 0, 0, 0);
    setMinimumSize(1, 1);
    setAlignment(Qt::AlignHCenter);

    setObjectName(QString::fromUtf8("QCvGraphicsView"));
    mSemaphore = dispatch_semaphore_create(1);
    image2Draw_qt = QImage(640, 480, QImage::Format_RGB888);
}


QCvGraphicsView::~QCvGraphicsView()
{
    dispatch_release(mSemaphore);
}


// PUBLIC SLOTS ////////////////////////////////////////////////////////
//
// Handler for arrival of a new frame.
//

void QCvGraphicsView::onUpdateImage(cv::Mat& arr)
{
    updateImage(arr);
}

void QCvGraphicsView::updateImage(cv::Mat& arr)
{
    QImage::Format fmt = QImage::Format_RGB888;
    if (arr.type() == CV_8UC4)
        fmt = QImage::Format_ARGB32_Premultiplied;
        
    dispatch_semaphore_wait(mSemaphore, DISPATCH_TIME_FOREVER);
    image2Draw_qt = QImage(arr.data, arr.cols, arr.rows, arr.step, fmt);
    dispatch_semaphore_signal(mSemaphore);
    
    viewport()->update();
}


// PROTECTED METHODS ///////////////////////////////////////////////////
//
// Paint event handler.
//
void QCvGraphicsView::paintEvent(QPaintEvent* event)
{
	// Call base class handler to draw the bounding box of this frame.

    QPainter myPainter(viewport());
    //myPainter.setWorldTransform(param_matrixWorld);
    myPainter.setBackgroundMode(Qt::OpaqueMode);

    dispatch_semaphore_wait(mSemaphore, DISPATCH_TIME_FOREVER);
    switch (paintMode) {
        case Cap::kPaintModeNoScalling:
            draw2DWithoutScaling(&myPainter);
            break;
        case Cap::kPaintModeScaleToFill:
            draw2DWithScaleToFill(&myPainter);
            break;
        case Cap::kPaintModeScaleAspectFit:
            draw2DWithScaleAspectFit(&myPainter);
            break;
        case Cap::kPaintModeScaleAspectFill:
            draw2DWithScaleAspectFill(&myPainter);
            break;
    }
	dispatch_semaphore_signal(mSemaphore);
}

void QCvGraphicsView::draw2DWithScaleToFill(QPainter *painter)
{
    // Always draw image2Draw_qt at the center of me.
    QRect target = painter->viewport();
    QRect source = image2Draw_qt.rect();
    painter->drawImage (target, image2Draw_qt, source);
}

void QCvGraphicsView::draw2DWithoutScaling(QPainter *painter)
{
    // Always draw image2Draw_qt at the center of me.
    QRect target, source;
    int w = image2Draw_qt.width();
    int h = image2Draw_qt.height();
    QRect vp = painter->viewport();
    
    int x = (vp.width() - w) / 2;
    if (x >= 0) {
        target.setX(x);
        source.setX(0);
        target.setWidth(w);
        source.setWidth(w);
    } else {
        target.setX(0);
        source.setX(-x);
        target.setWidth(vp.width());
        source.setWidth(vp.width());
    }
    int y = (vp.height() - h) / 2;
    if (y >= 0) {
        target.setY(y);
        source.setY(0);
        target.setHeight(h);
        source.setHeight(h);
    } else {
        target.setY(0);
        source.setY(-y);
        target.setHeight(vp.height());
        source.setHeight(vp.height());
    }
    painter->drawImage (target, image2Draw_qt, source);
}

void QCvGraphicsView::draw2DWithScaleAspectFit(QPainter *painter)
{
    // Always draw image2Draw_qt at the center of me.
    QRect destRect = painter->viewport();
    QRect imgRect = image2Draw_qt.rect();
    
    double rw = destRect.width() / imgRect.width();
    double rh = destRect.height()/ imgRect.height();
    if (rw < rh) {
        float h =  destRect.height();
        destRect.setHeight(imgRect.height() * rw);
        destRect.setY((h - destRect.height())/2);
    } else {
        float w = destRect.width();
        destRect.setWidth(imgRect.width() * rh);
        destRect.setX((w - destRect.width()) / 2);
    }
    
    painter->drawImage (destRect, image2Draw_qt, imgRect);
}

void QCvGraphicsView::draw2DWithScaleAspectFill(QPainter *painter)
{
    // Always draw image2Draw_qt at the center of me.
    QRect destRect = painter->viewport();
    QRect imgRect = image2Draw_qt.rect();
    
    double rw = imgRect.width() / destRect.width();
    double rh = imgRect.height()/ destRect.height();
    if (rw < rh) {
        float h =  imgRect.height();
        imgRect.setHeight(destRect.height() * rw);
        imgRect.setY((h - imgRect.height())/2);
    } else {
        float w = imgRect.width();
        imgRect.setWidth(destRect.width() * rh);
        imgRect.setX((w - imgRect.width()) / 2);
    }
    
    painter->drawImage (destRect, image2Draw_qt, imgRect);
}

/*
QSize QCvGraphicsView::sizeHint() const
{
	return QGraphicsView::sizeHint();
}
*/
