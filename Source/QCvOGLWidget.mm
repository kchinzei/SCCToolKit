/*=========================================================================
 
 Program:   Small Computings for Clinicals Project
 Module:    $HeadURL: $
 Date:      $Date: $
 Version:   $Revision: $
 URL:       http://scc.pj.aist.go.jp
 
 (c) 2016- Kiyoyuki Chinzei, Ph.D., AIST Japan, All rights reserved.
 
 Acknowledgement: This work is/was supported by many research fundings.
 See Acknowledgement.txt
 
 This software is distributed WITHOUT ANY WARRANTY; without even
 the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
 PURPOSE.  See License.txt for license terms.
 
 =========================================================================*/

/**
 * @file
 * QGLWidget that can draw CIImage and Qt image.
 */

#include "QCvOGLWidget.h"
#include <opencv2/core/core_c.h>
#include "opencv2/highgui/highgui.hpp"
#include <QPainter>

#import "QCvGLWidget_private.h"

// Below is for test&debug purposes
#include <QtDebug>
#include <cassert>


QCvOGLWidget::QCvOGLWidget(QWidget* parent, const QOpenGLWidget * shareWidget, Qt::WindowFlags f)
: QOpenGLWidget(parent, f)
, paintMode(Cap::kPaintModeNoScalling)
, imageType(QCvGLWidget_Undef)
, pOGLFunctions(nullptr)
, image2Draw_ci(nil)
, context(nil)
, doClear(0)
{
    // setContentsMargins(0, 0, 0, 0);
    // setMinimumSize(1, 1);
    // setAlignment(Qt::AlignHCenter);
    
    setObjectName(QString::fromUtf8("QCvOGLWidget"));
    mSemaphore = dispatch_semaphore_create(1);
    image2Draw_qt = QImage(640, 480, QImage::Format_RGB888);
}


QCvOGLWidget::~QCvOGLWidget()
{
    /* ARC
    dispatch_release(mSemaphore);
    [(QCvGLWidget_CIImageDrower *)context release];
    context = nil;
     */
}


// PUBLIC SLOTS ////////////////////////////////////////////////////////
//
// Handler for arrival of a new frame.
//

void QCvOGLWidget::onUpdateImage(cv::Mat& arr)
{
    updateImage(arr);
}

void QCvOGLWidget::onUpdateImage(CIImage *img)
{
    updateImage(img);
}

// PUBLIC MEMBERS ////////////////////////////////////////////////////////
//
// draws a new frame.
//
void QCvOGLWidget::updateImage(cv::Mat& arr)
{
    QImage::Format fmt = QImage::Format_RGB888;
    if (arr.type() == CV_8UC4)
        fmt = QImage::Format_ARGB32_Premultiplied;
    
    dispatch_semaphore_wait(mSemaphore, DISPATCH_TIME_FOREVER);
    image2Draw_qt = QImage(arr.data, arr.cols, arr.rows, arr.step, fmt);
    imageType = QCvGLWidget_QImage;
    dispatch_semaphore_signal(mSemaphore);
    
    update();
}

void QCvOGLWidget::updateImage(CIImage *img)
{
    CIImage *imageToRelease = image2Draw_ci;
    //ARC
    // KChinzei 20180825: Commenting out [img retain] and [imageToRelase release] causes crash as sometimes image2Draw is overwrote, resulting the previous contents is released by ARC.
    [img retain];
    dispatch_semaphore_wait(mSemaphore, DISPATCH_TIME_FOREVER);
    image2Draw_ci = img;
    imageType = QCvGLWidget_CIImage;
    dispatch_semaphore_signal(mSemaphore);
    //ARC
    [imageToRelease release];
    
    update();
}

void QCvOGLWidget::clear(void)
{
    doClear = 2;    // Need to clear double buffer.
    update();
}

void QCvOGLWidget::onClear(void)
{
    clear();
}

/*
 QGLWidget requires overriding three functions.
 */
