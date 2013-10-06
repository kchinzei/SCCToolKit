#/*=========================================================================
#
#  Program:   Small Computings for Clinicals Project
#  Module:    $HeadURL: $
#  Date:      $Date: $
#  Version:   $Revision: $
#  URL:       http://scc.pj.aist.go.jp
#
#  (c) 2013- Kiyoyuki Chinzei, Ph.D., AIST Japan, All rights reserved.
#
#  Acknowledgement: This work is/was supported by many research fundings.
#  See Acknowledgement.txt
#
#  This software is distributed WITHOUT ANY WARRANTY; without even
#  the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
#  PURPOSE.  See License.txt for license terms.
#
# =========================================================================*/

# name of libraries
SET(LIB_NAME ${SCC_LIB_NAMES})

IF(SCC_PLATFORM_WIN32) # for Windows
  SET(LINK_LIBS
    ws2_32
    wsock32
  )
ELSE(SCC_PLATFORM_WIN32) # for POSIX-compatible OSs
  SET(LINK_LIBS
    m
#    pthread
  )
ENDIF(SCC_PLATFORM_WIN32)

IF(SCC_PLATFORM_WIN32 AND SCC_BUILD_SHARED_LIBS)
  SET(CMAKE_CXX_FLAGS "-DSCCCommon_EXPORTS")
ENDIF(SCC_PLATFORM_WIN32 AND SCC_BUILD_SHARED_LIBS)


SET(SRC_FILES_OBJC
  CaptureCenter.mm
  Capture.mm
  CaptureDeckLink.mm
  CaptureQtKit.mm
  QCvGLWidget.mm
  QCvGLWidget_private.m
)

SET(SRC_FILES
  ${SRC_FILES_OBJC}
  CustomDeckLinkVideoFrame.cpp
  QCvGraphicsView.cpp
  CaptureUtils.cpp
  )

SET(MOC_HDRS_OBJC
  QCvGLWidget.h
  )

SET(MOC_PUBLIC_HDRS
  ${MOC_HDRS_OBJC}
  QCvGraphicsView.h
  )

SET(MOC_HDRS
  ${MOC_PUBLIC_HDRS}
  CaptureUtils_private.h
)

SET(SRC_PUBLIC_HDRS_OBJC
  CaptureCenter.h
  Capture.h
  CaptureTypes.h
  CaptureDeckLink.h
  CaptureQtKit.h
  CaptureUtils.h
  )

SET(SRC_PUBLIC_HDRS
  ${SRC_PUBLIC_HDRS_OBJC}
  )

SET(SRC_PRIVATE_HDRS_OBJC
  CaptureQtKit_private.h
  QCvGLWidget_private.h
  )

SET(SRC_PRIVATE_HDRS
  ${SRC_PRIVATE_HDRS_OBJC}
  CustomDeckLinkVideoFrame.h
)

SET(SRC_HDRS
  ${SRC_PUBLIC_HDRS}
  ${SRC_PRIVATE_HDRS}
  )

SET(UI_FILES
  )

SET(TS_FILES
  ${LIB_NAME}_ja_JP.ts
  )

SET(QM_FILES )

IF(APPLE)
  SET(FRAMEWORK_NAMES 
    CoreVideo
    QuartzCore
    OpenGL
    QTKit
    AppKit
    )
  scc_mark_as_objective_c (
    ${SRC_PRIVATE_HDRS_OBJC}
    ${SRC_PUBLIC_HDRS_OBJC}
    ${MOC_HDRS_OBJC}
    ${SRC_FILES_OBJC}
    )
ENDIF(APPLE)

#--------------------------------------------------------------------------------
# Qt setting

#--------------------------------------------------------------------------------
# this command will generate rules that will run rcc on all files from QTTEST_RCS
# in result QTTEST_GEN_RCS variable will contain paths to files produced by rcc
#
QT4_ADD_RESOURCES(QtApp_RCC_SRCS ${QtApp_RCCS})

#--------------------------------------------------------------------------------
# this will run uic on .ui files:
#
QT4_WRAP_UI(UI_HDRS ${UI_FILES})

#--------------------------------------------------------------------------------
# and finally this will run moc on the headers
#
QT4_WRAP_CPP(MOC_SRCS ${MOC_HDRS})

