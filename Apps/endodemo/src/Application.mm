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

#include <iostream>
#include "Application.h"
#include "Settings.h"

#include <cxcore.h>
#include <cassert>

#include <QtGlobal>
#include <QtDebug>
#include <QSettings>
#include <QMessageBox>
#include <QDesktopWidget>
  
#include <stdexcept>
#if QT_VERSION >= 0x050000
#include <qlogging.h>
#else
#include <qapplication.h>   // For qInstallMsgHandler()
#endif

#include "MainWindow.h"
#include "CaptureUtils.h"

#include "CaptureQtKit.h"   // Debug purpose only
#include "CaptureDeckLink.h"   // Debug purpose only

#define nCameras 1

#include <iostream>
#include <string>
//#include <boost/asio.hpp>
//#include "server/server.hpp"

static Application *gApp;

Application::Application(int& argc, char* argv[])
	: QApplication(argc, argv)
    , mStatus()
	, mWindow(nullptr)
	, mSettings(nullptr)
{
	// Prepare to use QSettings
	QCoreApplication::setOrganizationName(kSettingsKey_Organization);
	QCoreApplication::setOrganizationDomain(kSettingsKey_Domain);
	QCoreApplication::setApplicationName(kSettingsKey_Application);
    mSettings = new QSettings();
    readSettings();

    mMainQueue = dispatch_get_main_queue();
    //setApplicationStatus(mStatus);
    
    gApp = this;
}

Application::~Application()
{
    this->stop();
    saveSettings();
	if ( mWindow ) delete mWindow;
}



// PUBLIC SLOTS ////////////////////////////////////////////////////////
//
//
void Application::onSetApplicationStatus( ApplicationStatus& status )
{
 	mStatus = status;
}


void Application::onReqQuit(void)
{
/*
	if (mStatus.calibration.needCalibrationSaved) {
		switch(QMessageBox::question(mWindow,
									 tr("Confirmation"),
									 tr("Do you quit without saving calibration result?"),
									 QMessageBox::Cancel | QMessageBox::Discard | QMessageBox::Save,
									 QMessageBox::Save)) {
		case QMessageBox::Cancel:
			break;
		case QMessageBox::Save:
			onReqSaveCalibInfo();
			if (mStatus.calibration.needCalibrationSaved)
				return;
			emit quit();
			break;
		case QMessageBox::Discard:
			emit quit();
			break;
        default:
                break;
		}
	} else {
		emit quit();
	}
*/
	emit quit();
}

// PUBLIC METHODS //////////////////////////////////////////////////////

void Application::imagesArrived(Cap::Capture* capture)
{
    for (int i=0; i<nCameras; i++) {
		CIImage *pimg = captures[i]->retrieveCIImage();
		if (captures[i]->isReady()) {
			dispatch_async(mMainQueue, ^{
					captures[i]->lock();
					emit(reqUpdateImages(pimg));
					captures[i]->unlock();
				});
		}
    }
}

void Application::stateChanged(Cap::Capture* capture)
{
    static QString cname[nCameras];
    const QString* str;

    // Which camera is it?
    int i;
    for (i=0; i<nCameras; i++) {
        if (captures[i] == capture) break;
    }

    switch (capture->state) {
        case Cap::kCaptureState_Active:
        case Cap::kCaptureState_Inactive:
            // Normal. Just display the name of the camera.
            if (cname[i].length() == 0)
                cname[i] = QString(capture->mModelName);
            str = &cname[i];
            if (i == 2) str = nullptr;
            break;
        default:
            str = captureStateQString(capture->state, capture->mModelName);
    }
    dispatch_async(mMainQueue, ^{
        switch (i) {
            case 0:
                emit reqViewLLabelUpdate(str);
                emit reqEraseViewL();
                break;
            case 1:
                emit reqMsgLabelUpdate(str) ;
                break;
        }
    });
}

