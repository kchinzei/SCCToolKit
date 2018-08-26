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

#include "EndoView.h"

#include <QPainter>

// Below is for test&debug purposes
#include <QtDebug>
#include <cassert>

//EndoView::EndoView(QWidget* parent)
EndoView::EndoView(QWidget* parent, const QOpenGLWidget * shareWidget, Qt::WindowFlags f)
	: QCvOGLWidget(parent, shareWidget, f)
    , maskXShiftRatio(0.0)
    , maskYShiftRatio(0.0)
    , maskDiameterRatio(1.0)
    , maskVisibility(false)
    , clippingUpdated(false)
{
    setObjectName(QString::fromUtf8("EndoView"));
}


EndoView::~EndoView()
{
}

/*
 Simple policy: do semaphore check in public methods.
 (Otherwise, dead-locking can happen.)
 */

void EndoView::setCircleMaskVisibility(bool vis)
{
    maskVisibility = vis;
    clippingUpdated = true;
}

bool EndoView::circleMaskVisibility(void)
{
    return maskVisibility;
}

void EndoView::setCircleMaskXShiftRatio(float rx)
{
    if (-1.0 <= rx && rx <= 1.0 && rx != maskXShiftRatio) {
        maskXShiftRatio = rx;
        clippingUpdated = true;
    }
}

float EndoView::circleMaskXShiftRatio(void)
{
    return maskXShiftRatio;
}

void EndoView::setCircleMaskYShiftRatio(float ry)
{
    if (-1.0 <= ry && ry <= 1.0 && ry != maskYShiftRatio) {
        maskYShiftRatio = ry;
        clippingUpdated = true;
    }
}

float EndoView::circleMaskYShiftRatio(void)
{
    return maskYShiftRatio;
}

void EndoView::setCircleMaskDiameterRatio(float ratio)
{
    if (0.0 <= ratio && ratio != maskDiameterRatio) {
        maskDiameterRatio = ratio;
        clippingUpdated = true;
    }
}

float EndoView::circleMaskDiameterRatio(void)
{
    return maskDiameterRatio;
}


// PROTECTED METHODS ///////////////////////////////////////////////////
//

void EndoView::resizeGL(int w, int h)
{
    clippingUpdated = true;
    QCvOGLWidget::resizeGL(w, h);
}

void EndoView::paintGL(void)
{
    if (imageType == QCvGLWidget_CIImage) {
        if (clippingUpdated) {
            updateOvalStencil();
            setStencilVisibility(maskVisibility);
            clippingUpdated = false;
        }
    }
    QCvOGLWidget::paintGL();
}


void EndoView::paintEvent(QPaintEvent* event)
{
    if (imageType == QCvGLWidget_QImage) {
        if (clippingUpdated) {
            QPainter myPainter(this);
            updateOvalClip(&myPainter);
            clippingUpdated = false;
        }
    }
    QCvOGLWidget::paintEvent(event);
}

void EndoView::resizeEvent( QResizeEvent * event )
{
    clippingUpdated = true;
    QCvOGLWidget::resizeEvent(event);
}

// PRIVATE METHODS ///////////////////////////////////////////////////
//
void EndoView::updateOvalClip(QPainter *painter)
{
    int cx = 0, cy = 0, radius = 0;
    
    getCircleParameters(&cy, &cy, &radius);
    
    setBackgroundRole(QPalette::Shadow);
    QRegion rgn(cx - radius, cy - radius, radius*2, radius*2, QRegion::Ellipse);
    painter->setClipRegion(rgn);
    painter->setClipping(maskVisibility);
}

void EndoView::getCircleParameters(int *cx, int *cy, int *radius)
{
    float w = width();
    float h = height();
    float diameter = (w < h)? w : h;
    
    diameter *= maskDiameterRatio;
    *radius = (int)diameter/2;
    *cx = (int)(w/2 + w*maskXShiftRatio);
    *cy = (int)(h/2 + h*maskYShiftRatio);
}

#define STENCIL_FALSE 0
#define STENCIL_TRUE  1

void EndoView::updateOvalStencil(void)
{
    int cx = 0, cy = 0, radius = 0;
    
    getCircleParameters(&cx, &cy, &radius);

    pOGLFunctions->glClearStencil(STENCIL_FALSE);
    pOGLFunctions->glClear(GL_STENCIL_BUFFER_BIT);

    pOGLFunctions->glEnable(GL_STENCIL_TEST); // Activate stencil
    pOGLFunctions->glColorMask(GL_FALSE, GL_FALSE, GL_FALSE, GL_FALSE);
    
    pOGLFunctions->glStencilMask(STENCIL_TRUE);
    pOGLFunctions->glStencilOp(GL_KEEP, GL_REPLACE, GL_REPLACE);
    pOGLFunctions->glStencilFunc(GL_ALWAYS, STENCIL_TRUE, ~0);
    
    // Make stencil region
    // FIXME: glBegin()/End() are obsolate. GL_POLYGON is slow.
    // FIXME: rewrite it to use buffer copy.
    glBegin(GL_POLYGON);
#define NSTEP 180
#define PI 3.1415926
    for (int i=0; i<NSTEP; i++) {
        float x = cx + radius * cos(2*PI/NSTEP*i);
        float y = cy + radius * sin(2*PI/NSTEP*i);
        glVertex2f(x, y);
    }
    glEnd();
    
    // Restore
    pOGLFunctions->glColorMask(GL_TRUE, GL_TRUE, GL_TRUE, GL_TRUE);
    pOGLFunctions->glStencilOp(GL_KEEP, GL_KEEP , GL_KEEP);
    pOGLFunctions->glStencilMask(STENCIL_FALSE);
    pOGLFunctions->glDisable(GL_STENCIL_TEST);
}

void EndoView::setStencilVisibility(bool vis)
{
    if (vis) {
        pOGLFunctions->glEnable(GL_STENCIL_TEST);
        pOGLFunctions->glStencilOp(GL_KEEP, GL_KEEP , GL_KEEP);
        pOGLFunctions->glStencilFunc(GL_EQUAL, STENCIL_TRUE, ~0);
    } else {
        pOGLFunctions->glDisable(GL_STENCIL_TEST);
        pOGLFunctions->glStencilOp(GL_KEEP, GL_KEEP , GL_KEEP);
        pOGLFunctions->glStencilFunc(GL_ALWAYS, STENCIL_TRUE, ~0);
    }
}
