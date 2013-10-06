/*=========================================================================

  This software is distributed WITHOUT ANY WARRANTY; without even
  the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
  PURPOSE.  See the above copyright notices for more information.

=========================================================================*/
#include "my_application.h"
#include "my_settings.h"

#include <cxcore.h>
#include <cassert>

#include <QTime>
#include <QTimer>
#include <QSettings>
#include <QMessageBox>
#include <QDesktopWidget>
#include <QtDebug>

#include <stdexcept>
#include "my_mainwindow.h"

#include "timerSingleton.h"

#define kFPS 30

kDrawMode gDrawMode = kNativeYUVConversion_CvFlip;

Application::Application(int& argc, char* argv[])
	: QApplication(argc, argv)
    , ImageSourceDeckLink()
    //, ImageSourceCvCapture()
	, mWindow(NULL)
	, mSettings(NULL)
{
	// Prepare to use QSettings
	QCoreApplication::setOrganizationName(kSettingsKey_Organization);
	QCoreApplication::setOrganizationDomain(kSettingsKey_Domain);
	QCoreApplication::setApplicationName(kSettingsKey_Application);
    mSettings = new QSettings();
    readSettings();

    //if (ImageSourceCvCapture::initialize(argc, argv))
    if (ImageSourceDeckLink::initialize(argc, argv))
        exit(-1);
    
    mStatus.nConcurrentTasks = mConcurrentTasks;
    mStatus.inputPixelMode   = mPixelFormat;
    mStatus.inputFormatMode  = mDisplayMode;
    mStatus.drawMode         = gDrawMode;
    setApplicationStatus(mStatus);
}

Application::~Application()
{
    ImageSourceDeckLink::imageStop();
    //ImageSourceCvCapture::imageStop();
    saveSettings();
	if ( mWindow ) delete mWindow;
}


void Application::imageArrived(cv::Mat *mat)
{
    /*
     It's not best place to modify it...
     */
    ImageSourceDeckLink::mNativeYUVConversion = (gDrawMode & kNativeYUVConversionBit);
    
    dispatch_async(mMainQueue, ^{
        switch (gDrawMode) {
            case kNativeYUVConversion_CvFlip:
            case kNativeYUVConversion_QtFlip:
            case kNativeYUVConversion_MyFlip:
                emit reqUpdateImage(*mat);
                break;
            case kMyYUVConversion_CvCopy:
            case kMyYUVConversion_QtCopy:
            case kMyYUVConversion_MyCopy:
                cv::Rect_<int> rectR(mStatus.srcCenterR.x()-mStatus.srcSizeR.width()/2,
                                     mStatus.srcCenterR.y()-mStatus.srcSizeR.height()/2,
                                     mStatus.srcSizeR.width(),
                                     mStatus.srcSizeR.height());
                cv::Mat *r = imageClone(*mat, rectR, 1);
                cv::Rect_<int> rectL(mStatus.srcCenterL.x()-mStatus.srcSizeL.width()/2,
                                     mStatus.srcCenterL.y()-mStatus.srcSizeL.height()/2,
                                     mStatus.srcSizeL.width(),
                                     mStatus.srcSizeL.height());
                cv::Mat *l = imageClone(*mat, rectL, 1);
                emit reqUpdateImageL(*l);
                emit reqUpdateImageR(*r);
                if (gDrawMode != kMyYUVConversion_QtCopy) {
                    delete l;
                    delete r;
                }
                break;
        }
        delete mat;
    });
}


