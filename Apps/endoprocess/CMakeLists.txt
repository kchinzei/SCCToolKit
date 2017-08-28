#/*=========================================================================
# 
# Program:   Small Computings for Clinicals Project
# Module:    $HeadURL: $
# Date:      $Date: $
# Version:   $Revision: $
# 
# Kiyoyuki Chinzei, Ph.D.
# (c) National Institute of Advanced Industrial Science and Technology (AIST), Japan All rights reserved.
# This work is/was supported by
# * NEDO P10003 "Intelligent Surgical Instruments Project", Japan.
# * MHLW H24-Area-Norm-007 "Super Sensitive Endoscope", Japan.
# * AIST "Regulatory Science Platform" FS, Japan.
# 
# This software is distributed WITHOUT ANY WARRANTY; without even
# the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
# PURPOSE.  See the above copyright notices for more information.
# 
# =========================================================================*/

set(APP Endoprocess)

project(${APP})
cmake_minimum_required(VERSION 2.8)

FIND_PACKAGE(SCCToolKit REQUIRED)

scc_define_option(APP_MACOSX_BUNDLE "Make OSX style app bundle." ON	IF APPLE)
scc_define_option(APP_UPDATE_QT_TSFILES "Update Qt translation files (WARNING: make clean will delete the .ts files!) " OFF)

#--------------------------------------------------------------------------------
# App specific setting. Mostly you edit here.
#

set(QT_USE_QTOPENGL YES)

SET(FILES_TO_TRANSLATE)

SET(SRC_DIR src)
SET(INCLUDE_DIR ${SRC_DIR})

SET(OBJC_SRC_FILES
  ${SRC_DIR}/main.mm
  ${SRC_DIR}/Application.mm
  ${SRC_DIR}/MainWindow.mm
  ${SRC_DIR}/EndoView.mm
  #${SRC_DIR}/SettingWindow.mm
  )

SET(SRC_FILES
  ${OBJC_SRC_FILES}
  )

SET(OBJC_MOC_HDRS
  ${INCLUDE_DIR}/Application.h
  ${INCLUDE_DIR}/MainWindow.h
  ${INCLUDE_DIR}/EndoView.h
  #${INCLUDE_DIR}/SettingWindow.h
  )

SET(MOC_HDRS
  ${OBJC_MOC_HDRS}
  )

SET(OBJC_SRC_HDRS
  )

SET(SRC_HDRS
  ${INCLUDE_DIR}/ApplicationStatus.h
  ${INCLUDE_DIR}/Settings.h
  ${OBJC_SRC_HDRS}
  )

SET(UI_FILES
  ${SRC_DIR}/MainWindow.ui
  )

SET(TS_FILES
  ${SRC_DIR}/Translation_ja_JP.ts
  )

SET(QM_FILES )


#--------------------------------------------------------------------------------
# QRC files to include
#
SET(QtApp_RCCS
  ${SRC_DIR}/QResources.qrc
  )

#--------------------------------------------------------------------------------
# Other resource files to add in the target.
# ${RSRC_DIR}/*.${RSRC_EXTENSIONS} will be copied in platform-dependent places.
#
SET(RSRC_DIR
  ${CMAKE_SOURCE_DIR}/Resources
  )
SET(RSRC_EXTENSIONS
  png
)

#--------------------------------------------------------------------------------
# Application icon files will be copied in platform-dependent manner.
#
SET(APPICON icon.icns)
SET(APPICONFILE ${RSRC_DIR}/${APPICON})

# (usully you don't edit. But you may do it when necessary.)
SET(FILES_TO_TRANSLATE 
  ${FILES_TO_TRANSLATE}
  ${SRC_FILES}
  ${MOC_HDRS} 
  ${SRC_HDRS} 
  ${UI_FILES}
  )

scc_mark_as_objective_c(${OBJC_SRC_FILES} ${OBJC_SRC_HDRS} ${OBJC_MOC_HDRS})


#### Qt setting

#--------------------------------------------------------------------------------
# This sets the windows build that will need the special winmain@16 call. Qt provides
#  this for us in the qtmain.lib file. Using this cmake code will ensure we have it
#  linked into our build. Not needed on Unix/OS X/Linux which is why we have the 
#  IF(WIN32) conditional.
# cf: http://www.vtk.org/Wiki/images/2/25/QtTest-Package-Example.zip
# cf: http://www.vtk.org/Wiki/BundleUtilitiesExample
IF (WIN32)
    SET (QT_USE_QTMAIN TRUE)
ENDIF (WIN32)

