/*=========================================================================
 
 Program:   Small Computings for Clinicals Project
 Module:    $HeadURL: $
 Date:      $Date: $
 Version:   $Revision: $
 
 Kiyoyuki Chinzei, Ph.D.
 (c) National Institute of Advanced Industrial Science and Technology (AIST), Japan All rights reserved.
 This work is/was supported by
 * NEDO P10003 "Intelligent Surgical Instruments Project", Japan.
 * MHLW H24-Area-Norm-007 "Super Sensitive Endoscope", Japan.
 * AIST "Regulatory Science Platform" FS, Japan.
 
 This software is distributed WITHOUT ANY WARRANTY; without even
 the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
 PURPOSE.  See the above copyright notices for more information.
 
 =========================================================================*/

#include <cassert>

#include <QSurfaceFormat>
#include <QSplashScreen>
#include <QPixmap>
#include <QTranslator>
#include <QLocale>
#include <QLibraryInfo>
#include <QtDebug>

#include "Application.h"

int main(int argc, char* argv[])
{
    Application app(argc, argv);

    QSurfaceFormat format;
    format.setDepthBufferSize(8);
    format.setStencilBufferSize(8);
    format.setProfile(QSurfaceFormat::CoreProfile);
    QSurfaceFormat::setDefaultFormat(format);
    
	// Create a splash screen.
	QPixmap pixmap(200, 100);
	pixmap.fill(Qt::blue);
	QSplashScreen* splash = new QSplashScreen(pixmap);
	splash->show();
	splash->showMessage("Initializing...", Qt::AlignCenter, Qt::white);
	
	// Internationalize the application.
	app.processEvents();
	QTranslator transSys;
	if(transSys.load("qt_" + QLocale::system().name(),
					 QLibraryInfo::location(
						 QLibraryInfo::TranslationsPath
					 ))) {
		app.installTranslator(&transSys);
	} else {
		qWarning()
			<< "Failed to load system translation file for locale: "
			<< QLocale::system().name();
	}

	app.processEvents();
	QTranslator transMainWindow;
	if(transMainWindow.load("Translation_" + QLocale::system().name(),
							 QCoreApplication::applicationDirPath())) {
		app.installTranslator(&transMainWindow);
	} else {
		qWarning()
			<< "Failed to load main window translation file for locale: "
			<< QLocale::system().name();
	}

	// Initialize the application.
	app.processEvents();
    app.initialize();

	// Run the application.
	splash->finish((QWidget *)app.getMainWindow());
    return app.exec();
}

