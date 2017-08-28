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

#ifndef ___ENDOVIEW_H___
#define ___ENDOVIEW_H___

#include "QCvGLWidget.h"

class EndoView : public QCvGLWidget
{
	Q_OBJECT

public:
	//EndoView(QWidget* parent = nillptr);
    EndoView(QWidget* parent = 0, const QGLWidget * shareWidget = 0, Qt::WindowFlags f = 0);
	virtual	~EndoView() override;

    void setCircleMaskVisibility(bool vis);
    bool circleMaskVisibility(void);

    void setCircleMaskDiameterRatio(float ratio);
    float circleMaskDiameterRatio(void);
    
signals:

public slots:

protected:
    virtual void resizeEvent (QResizeEvent * event) override;
	virtual void paintEvent(QPaintEvent* event) override;

    virtual void resizeGL(int w, int h) override;
    virtual void paintGL(void) override;
public:

private:
    void updateOvalClip(QPainter *painter);
    void updateOvalStencil(void);
    void setStencilVisibility(bool vis);
    
    float maskDiameterRatio;
    bool  maskVisibility;
    
    bool clippingUpdated;
};

#endif