//
// Initialize the application.
//
void Application::initialize(void)
{
    // ENTRY DIAGNOSIS:
    assert(mWindow == NULL);    // It might be called twice if these fail.

    /*
    dispatch_queue_t queue_server = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue_server, ^{
        // Initialise the server.
        http::server::server s(readSettings_StdString(kSettingsKey_ServerIP),
                               readSettings_StdString(kSettingsKey_ServerPort),
                               this);
        // Set document root = a directory containing files to be served.
        set_document_root(readSettings_StdString(kSettingsKey_ServerRootDir));
        // Run the server until stopped.
        s.run();
    });
*/
    
    // Create the main window (and other) and show it.
	createWindows();
#if QT_VERSION >= 0x050000
	qInstallMessageHandler((QtMessageHandler)myMessageOutput);
#else
    qInstallMsgHandler(myMessageOutput);
#endif
    int h = mWindow->getViewH();
    int w = mWindow->getViewW();
    
    if (mStatus.desiredFPS > 0) {
        useSoftwareTimer = true;
        setDesiredFPS(mStatus.desiredFPS);
    }

    for (int i=0; i<nCameras; i++) {
        Cap::CaptureType type = (Cap::CaptureType) readSettings_CapType(i);
        //Cap::CaptureType type = Cap::kCaptureTypeQtKit;
        //if (type == Cap::kCaptureTypeUndefined)
        type = Cap::kCaptureTypeDeckLink;
        //type = Cap::kCaptureTypeQtKit;

        
        Cap::Capture *cap;
        cap = this->addCapture(type);
        if (cap == nullptr) {
            //std::cerr << "Fail to create capture #" << i << std::endl;
            return;
        }
        
        //Cap::CaptureDeckLink *cdk = (Cap::CaptureDeckLink *)cap;

		Cap::CaptureQtKit *cqk = (Cap::CaptureQtKit *)cap;
        cqk->mUseInternalCameras = true;

        //const char *c = readSettings_CapUniqueID(i).toAscii().data();
        //strlcpy(cap->mUniqueID, c, kCaptureBufLen);

        if (cap->init() == false) {
            //std::cerr << "Fail to open capture #" << i << std::endl;
            return;
        }
        //std::cerr << "Capture[" << i << "] : " << cap->mModelName << std::endl;
        if (w > h*1.5)
            cap->setDesiredWidth(w);
        else
            cap->setDesiredHeight(h);
    }
    this->start();
}

void Application::saveSettings()
{
    mSettings->setValue(kSettingsKey_Cap_DesiredFPS, (int) mStatus.desiredFPS);
    mSettings->beginWriteArray(kSettingsKey_Capture);
    for (int i=0; i<nCameras; i++) {
        Cap::Capture *cap = captures[i];
        mSettings->setArrayIndex(i);
        mSettings->setValue(kSettingsKey_Cap_CaptureType, (int)cap->getCaptureType());
        mSettings->setValue(kSettingsKey_Cap_UniqueIDStr, cap->mUniqueID);
    }
    mSettings->endArray();
    mSettings->sync();
}

void Application::readSettings()
{
    /*
    QVariant v = mSettings->value(kSettingsKey_DeckLink_DeviceName, "");
    QString qDeviceName = v.toString();
    strlcpy(mModelName, (const char*)qDeviceName.unicode(), BUFLEN_MODELNAME);
    */
    
    mStatus.desiredFPS = mSettings->value(kSettingsKey_Cap_DesiredFPS, mStatus.desiredFPS).toFloat();
}

int Application::readSettings_CapType(int idx)
{
    int capType;
    mSettings->beginReadArray(kSettingsKey_Capture);
    mSettings->setArrayIndex(idx);
    capType = mSettings->value(kSettingsKey_Cap_CaptureType, (int)Cap::kCaptureTypeUndefined).toInt();
    mSettings->endArray();
    return capType;
}
    
QString Application::readSettings_CapUniqueID(int idx)
{
    QString str;
    mSettings->beginReadArray(kSettingsKey_Capture);
    mSettings->setArrayIndex(idx);
    str = mSettings->value(kSettingsKey_Cap_UniqueIDStr, "").toString();
    mSettings->endArray();
    return str;
}

std::string Application::readSettings_StdString(const char *keystr)
{
    QVariant v = mSettings->value(keystr, "");
    QString qstr = v.toString();
    return qstr.toStdString();
}

/*
void Application::handle_request(const http::server::request& req, http::server::reply& rep, std::shared_ptr<http::server::connection> sp_connection)
{
    http::server::connection* pconnection = sp_connection.get();
    
    // Decode url to path.
    std::string request_path;
    if (!url_decode(req.uri, request_path))
    {
        rep = reply::stock_reply(http::server::reply::bad_request);
        pconnection->do_write();
        return;
    }
    
    // Request path must be absolute and not contain "..".
    if (request_path.empty() || request_path[0] != '/'
        || request_path.find("..") != std::string::npos)
    {
        rep = reply::stock_reply(http::server::reply::bad_request);
        pconnection->do_write();
        return;
    }
    
    // K.Chinzei: If request path contains...
    std::string vstream_token = "/videostream";
    if (request_path == vstream_token) {
        // Our special request handler.
        pconnection->do_write();
        return;
    }

}
*/

