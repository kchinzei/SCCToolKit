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
EndoView::EndoView(QWidget* parent, const QGLWidget * shareWidget, Qt::WindowFlags f)
	: QCvGLWidget(parent, shareWidget, f)
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

void EndoView::setCircleMaskDiameterRatio(float ratio)
{
    if (0.0 <= ratio && ratio <= 1.0 && ratio != maskDiameterRatio) {
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
    QCvGLWidget::resizeGL(w, h);
}

void EndoView::paintGL(void)
{
    if (imageType == QCvGLWidget_CIImage) {
        if (clippingUpdated) {
            updateOvalStencil();
            setStencilVisibility(maskVisibility);
            clippingUpdated = false;
        }
        QCvGLWidget::paintGL();
    }
}


void EndoView::paintEvent(QPaintEvent* event)
{
    if (imageType == QCvGLWidget_QImage) {
        if (clippingUpdated) {
            QPainter myPainter(this);
            updateOvalClip(&myPainter);
            clippingUpdated = false;
        }
        QCvGLWidget::paintEvent(event);
    }
}

void EndoView::resizeEvent( QResizeEvent * event )
{
    QCvGLWidget::resizeEvent(event);
}

// PRIVATE METHODS ///////////////////////////////////////////////////
//
void EndoView::updateOvalClip(QPainter *painter)
{
    int w = width();
    int h = height();
    
    int diameter = (w < h)? w : h;
    diameter *= maskDiameterRatio;
    int w0 = (w - diameter) / 2;
    int h0 = (h - diameter) / 2;

    setBackgroundRole(QPalette::Shadow);
    QRegion rgn(w0, h0, diameter, diameter, QRegion::Ellipse);
    painter->setClipRegion(rgn);
    painter->setClipping(maskVisibility);
}

#define STENCIL_FALSE 0
#define STENCIL_TRUE  1

void EndoView::updateOvalStencil(void)
{
    float w = width();
    float h = height();

    float diameter = (w < h)? w : h;
    diameter *= maskDiameterRatio;
    float radius = diameter / 2;

    glClearStencil(STENCIL_FALSE);
    glClear(GL_STENCIL_BUFFER_BIT);

    glEnable(GL_STENCIL_TEST); // Activate stencil
    glColorMask(GL_FALSE, GL_FALSE, GL_FALSE, GL_FALSE);
    
    glStencilMask(STENCIL_TRUE);
    glStencilOp(GL_KEEP, GL_REPLACE, GL_REPLACE);
    glStencilFunc(GL_ALWAYS, STENCIL_TRUE, ~0);
    
    // Make stencil region
    // FIXME: glBegin()/End() are obsolate. GL_POLYGON is slow.
    // FIXME: rewrite it to use buffer copy.
    glBegin(GL_POLYGON);
#define NSTEP 180
#define PI 3.1415926
    for (int i=0; i<NSTEP; i++) {
        float x = w/2 + radius * cos(2*PI/NSTEP*i);
        float y = h/2 + radius * sin(2*PI/NSTEP*i);
        glVertex2f(x, y);
    }
    glEnd();
    
    // Restore
    glColorMask(GL_TRUE, GL_TRUE, GL_TRUE, GL_TRUE);
    glStencilOp(GL_KEEP, GL_KEEP , GL_KEEP);
    glStencilMask(STENCIL_FALSE);
    glDisable(GL_STENCIL_TEST);
}

void EndoView::setStencilVisibility(bool vis)
{
    if (vis) {
        glEnable(GL_STENCIL_TEST);
        glStencilOp(GL_KEEP, GL_KEEP , GL_KEEP);
        glStencilFunc(GL_EQUAL, STENCIL_TRUE, ~0);
    } else {
        glDisable(GL_STENCIL_TEST);
        glStencilOp(GL_KEEP, GL_KEEP , GL_KEEP);
        glStencilFunc(GL_ALWAYS, STENCIL_TRUE, ~0);
    }
}