// PUBLIC SLOTS ////////////////////////////////////////////////////////
//
//
void Application::onSetApplicationStatus( ApplicationStatus& status )
{
    if (mStatus.inputPixelMode != status.inputPixelMode ||
        mStatus.inputFormatMode != status.inputFormatMode ||
        mStatus.drawMode != status.drawMode) {
        imageStop();
        mConcurrentTasks = status.nConcurrentTasks;
        gDrawMode = status.drawMode;
        mDisplayMode = status.inputFormatMode;
        mPixelFormat = status.inputPixelMode;
        mNativeYUVConversion = status.drawMode & kNativeYUVConversionBit;
        if (ImageSourceDeckLink::initialize() == S_OK)
            imageStart();
        saveSettings();
    }
    if (mStatus.endoAxis != status.endoAxis) {
        // FIXME: code it.
    }
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
//
// Initialize the application.
//
void Application::initialize(void)
{
    // ENTRY DIAGNOSIS:
    assert(mWindow == NULL);    // It might be called twice if these fail.

    // Shinko 3eye endoscope image in 1920x1080
    mStatus.srcSizeL = QSize(524, 524);
    mStatus.srcCenterL = QPoint(596, 194);
    mStatus.srcSizeR = QSize(524, 524);
    //mStatus.srcCenterR = QPoint(352, 188);
    mStatus.srcCenterR = QPoint(1352, 188);
    
    mStatus.drawMode = gDrawMode;
    mStatus.inputFormatMode = bmdModeHD1080i5994;
    mStatus.inputPixelMode = bmdFormat8BitYUV;

    // Create the main window (and other) and show it.
	createWindows();
    qInstallMsgHandler(myMessageOutput);
    
    mMainQueue = dispatch_get_main_queue();

    // This timer is to do performance measurement.
    (void) timerSingleton::sharedInstance();
    mTimer = new QTimer(this);
	connect(mTimer, SIGNAL(timeout(void)),
			this, SLOT(onTimeout(void)));
	mTimer->start(1000);

    imageStart();
}

void Application::saveSettings()
{
    mSettings->setValue(kSettingsKey_DeckLink_DeviceName, mModelName);
    mSettings->setValue(kSettingsKey_DeckLink_InputFormat, mDisplayMode);
	mSettings->setValue(kSettingsKey_DeckLink_InputPixel, mPixelFormat);
	mSettings->setValue(kSettingsKey_AlgorithmIndex, gDrawMode);
	mSettings->setValue(kSettingsKey_nCouncurrentTasks, mConcurrentTasks);
	mSettings->sync();
}

void Application::readSettings()
{
	QVariant v;

    v = mSettings->value(kSettingsKey_DeckLink_DeviceName, "");
    QString qDeviceName = v.toString();
    strlcpy(mModelName, (const char*)qDeviceName.unicode(), BUFLEN_MODELNAME);
    
    v = mSettings->value(kSettingsKey_DeckLink_InputFormat, mDisplayMode);
    mDisplayMode = v.toUInt();
    v = mSettings->value(kSettingsKey_DeckLink_InputPixel, mPixelFormat);
    mPixelFormat = v.toUInt();
    v = mSettings->value(kSettingsKey_AlgorithmIndex, gDrawMode);
    gDrawMode = (kDrawMode) v.toInt();
    v = mSettings->value(kSettingsKey_nCouncurrentTasks, mConcurrentTasks);
    mConcurrentTasks = v.toUInt();
    
}


void Application::onTimeout(void)
{
    timerSingleton *t = timerSingleton::sharedInstance();
    t->startMeasure = true;
    emit reqTimerUpdate();
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


    connect(this, SIGNAL(reqUpdateImage(cv::Mat&)),
			mWindow, SLOT(onUpdateImage(cv::Mat&)));
    connect(this, SIGNAL(reqUpdateImageL(cv::Mat&)),
			mWindow, SLOT(onUpdateImageL(cv::Mat&)));
    connect(this, SIGNAL(reqUpdateImageR(cv::Mat&)),
			mWindow, SLOT(onUpdateImageR(cv::Mat&)));

	//connect(this, SIGNAL(reqUpdateStereoImage(const cv::Mat&, const cv::Mat&)),
	//		mWindow, SLOT(onUpdateStereoImage(const cv::Mat&, const cv::Mat&)));

	connect(this, SIGNAL(setApplicationStatus(ApplicationStatus&)),
			mWindow, SLOT(onSetApplicationStatus(ApplicationStatus&)));
	connect(this, SIGNAL(reqTimerUpdate()),
			mWindow, SLOT(onTimerUpdate()));
	connect(this, SIGNAL(reqMsgUpdate(const char *)),
			mWindow, SLOT(onMsgUpdate(const char *)));
    

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
    if (desktopRect.size().width() <= 1024 && desktopRect.size().height() <= 768)
        mWindow->showFullScreen();
    else
        mWindow->show();
}

#define STR_LEN 256

void Application::updateMessageBox(QMessageBox::Icon icon, const char *msg)
{
    static QMessageBox::Icon prevIcon = QMessageBox::NoIcon;
    static char prevStr[STR_LEN], str[STR_LEN];
    static QMessageBox *msgbox = NULL;
    
    strlcpy(str, msg, STR_LEN);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        const char *s = str;
        if (strnlen(s, STR_LEN) < 5)
            s = "";
        if (prevIcon != icon || strncmp(prevStr, s, STR_LEN-1)) {
            if (msgbox == NULL) {
                msgbox = new QMessageBox(icon, QString("Warning"), QString(""), QMessageBox::NoButton, 0, Qt::Dialog);
            }
            if (s[0] == '\0') {
                emit reqMsgUpdate(s);
                // msgbox->hide();
            } else {
                /*
                msgbox->setIcon(icon);
                msgbox->setText(s);
                msgbox->show();
                 */
                emit reqMsgUpdate(s);
            }
            strlcpy(prevStr, s, STR_LEN);
            prevIcon = icon;
        }
    });
}

void Application::myMessageOutput(QtMsgType type, const char *msg)
{
    Application *a = dynamic_cast<Application *>(qApp);
    
    switch (type) {
        case QtDebugMsg:
            std::cerr << "Debug: " << msg;
            break;
        case QtWarningMsg:
            a->updateMessageBox(QMessageBox::Warning, msg);
            //std::cerr << "Warning: " << strlen(msg) << " " << msg;
            break;
        case QtCriticalMsg:
            a->updateMessageBox(QMessageBox::Critical, msg);
            //std::cerr << "Critical: " << strlen(msg) << " " << msg;
            break;
        case QtFatalMsg:
            std::cerr << "Fatal: " << msg;
            abort();
    }
}
