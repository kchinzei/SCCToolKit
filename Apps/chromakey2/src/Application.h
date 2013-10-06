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

#ifndef ___APPLICATION_H___
#define ___APPLICATION_H___

#include <QApplication>
#include "ApplicationStatus.h"
#include <dispatch/dispatch.h>

#include <QMessageBox>
#include "CaptureCenter.h"

class MainWindow;
class QSettings;
@class CIImage;
@class CvChromakey;

/**
 * Application class.
 */
class Application : public QApplication, public Cap::CaptureCenter
{
    Q_OBJECT

public:
    Application(int& argc, char* argv[]);
    virtual ~Application();

    void imagesArrived(Cap::Capture *capture) override;
    void stateChanged(Cap::Capture* capture) override;

signals:
    void setApplicationStatus(ApplicationStatus& status);
    void reqUpdateImages(CIImage *img1, CIImage *img2);
    void reqViewLLabelUpdate(const QString* str);
    void reqViewRLabelUpdate(const QString* str);
    void reqMsgLabelUpdate(const QString* str);
    void reqEraseViewL(void);
    void reqEraseViewR(void);

public slots:
	void onSetApplicationStatus(ApplicationStatus& status);
	void onReqQuit(void);
    
public:
	MainWindow* getMainWindow(void) { return mWindow; }
    void initialize(void);

private:
	void createWindows(void);
    void updateMessageBox(QMessageBox::Icon icon, const char *msg);
    void saveSettings();
    void readSettings();
    int  readSettings_CapType(int idx);
    QString readSettings_CapUniqueID(int idx);
    static void myMessageOutput(QtMsgType type, const char *msg);

private:
	ApplicationStatus mStatus;
    MainWindow* mWindow;
	QSettings   *mSettings;
    CvChromakey *mChromakey;
    dispatch_queue_t mMainQueue;
};

#endif // ___APPLICATION_H___CV