void QCvOGLWidget::initializeGL(void)
{
    pOGLFunctions = QOpenGLContext::currentContext()->functions();
    
    // Set up the rendering context, define display lists etc.:
    int w = this->width();
    int h = this->height();
    pOGLFunctions->glViewport (0, 0, w, h);
    glMatrixMode (GL_PROJECTION);
    glLoadIdentity ();
    glOrtho (0, w, 0, h, -1, 1);
    pOGLFunctions->glClear(GL_COLOR_BUFFER_BIT	 | GL_DEPTH_BUFFER_BIT | GL_ACCUM_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);
    pOGLFunctions->glClearColor(0.0, 0.0, 0.0, 0.0);
    pOGLFunctions->glBlendFunc (GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
    pOGLFunctions->glEnable (GL_BLEND);
    context = [[QCvGLWidget_CIImageDrower alloc] init];
}

void QCvOGLWidget::resizeGL(int w, int h)
{
    // setup viewport, projection etc.:
    // pOGLFunctions->glMatrixMode (GL_PROJECTION);
    pOGLFunctions->glViewport (0, 0, w, h);
    glLoadIdentity ();
    glOrtho (0, w, 0, h, -1, 1);
    pOGLFunctions->glClear(GL_COLOR_BUFFER_BIT);
    // pOGLFunctions->glClear(GL_COLOR_BUFFER_BIT	 | GL_DEPTH_BUFFER_BIT | GL_ACCUM_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);
    // pOGLFunctions->glFrustum(...);
}

void QCvOGLWidget::paintGL(void)
{
    assert(context != nil);
    GLfloat pSize = 0;
    pOGLFunctions->glGetFloatv(GL_POINT_SIZE, &pSize);
    
    int w = this->width();
    int h = this->height();
    CGRect bRect = CGRectMake(0, 0, w, h);
    dispatch_semaphore_wait(mSemaphore, DISPATCH_TIME_FOREVER);
    if (doClear > 0) {
        //std::cerr << "glClear " << doClear << std::endl;
        pOGLFunctions->glClear(GL_COLOR_BUFFER_BIT);
        doClear--;
    } else {
        if (image2Draw_ci) {
            // ARC
            // QCvGLWidget_CIImageDrower *c = (QCvGLWidget_CIImageDrower *)context;
            QCvGLWidget_CIImageDrower *c = (__bridge QCvGLWidget_CIImageDrower *)context;
            switch (paintMode) {
                case Cap::kPaintModeNoScalling:
                    [c drawImageWithoutScaling:image2Draw_ci
                                        inRect:bRect
                                 withPointSize:pSize];
                    break;
                case Cap::kPaintModeScaleToFill:
                    [c drawImageWithScaleToFill:image2Draw_ci
                                         inRect:bRect
                                  withPointSize:pSize];
                    break;
                case Cap::kPaintModeScaleAspectFit:
                    [c drawImageWithScaleAspectFit:image2Draw_ci
                                            inRect:bRect
                                     withPointSize:pSize];
                    break;
                case Cap::kPaintModeScaleAspectFill:
                    [c drawImageWithScaleAspectFill:image2Draw_ci
                                             inRect:bRect
                                      withPointSize:pSize];
                    break;
            }
        }
    }
    dispatch_semaphore_signal(mSemaphore);
}

void QCvOGLWidget::resizeEvent (QResizeEvent * event)
{
    QPainter myPainter;
    myPainter.eraseRect(this->rect());
    QOpenGLWidget::resizeEvent(event);
}

void QCvOGLWidget::paintEvent(QPaintEvent* event)
{
    if (imageType == QCvGLWidget_QImage) {
        // Call base class handler to draw the bounding box of this frame.
        QPainter myPainter(this);
        //myPainter.setWorldTransform(param_matrixWorld);
        myPainter.setBackgroundMode(Qt::OpaqueMode);
        
        dispatch_semaphore_wait(mSemaphore, DISPATCH_TIME_FOREVER);
        if (doClear > 0) {
            //std::cerr << "eraseRect " << doClear << std::endl;
            myPainter.eraseRect(this->rect());
            doClear--;
        } else {
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
        }
        dispatch_semaphore_signal(mSemaphore);
    }
    QOpenGLWidget::paintEvent(event);
}

void QCvOGLWidget::draw2DWithScaleToFill(QPainter *painter)
{
    // Always draw image2Draw_qt at the center of me.
    QRect target = painter->viewport();
    QRect source = image2Draw_qt.rect();
    painter->drawImage (target, image2Draw_qt, source);
}

void QCvOGLWidget::draw2DWithoutScaling(QPainter *painter)
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

void QCvOGLWidget::draw2DWithScaleAspectFit(QPainter *painter)
{
    // Always draw image2Draw_qt at the center of me.
    QRect destRect = painter->viewport();
    QRect imgRect = image2Draw_qt.rect();
    
    double rw = (double) destRect.width() / imgRect.width();
    double rh = (double) destRect.height()/ imgRect.height();
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

void QCvOGLWidget::draw2DWithScaleAspectFill(QPainter *painter)
{
    // Always draw image2Draw_qt at the center of me.
    QRect destRect = painter->viewport();
    QRect imgRect = image2Draw_qt.rect();
    
    double rw = (double) imgRect.width() / destRect.width();
    double rh = (double) imgRect.height()/ destRect.height();
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
 QSize QCvOGLWidget::sizeHint() const
 {
	return QGLWidget::sizeHint();
 }
 */