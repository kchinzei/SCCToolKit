/*=========================================================================

  This software is distributed WITHOUT ANY WARRANTY; without even
  the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
  PURPOSE.  See the above copyright notices for more information.

=========================================================================*/

#include <cv.h>
#include <cassert>

#include <QSplashScreen>
#include <QPixmap>
#include <QTranslator>
#include <QLocale>
#include <QLibraryInfo>
#include <QtDebug>

#include "my_application.h"
#include "my_mainwindow.h"

int main(int argc, char* argv[])
{
    Application app(argc, argv);
	
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
	if(transMainWindow.load("my_mainwindow_" + QLocale::system().name(),
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
	splash->finish(app.getMainWindow());
    return app.exec();
}

