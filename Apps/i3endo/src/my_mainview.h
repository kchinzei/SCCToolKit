/*=========================================================================

  This software is distributed WITHOUT ANY WARRANTY; without even
  the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
  PURPOSE.  See the above copyright notices for more information.

=========================================================================*/

#ifndef ___MAINVIEW_H___
#define ___MAINVIEW_H___

#include "opencv2/imgproc/imgproc.hpp"
#include <QGraphicsView>
#include <dispatch/dispatch.h>

class QImage;
class cv::Mat;


class MainView : public QGraphicsView
{
	Q_OBJECT

public:
	MainView(QWidget* parent = NULL);
	virtual	~MainView();

signals:

public slots:
    void onUpdateImage(cv::Mat& mat);

protected:
	virtual void paintEvent(QPaintEvent* event);

private slots:

public:
    QPoint  srcCenter;
    int     srcWidth;
    int     srcHeight;
    bool    largeClip;
    
private:
    //parameters (will be save/load)
    QTransform param_matrixWorld;

	CvMat* image2Draw_mat;
    QImage image2Draw_qt;
    
    QRect  srcRect;  // 切り出す領域．arrの範囲を出るかも
    QRect  srcVisRect; // 常にarrの範囲内
    
    int    destWidth;   // = size().width()
    int    destHeight;  // = size().height()
    bool   resized;

    void onUpdateImage1(const cv::Mat& mat);
    void onUpdateImage2(const cv::Mat& mat);
    void onUpdateImage3(cv::Mat& mat);
    void onUpdateImage4(const cv::Mat& mat);
    cv::Mat *prevMat;

	void draw2D1(QPainter *painter);
    void draw2D2(QPainter *painter);
    void draw2D3(QPainter *painter);
    void draw2D4(QPainter *painter);

    void updateOvalClip(QPainter *painter);

    QSize sizeHint() const;
    void resizeEvent ( QResizeEvent * event );
    
//    dispatch_queue_t mBkgndQueue;
};

#endif // ___MAINVIEW_H___
