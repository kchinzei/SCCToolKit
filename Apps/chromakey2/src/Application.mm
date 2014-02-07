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
#include <qapplication.h>   // For qInstallMsgHandler()

#include "MainWindow.h"
#include "CaptureUtils.h"
#import "CvChromakey.h"

#include "CaptureQtKit.h"   // Debug purpose only

#define nCameras 3

static Application *gApp;

Application::Application(int& argc, char* argv[])
	: QApplication(argc, argv)
    , mStatus()
	, mWindow(nullptr)
	, mSettings(nullptr)
    , mChromakey(nil)
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
    if (status.hueMin != mStatus.hueMin)
        mChromakey.minHueAngle = status.hueMin;
    if (status.hueMax != mStatus.hueMax)
        mChromakey.maxHueAngle = status.hueMax;
    if (status.valMin != mStatus.valMin)
        mChromakey.minValue = status.valMin;
    if (status.valMax != mStatus.valMax)
        mChromakey.maxValue = status.valMax;
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
    CIImage *img[nCameras];

    for (int i=0; i<nCameras; i++) {
        img[i] = captures[i]->retrieveCIImage();
        captures[i]->lock();
    }
    
    CIImage *img0, *img1, *imgOut; // It's necessary for a block to handle array object outside block.
    
    img0 = img[0];
    img1 = img[1];
    if (!captures[1]->isReady())
        img1 = img0;
    if (!captures[0]->isReady())
        img0 = img1;

    if (captures[2]->isReady()) {
        imgOut = [mChromakey updateFilter:img[2] withBkgnd:(mStatus.adjustChromaMode)? nil : img1];
    } else {
        imgOut = img1;
    }
    dispatch_async(mMainQueue, ^{
        emit(reqUpdateImages(img0, imgOut));
    });
    
    for (int i=0; i<nCameras; i++) {
        captures[i]->unlock();
    }
/*
    for (int i=0; i<nCameras; i++) {
        img[i] = captures[i]->retrieveCIImage();
        captures[i]->lock();
    }
    
    CIImage *img0 = img[0]; // It's necessary for a block to handle array object outside block.
    CIImage *imgOut;
    if (captures[2]->isReady()) {
        imgOut = [mChromakey updateFilter:img[2] withBkgnd:(mStatus.adjustChromaMode)? nil : img[1]];
    } else {
        imgOut = img[1];
    }
    dispatch_async(mMainQueue, ^{
        emit(reqUpdateImages(img0, imgOut));
    });

    for (int i=0; i<nCameras; i++) {
        captures[i]->unlock();
    }
*/
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
                emit reqViewRLabelUpdate(str) ;
                emit reqEraseViewR();
                break;
            case 2:
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

    mChromakey = [[CvChromakey alloc] initWithHueAngles:mStatus.hueMin
                                                     to:mStatus.hueMax
                                           withMinValue:mStatus.valMin/256.0
                                           withMaxValue:mStatus.valMax/256.0];

    // Create the main window (and other) and show it.
	createWindows();
    qInstallMsgHandler(myMessageOutput);
    int h = mWindow->getViewH();
    int w = mWindow->getViewW();
    
    if (mStatus.desiredFPS > 0) {
        useSoftwareTimer = true;
        setDesiredFPS(mStatus.desiredFPS);
    }

    for (int i=0; i<nCameras; i++) {
        Cap::CaptureType type = (Cap::CaptureType) readSettings_CapType(i);
        //Cap::CaptureType type = Cap::kCaptureTypeQtKit;
        if (type == Cap::kCaptureTypeUndefined)
            type = Cap::kCaptureTypeQtKit;
        
        Cap::Capture *cap;
        cap = this->addCapture(type);
        if (cap == nullptr) {
            //std::cerr << "Fail to create capture #" << i << std::endl;
            return;
        }
        
        Cap::CaptureQtKit *cqk = (Cap::CaptureQtKit *)cap;
        cqk->mUseInternalCameras = false;
        
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
    mSettings->setValue(kSettingsKey_ChromaHueMin, (int) mStatus.hueMin);
    mSettings->setValue(kSettingsKey_ChromaHueMax, (int) mStatus.hueMax);
    mSettings->setValue(kSettingsKey_ChromaValMin, (int) mStatus.valMin);
    mSettings->setValue(kSettingsKey_ChromaValMax, (int) mStatus.valMax);
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

    mStatus.hueMin = mSettings->value(kSettingsKey_ChromaHueMin, mStatus.hueMin).toFloat();
    mStatus.hueMax = mSettings->value(kSettingsKey_ChromaHueMax, mStatus.hueMax).toFloat();
    mStatus.valMin = mSettings->value(kSettingsKey_ChromaValMin, mStatus.valMin).toFloat();
    mStatus.hueMax = mSettings->value(kSettingsKey_ChromaValMax, mStatus.hueMax).toFloat();
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
    connect(this, SIGNAL(reqUpdateImages(CIImage *, CIImage *)),
			mWindow, SLOT(onUpdateImages(CIImage *, CIImage *)));
    connect(this, SIGNAL(reqViewLLabelUpdate(const QString*)),
			mWindow, SLOT(onViewLLabelUpdate(const QString*)));
    connect(this, SIGNAL(reqViewRLabelUpdate(const QString*)),
			mWindow, SLOT(onViewRLabelUpdate(const QString*)));
    connect(this, SIGNAL(reqMsgLabelUpdate(const QString*)),
			mWindow, SLOT(onMsgLabelUpdate(const QString*)));
    connect(this, SIGNAL(reqEraseViewL(void)),
			mWindow, SLOT(onEraseViewL(void)));
    connect(this, SIGNAL(reqEraseViewR(void)),
			mWindow, SLOT(onEraseViewR(void)));
   

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
