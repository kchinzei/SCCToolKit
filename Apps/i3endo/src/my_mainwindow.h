/*=========================================================================

  This software is distributed WITHOUT ANY WARRANTY; without even
  the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
  PURPOSE.  See the above copyright notices for more information.

=========================================================================*/
/**
 * @file
 * Main window class declarations.
 */

#ifndef ___MAINWINDOW_H___
#define ___MAINWINDOW_H___

#include <QDialog>
#include "ui_my_mainwindow.h"
#include "ApplicationStatus.h"

class cv::Mat;
class QComboBox;
class QString;
class QVariant;

/**
 * Main window class.
 */
class MainWindow : public QDialog,
                   private Ui::MainWindow
{
    Q_OBJECT

public:
    MainWindow(QWidget* parent = NULL);
    virtual
    ~MainWindow();

signals:
    void setApplicationStatus(ApplicationStatus& status);
	void reqQuit(void);

	/**
	 * Notify image to the image frame
	 */
	void reqUpdateImage(cv::Mat& mat);
	void reqUpdateImageR(cv::Mat& mat);
	void reqUpdateImageL(cv::Mat& mat);
	
public slots:
	void onSetApplicationStatus( ApplicationStatus& status );
    void on_sliderEndoAxis_valueChanged(int val);
    void on_btnResetAvg_clicked();
    void on_btnUpdate_clicked();
    void onTimerUpdate();
    void onMsgUpdate(const char *str);

	/**
	 * Notify image to the image frame
	 */
	void onUpdateImage(cv::Mat& mat);
	void onUpdateImageR(cv::Mat& mat);
	void onUpdateImageL(cv::Mat& mat);
	virtual void reject();

private:
	void setConnections(void);
    void setComboBox(QComboBox* cb, const QString& str, unsigned val);
    unsigned getValueFromComboBox(const QComboBox* cb);
    void setComboBoxFromValue(QComboBox* cb, unsigned val);
    
private:
	ApplicationStatus mStatus;

//    int imageWidth, imageHeight;
};

#endif // ___MAINWINDOW_H___
