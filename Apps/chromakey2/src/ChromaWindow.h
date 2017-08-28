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

#ifndef ___CHROMAWINDOW_H___
#define ___CHROMAWINDOW_H___

#include <QDialog>
#include "ui_ChromaWindow.h"

/**
 * Main window class.
 */
class ChromaWindow : public QDialog,
					 private Ui::ChromaDialog
{
    Q_OBJECT

public:
    ChromaWindow(QWidget* parent = NULL);
    virtual ~ChromaWindow();

protected:
	
signals:
	void reqUpdateChroma(float hueMin, float hueMax, float valMin, float valMax);
    void reqAcceptChroma(void);
	void reqRevertChroma(void);
    void reqRejectChromaWindow(void);
    
public slots:
	void on_buttonBox_rejected(void);
	void on_buttonBox_clicked(QAbstractButton* button);
    void onUpdateChromaImage(CIImage *mat);
    void onUpdateChroma(float hueMin, float hueMax, float valMin, float valMax);
    void onUpdateValues(void);
	virtual void reject();

public:
    float mHueMin, mHueMax, mValMin, mValMax;

private:
};

#endif
