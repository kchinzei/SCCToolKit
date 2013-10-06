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

#ifndef ___QCVGRAPHICSVIEW_H___
#define ___QCVGRAPHICSVIEW_H___

#include "opencv2/imgproc/imgproc.hpp"
#include <QGraphicsView>
#include <dispatch/dispatch.h>
#include "CaptureTypes.h"

class QImage;


class QCvGraphicsView : public QGraphicsView
{
	Q_OBJECT

public:
	QCvGraphicsView(QWidget* parent = nullptr);
	virtual ~QCvGraphicsView() override;
    void updateImage(cv::Mat& mat);

    Cap::PaintMode paintMode;

signals:

public slots:
    void onUpdateImage(cv::Mat& mat);

protected:
	virtual void paintEvent(QPaintEvent* event) override;

private slots:

private:
    dispatch_semaphore_t mSemaphore;
    QTransform param_matrixWorld;

    QImage image2Draw_qt;
    void draw2DWithoutScaling(QPainter *painter);
    void draw2DWithScaleToFill(QPainter *painter);
    void draw2DWithScaleAspectFit(QPainter *painter);
    void draw2DWithScaleAspectFill(QPainter *painter);
};

#endif // ___MAINVIEW_H___