#--------------------------------------------------------------------------------
# QT_USE_FILE is a variable defined by FIND_PACKAGE( Qt4 ) that contains a path to
# a CMake script that sets up this directory for building with Qt4
# Qt5 does not use it.
#
if(QT_USE_FILE)
  include(${QT_USE_FILE})
endif(QT_USE_FILE)

#--------------------------------------------------------------------------------
# this command will generate rules that will run rcc on all files from QTTEST_RCS
# in result QTTEST_GEN_RCS variable will contain paths to files produced by rcc
#
QT_ADD_RESOURCES(QtApp_RCC_SRCS ${QtApp_RCCS})
#set(CMAKE_AUTORCC ON)

#--------------------------------------------------------------------------------
# this will run uic on .ui files:
#
QT_WRAP_UI(UI_HDRS ${UI_FILES})

#--------------------------------------------------------------------------------
# and finally this will run moc on the headers
#
QT_WRAP_CPP(MOC_SRCS ${MOC_HDRS})

ADD_DEFINITIONS(${QT_DEFINITIONS})

#--------------------------------------------------------------------------------
# we include the translation files. The location needs to be hard coded in QTranslator.
#
if (APP_UPDATE_QT_TSFILES)
  qt_create_translation(
    QM_FILES
    ${FILES_TO_TRANSLATE}
    ${TS_FILES}
  )
else ()
  qt_add_translation(QM_FILES ${TS_FILES})
endif () 
add_custom_target (translations_target DEPENDS ${QM_FILES})


#--------------------------------------------------------------------------------
# For Apple set the icns file containing icons
IF(APP_MACOSX_BUNDLE)
  IF(EXISTS ${APPICONFILE})
    # set how it shows up in the Info.plist file
    SET(MACOSX_BUNDLE_ICON_FILE ${APPICON}) 
    # set where in the bundle to put the icns file
    SET_SOURCE_FILES_PROPERTIES(${APPICONFILE} PROPERTIES MACOSX_PACKAGE_LOCATION Resources)
  ELSE()
    SET(APPICONFILE )
  ENDIF()
ENDIF(APP_MACOSX_BUNDLE)

