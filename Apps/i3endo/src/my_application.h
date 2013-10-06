/*=========================================================================

  This software is distributed WITHOUT ANY WARRANTY; without even
  the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
  PURPOSE.  See the above copyright notices for more information.

=========================================================================*/

#ifndef ___APPLICATION_H___
#define ___APPLICATION_H___

#include "opencv2/highgui/highgui.hpp"

#include <QApplication>
#include <qapplication.h>   // For qInstallMsgHandler()
#include "ApplicationStatus.h"
#include <dispatch/dispatch.h>

#include "ImageSourceDeckLink.h"
#include "ImageSourceCvCapture.h"
#include <QMessageBox>

class MainWindow;
class QSettings;
class QTimer;
class cv::Mat;

/**
 * Application class.
 */
//class Application : public QApplication, public ImageSourceCvCapture
class Application : public QApplication, public ImageSourceDeckLink
{
    Q_OBJECT

public:
    Application(int& argc, char* argv[]);
    virtual ~Application();

signals:
    void setApplicationStatus(ApplicationStatus& status);
	void reqUpdateImage(cv::Mat& mat);
    void reqUpdateImageR(cv::Mat& mat);
	void reqUpdateImageL(cv::Mat& mat);
	void reqUpdateStereoImage(const cv::Mat& lMat, const cv::Mat& rMat);
    void reqTimerUpdate(void);
    void reqMsgUpdate(const char *str);

public slots:
	void onSetApplicationStatus(ApplicationStatus& status);
	void onReqQuit(void);
    
private slots:
    void onTimeout(void);
    
public:
	MainWindow* getMainWindow(void) { return mWindow; }
    void initialize(void);

private:
	void createWindows(void);
    void imageArrived(cv::Mat *mat);
    void updateMessageBox(QMessageBox::Icon icon, const char *msg);
    void saveSettings();
    void readSettings();
    static void myMessageOutput(QtMsgType type, const char *msg);

private:
    MainWindow* mWindow;
	ApplicationStatus mStatus;
	QSettings   *mSettings;
    
    dispatch_queue_t mMainQueue;
    
    QTimer  *mTimer;
};

#endif // ___APPLICATION_H___CV