#--------------------------------------------------------------------------------
# we need this to be able to include headers produced by uic in our code
# CMAKE_BINARY_DIR holds a path to the build directory, while INCLUDE_DIRECTORIES()
#  works just like INCLUDEPATH from qmake
#
INCLUDE_DIRECTORIES (
  ${CMAKE_SOURCE_DIR}
  ${CMAKE_CURRENT_SOURCE_DIR}
  # Look in the cmake build directory (some generated headers could be there)
  ${CMAKE_CURRENT_BINARY_DIR}
)

ADD_DEFINITIONS(${QT_DEFINITIONS})

SET(FILES_TO_TRANSLATE 
  ${FILES_TO_TRANSLATE}
  ${SRC_FILES}
  ${MOC_SRCS}
  ${SRC_HDRS}
  ${MOC_HDRS}
  ${UI_FILES}
  )

#--------------------------------------------------------------------------------
# we include the translation files. The location needs to be hard coded in QTranslator.
#
if (SCC_UPDATE_QT_TSFILES)
  qt4_create_translation(
    QM_FILES
    ${FILES_TO_TRANSLATE}
    ${TS_FILES}
  )
else ()
  qt4_add_translation(QM_FILES ${TS_FILES})
endif () 
add_custom_target (translations_target DEPENDS ${QM_FILES})


#--------------------------------------------------------------------------------
# Build it.
IF(SCC_WITH_DECKLINK)
  set(SRC_FILES ${SRC_FILES} "${DeckLinkSDK_SRC_FILE}")
  include_directories("${DeckLinkSDK_INCLUDE_PATH}")
  SET(DeckLink_DEF -DDeckLinkSDK_INCLUDE_FILE=${DeckLinkSDK_INCLUDE_FILE})
  if   (COMPILE_DEFINITIONS)
    SET(COMPILE_DEFINITIONS "${COMPILE_DEFINITIONS};${DeckLinkSDK_DEF}")
  else (COMPILE_DEFINITIONS)
    SET(COMPILE_DEFINITIONS ${DeckLinkSDK_DEF})
  endif(COMPILE_DEFINITIONS)
ENDIF(SCC_WITH_DECKLINK)

ADD_LIBRARY(
  ${LIB_NAME}
  ${SRC_FILES}
  ${MOC_SRCS}
  ${UI_HDRS}
  ${QtApp_RCC_SRCS}
  ${SRC_HDRS}
  ${MOC_HDRS}
  ${QM_FILES}
)
TARGET_LINK_LIBRARIES(
  ${LIB_NAME}
  ${OpenCV_LIBS}
  #${OPENCV-EX_LIBS}
  #${OpenIGTLink_LIBRARIES}
  ${QT_LIBRARIES}
  ${LINK_LIBS}
)

#--------------------------------------------------------------------------------
# 
IF(SCC_WITH_DECKLINK)
  TARGET_LINK_LIBRARIES(${LIB_NAME}
    LINK_PUBLIC
    ${DeckLinkSDK_LIBS}
    )
ENDIF(SCC_WITH_DECKLINK)
IF(APPLE)
  FOREACH(fw ${FRAMEWORK_NAMES})
    SET(${fw}_FILE ${${fw}_FILE} CACHE INTERNAL "")
    FIND_LIBRARY(${fw}_FILE ${fw})
    SET(fw_file ${${fw}_FILE})
    TARGET_LINK_LIBRARIES(${LIB_NAME}
      LINK_PUBLIC
      ${fw_file})
  ENDFOREACH(fw)
ENDIF(APPLE)


SET_TARGET_PROPERTIES(${LIB_NAME} PROPERTIES
  VERSION ${SCC_VERSION_MAJOR}.${SCC_VERSION_MINOR}.${SCC_VERSION_PATCH}
  SOVERSION ${SCC_VERSION_MAJOR}
)


#--------------------------------------------------------------------------------
# Install
INSTALL(FILES ${SRC_PUBLIC_HDRS}
  DESTINATION ${SCC_INSTALL_INCLUDE_DIR}
  COMPONENT Development)

INSTALL(TARGETS ${LIB_NAME}
  RUNTIME DESTINATION ${SCC_INSTALL_BIN_DIR} COMPONENT RuntimeLibraries
  LIBRARY DESTINATION ${SCC_INSTALL_LIB_DIR} COMPONENT RuntimeLibraries
  ARCHIVE DESTINATION ${SCC_INSTALL_LIB_DIR} COMPONENT Development)
