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
/**
 * @file
 * Main window class implementations.
 */

#include <QSettings>
#include <QtDebug>

#include <opencv2/core/core.hpp>
#include "MainWindow.h"
#include "Settings.h"

#define BUFLEN 1024

MainWindow::MainWindow(QWidget* parent)
    : QDialog (parent)
{
    // Set up the UI generated by Designer.
    setupUi(this);
    viewL->paintMode = Cap::kPaintModeScaleAspectFill;
    viewL->setCircleMaskVisibility(true);
    viewL->clear();
    
	setConnections();
}


MainWindow::~MainWindow()
{
}

void MainWindow::resizeUi_and_showWindow(int screenWidth)
{
    if (screenWidth <= 1280) {
        this->showFullScreen();
    } else {
        this->show();
    }
}

int MainWindow::getViewH(void)
{
    QRect r = viewL->geometry();
    QSize s = r.size();
    return s.height();
}

int MainWindow::getViewW(void)
{
    QRect r = viewL->geometry();
    QSize s = r.size();
    return s.width();
}

// PUBLIC SLOTS ////////////////////////////////////////////////////////
//
void MainWindow::onSetApplicationStatus( ApplicationStatus& status )
{
	mStatus = status;
}

void MainWindow::onMsgLabelUpdate(const QString* str)
{
    QString s = (str == nullptr)? QString("") : *str;
    label_msg->setText(s);
}

void MainWindow::onViewLLabelUpdate(const QString* str)
{
    QString s1 = QString(tr("Camera 1 : "));
    if (str) s1 += *str;
    label_camname1->setText(s1);
}

//
// "Quit"
//
void MainWindow::reject()
{
	emit reqQuit();
}

void MainWindow::onUpdateImages(CIImage *img1)
{
    viewL->updateImage(img1);
}

void MainWindow::onEraseViewL(void)
{
    viewL->update(viewL->rect());
}

// PRIVATE METHODS /////////////////////////////////////////////////////
//
// Set signal-slot connections.
//
void MainWindow::setConnections(void)
{
}
