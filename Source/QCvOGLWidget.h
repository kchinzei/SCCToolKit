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

#ifndef ___QCvOGLWidget_H___
#define ___QCvOGLWidget_H___

#include "opencv2/imgproc/imgproc.hpp"
#include <QOpenGLWidget>
#include <QOpenGLFunctions>
#include <dispatch/dispatch.h>

#include "CaptureTypes.h"

class QImage;
class QOpenGLFunctions;
@class CIImage;
@class QCvGLWidget_CIImageDrower;

class QCvOGLWidget : public QOpenGLWidget
{
	Q_OBJECT

public:
	QCvOGLWidget(QWidget* parent = 0, const QOpenGLWidget * shareWidget = 0, Qt::WindowFlags f = 0);
    virtual ~QCvOGLWidget() override;
    void updateImage(cv::Mat& mat);
    void updateImage(CIImage *img);
    void clear(void);

    Cap::PaintMode paintMode;
    
signals:

public slots:
    void onUpdateImage(cv::Mat& mat);
    void onUpdateImage(CIImage *img);
    void onClear(void);

protected:
    virtual void resizeEvent(QResizeEvent * event) override;
    virtual void paintEvent(QPaintEvent* event) override;
	virtual void initializeGL(void) override;
    virtual void resizeGL(int w, int h) override;
    virtual void paintGL(void) override;
    //virtual QSize sizeHint(void) const override;
    
    enum QCvGLWidget_imageType {
        QCvGLWidget_Undef,
        QCvGLWidget_CIImage,
        QCvGLWidget_QImage
    };
    QCvGLWidget_imageType imageType;
    
    QOpenGLFunctions *pOGLFunctions;
    
private slots:

private:
    QTransform param_matrixWorld;

    QImage image2Draw_qt;
    void draw2DWithoutScaling(QPainter *painter);
    void draw2DWithScaleToFill(QPainter *painter);
    void draw2DWithScaleAspectFit(QPainter *painter);
    void draw2DWithScaleAspectFill(QPainter *painter);

    dispatch_semaphore_t mSemaphore;
    CIImage *image2Draw_ci;
    QCvGLWidget_CIImageDrower *context;
    int doClear;
};

#endif
