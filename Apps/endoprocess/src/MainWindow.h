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
 * Main window class declarations.
 */

#ifndef ___MAINWINDOW_H___
#define ___MAINWINDOW_H___

#include <QDialog>
#include "ui_MainWindow.h"
#include "ApplicationStatus.h"

class QString;
class QVariant;

class ChromaWindow;

@class CIImage;


/**
 * Main window class.
 */
class MainWindow : public QDialog,
                   private Ui::MainWindow
{
    Q_OBJECT

public:
    MainWindow(QWidget* parent = NULL);
    virtual ~MainWindow();
    void resizeUi_and_showWindow(int screenWidth);
    int getViewH(void);
    int getViewW(void);

signals:
    void setApplicationStatus(ApplicationStatus& status);
	void reqQuit(void);

public slots:
	void onSetApplicationStatus( ApplicationStatus& status );
    void onMsgLabelUpdate(const QString* str);
    void onViewLLabelUpdate(const QString* str);
	virtual void reject();
    void onUpdateImages(CIImage *img1);
    void onEraseViewL(void);

private:
	void setConnections(void);
    
private:
	ApplicationStatus mStatus, mStatusBuf;
};

#endif // ___MAINWINDOW_H___