#--------------------------------------------------------------------------------
# 
IF(APP_MACOSX_BUNDLE)
  FOREACH(EXT ${RSRC_EXTENSIONS})
    FILE(GLOB RSRC_FILES ${RSRC_DIR}/*.${EXT})
    SET_SOURCE_FILES_PROPERTIES(${RSRC_FILES} PROPERTIES MACOSX_PACKAGE_LOCATION Resources)
  ENDFOREACH(EXT)
  SET_SOURCE_FILES_PROPERTIES(${QM_FILES} PROPERTIES MACOSX_PACKAGE_LOCATION MacOS)
ELSE()
  SET(RSRC_FILES )
ENDIF()

IF(APP_MACOSX_BUNDLE)
  SET(MACOSX_BUNDLE "MACOSX_BUNDLE")
ELSE()
  SET(MACOSX_BUNDLE )
ENDIF()

#--------------------------------------------------------------------------------
# Compile and link it
INCLUDE_DIRECTORIES (
  ${CMAKE_SOURCE_DIR}/${INCLUDE_DIR}
  # Look in the cmake build directory (some generated headers could be there)
  ${CMAKE_CURRENT_BINARY_DIR}
  )
ADD_EXECUTABLE(${APP} ${MACOSX_BUNDLE} 
  ${SRC_FILES} ${SRC_HDRS}
  ${MOC_SRCS} ${MOC_HDRS}
  ${UI_HDRS} 
  ${QtApp_RCC_SRCS} ${APPICONFILE} ${RSRC_FILES} ${QM_FILES})
TARGET_LINK_LIBRARIES(${APP} ${SCC_LIBS})



#--------------------------------------------------------------------------------
# Now the installation stuff below
#--------------------------------------------------------------------------------
SET(APPS "\${CMAKE_INSTALL_PREFIX}/bin/{$APP}")
IF(APP_MACOSX_BUNDLE)
  SET(plugin_dest_dir bin)
  SET(qtconf_dest_dir bin)
  SET(APPBUNDLE ${APP}.app)
  SET(plugin_dest_dir ${APPBUNDLE}/Contents/MacOS)
  SET(qtconf_dest_dir ${APPBUNDLE}/Contents/Resources)
  SET(APPS "\${CMAKE_INSTALL_PREFIX}/${APPBUNDLE}")
ENDIF()
IF(WIN32)
  SET(APPEXE ${APP}.exe)
  SET(APPS "\${CMAKE_INSTALL_PREFIX}/bin/${APPEXE}")
ENDIF()

#--------------------------------------------------------------------------------
# Install the app application, on Apple, the bundle is at the root of the
# install tree, and on other platforms it'll go into the bin directory.
INSTALL(TARGETS ${APP}
    BUNDLE DESTINATION . COMPONENT Runtime
    RUNTIME DESTINATION bin COMPONENT Runtime
    )
#--------------------------------------------------------------------------------
# Install translation
#INSTALL(FILES ${QM_FILES} DESTINATION ${plugin_dest_dir}/translations)

#--------------------------------------------------------------------------------
# Install needed Qt plugins by copying directories from the qt installation
# One can cull what gets copied by using 'REGEX "..." EXCLUDE'
#INSTALL(DIRECTORY "${QT_PLUGINS_DIR}/imageformats" DESTINATION ${plugin_dest_dir}/plugins COMPONENT Runtime)

#--------------------------------------------------------------------------------
# install a qt.conf file
# this inserts some cmake code into the install script to write the file
INSTALL(CODE "
    file(WRITE \"\${CMAKE_INSTALL_PREFIX}/${qtconf_dest_dir}/qt.conf\" \"\")
    " COMPONENT Runtime)

#--------------------------------------------------------------------------------
# Use BundleUtilities to get all other dependencies for the application to work.
# It takes a bundle or executable along with possible plugins and inspects it
# for dependencies.  If they are not system dependencies, they are copied.

# directories to look for dependencies
SET(DIRS ${OpenCV_LIB_DIR} ${QT_LIBRARY_DIR})

# Now the work of copying dependencies into the bundle/package
# The quotes are escaped and variables to use at install time have their $ escaped
# An alternative is the do a configure_file() on a script and use install(SCRIPT  ...).
# Note that the image plugins depend on QtSvg and QtXml, and it got those copied
# over.
#INSTALL(CODE "
#    file(GLOB_RECURSE QTPLUGINS
#      \"\${CMAKE_INSTALL_PREFIX}/${plugin_dest_dir}/plugins/*${CMAKE_SHARED_LIBRARY_SUFFIX}\")
#    include(BundleUtilities)
#    fixup_bundle(\"${APPS}\" \"\${QTPLUGINS}\" \"${DIRS}\")
#    " COMPONENT Runtime)
INSTALL(CODE "
    include(BundleUtilities)
    fixup_bundle(\"${APPS}\" \"\" \"${DIRS}\")
    " COMPONENT Runtime)



set(CPACK_PACKAGE_DESCRIPTION_SUMMARY
  "${APP} is a sample app of Small Computings for Clinical Project"
  )
set(CPACK_PACKAGE_DESCRIPTION_FILE ${RSRC_DIR}/Readme.txt)
set(CPACK_PACKAGE_VENDOR "Intlligent Surgical Instruments Project, AIST")
set(CPACK_PACKAGE_VERSION_MAJOR 1)
set(CPACK_PACKAGE_VERSION_MINOR 0)
set(CPACK_PACKAGE_VERSION_PATCH 0)
set(CPACK_RESOURCE_FILE_README ${RSRC_DIR}/Readme.txt)
set(CPACK_RESOURCE_FILE_WELCOME ${RSRC_DIR}/Readme.rtfd)
set(CPACK_RESOURCE_FILE_LICENSE ${RSRC_DIR}/License.txt)

set(CPACK_PACKAGING_INSTALL_PREFIX ${CMAKE_INSTALL_PREFIX})

set(CPACK_SOURCE_IGNORE_FILES "/CVS/;/.svn/;/.bzr/;/.hg/;/.git/;.swp$;.#;/#;.*~;/build*/")
# FIXME: adding 'properly' back-slash will cause 'make package_source' an error.
#set(CPACK_SOURCE_IGNORE_FILES "/CVS/;/\\.svn/;/\\.bzr/;/\\.hg/;/\\.git/;\\.swp$;\\.#;/#;.*~;/build*/")

IF(APPLE)
  # You may need to obtain PackageMaker.app
  # It is downloadable from developper.apple.com as part of "Auxiliary Tools for Xcode".
  #
  # FIXME: setting CPACK_GENERATOR to both PackageMaker and DragNDrop arises problem of CPACK_PACKAGING_INSTALL_PREFIX
  set(CPACK_GENERATOR PackageMaker)
  #set(CPACK_GENERATOR DragNDrop)
  IF(CPACK_GENERATOR EQUAL "DragNDrop")
    set(CPACK_PACKAGING_INSTALL_PREFIX)
  ELSE()
    set(CPACK_PACKAGING_INSTALL_PREFIX /Applications) # This is always good to override this way.
  ENDIF()
  set(CPACK_SOURCE_GENERATOR ZIP)
ENDIF(APPLE)

include(CPack)
