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
class Application : public QApplication, public Cap::CaptureCenter //, public http::server::request_handler
{
    Q_OBJECT

public:
    Application(int& argc, char* argv[]);
    virtual ~Application();

    void imagesArrived(Cap::Capture *capture) override;
    void stateChanged(Cap::Capture* capture) override;

signals:
    void setApplicationStatus(ApplicationStatus& status);
    void reqUpdateImages(CIImage *img);
    void reqViewLLabelUpdate(const QString* str);
    void reqMsgLabelUpdate(const QString* str);
    void reqEraseViewL(void);

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
    std::string readSettings_StdString(const char *keystr);

    // request_handler
    /// Handle a request and produce a reply.
//    handle_request(const http::server::request& req, http::server::reply& rep, std::shared_ptr<http::server::connection> sp_connection);

#if QT_VERSION >= 0x050000
	class QMessageLogContext;
	static void myMessageOutput(QtMsgType type, const QMessageLogContext &context, const QString &msg);
#else
    static void myMessageOutput(QtMsgType type, const char *msg);
#endif
	
private:
	ApplicationStatus mStatus;
    MainWindow* mWindow;
	QSettings   *mSettings;
    dispatch_queue_t mMainQueue;
};

#endif // ___APPLICATION_H___CV