// PRIVATE SLOTS ////////////////////////////////////////

// PRIVATE METHODS //////////////////////////////////////
// Create windows.
//
void Application::createWindows(void)
{
    mWindow = new MainWindow();

	//---------------------------------------------------
	// Signal Application >>>>> Slot MainWindow.
	//---------------------------------------------------
	connect(this, SIGNAL(setApplicationStatus(ApplicationStatus&)),
			mWindow, SLOT(onSetApplicationStatus(ApplicationStatus&)));
    connect(this, SIGNAL(reqUpdateImages(CIImage *)),
			mWindow, SLOT(onUpdateImages(CIImage *)));
    connect(this, SIGNAL(reqViewLLabelUpdate(const QString*)),
			mWindow, SLOT(onViewLLabelUpdate(const QString*)));
    connect(this, SIGNAL(reqMsgLabelUpdate(const QString*)),
			mWindow, SLOT(onMsgLabelUpdate(const QString*)));
    connect(this, SIGNAL(reqEraseViewL(void)),
			mWindow, SLOT(onEraseViewL(void)));
   

	//-------------------------------------------------------------
	// Signal MainWindow >>>>> Slot Application.
	//-------------------------------------------------------------
	connect(mWindow, SIGNAL(setApplicationStatus(ApplicationStatus&)),
			this, SLOT(onSetApplicationStatus(ApplicationStatus&)));
	connect(mWindow, SIGNAL(reqQuit(void)),
			this, SLOT(onReqQuit(void)));

	// Show the main window.
	emit setApplicationStatus( mStatus );

    QRect desktopRect = QApplication::desktop()->screenGeometry();
    mWindow->resizeUi_and_showWindow(desktopRect.size().width());
}

#define STR_LEN 256

void Application::updateMessageBox(QMessageBox::Icon icon, const char *msg)
{
    static QMessageBox::Icon prevIcon = QMessageBox::NoIcon;
    static char prevStr[STR_LEN], str[STR_LEN];
    //static QMessageBox *msgbox = nullptr;
    static QString *msgstr = nullptr;
    
    strlcpy(str, msg, STR_LEN);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        const char *s = str;
        if (strnlen(s, STR_LEN) < 5)
            s = "";
        if (prevIcon != icon || strncmp(prevStr, s, STR_LEN-1)) {
            /*
            if (msgbox == NULL) {
                msgbox = new QMessageBox(icon, QString("Warning"), QString(""), QMessageBox::NoButton, 0, Qt::Dialog);
            }
             */
            if (msgstr) delete msgstr;
            msgstr = new QString(s);
            if (s[0] == '\0') {
                emit reqMsgLabelUpdate(msgstr);
                //msgbox->hide();
            } else {
                /*
                msgbox->setIcon(icon);
                msgbox->setText(s);
                msgbox->show();
                */
                emit reqMsgLabelUpdate(msgstr);
            }
            strlcpy(prevStr, s, STR_LEN);
            prevIcon = icon;
        }
    });
}

#if QT_VERSION >= 0x050000
void Application::myMessageOutput(QtMsgType type, const QMessageLogContext &context, const QString &msg)
{
	QByteArray localMsg = msg.toLocal8Bit();
    switch (type) {
        case QtInfoMsg:
            std::cerr << "Info: " << localMsg.constData();
            break;
        case QtDebugMsg:
            std::cerr << "Debug: " << localMsg.constData();
            break;
        case QtWarningMsg:
            gApp->updateMessageBox(QMessageBox::Warning, localMsg.constData());
            break;
        case QtCriticalMsg:
            gApp->updateMessageBox(QMessageBox::Critical, localMsg.constData());
            break;
        case QtFatalMsg:
            std::cerr << "Fatal: " << localMsg.constData();
            abort();
    }
}

#else
void Application::myMessageOutput(QtMsgType type, const char *msg)
{
    switch (type) {
        case QtDebugMsg:
            std::cerr << "Debug: " << msg;
            break;
        case QtWarningMsg:
            gApp->updateMessageBox(QMessageBox::Warning, msg);
            break;
        case QtCriticalMsg:
            gApp->updateMessageBox(QMessageBox::Critical, msg);
            break;
        case QtFatalMsg:
            std::cerr << "Fatal: " << msg;
            abort();
    }
}
#endif
