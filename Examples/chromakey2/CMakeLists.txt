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

set(APP chromakey2)

project(${APP})

SET(FILES_TO_TRANSLATE)

SET(SRC_DIR src)
SET(INCLUDE_DIR ${SRC_DIR})

SET(OBJC_SRC_FILES
  ${SRC_DIR}/main.mm
  ${SRC_DIR}/Application.mm
  ${SRC_DIR}/MainWindow.mm
  ${SRC_DIR}/ChromaWindow.mm
  ${SRC_DIR}/EndoView.mm
  ${SRC_DIR}/CvChromakey.m
  )

SET(SRC_FILES
  ${OBJC_SRC_FILES}
  )

SET(OBJC_MOC_HDRS
  ${INCLUDE_DIR}/Application.h
  ${INCLUDE_DIR}/MainWindow.h
  ${INCLUDE_DIR}/EndoView.h
  ${INCLUDE_DIR}/ChromaWindow.h
  )

SET(MOC_HDRS
  ${OBJC_MOC_HDRS}
  )

SET(OBJC_SRC_HDRS
  ${INCLUDE_DIR}/CvChromakey.h
  )

SET(SRC_HDRS
  ${INCLUDE_DIR}/ApplicationStatus.h
  ${INCLUDE_DIR}/Settings.h
  ${OBJC_SRC_HDRS}
  )

SET(UI_FILES
  ${SRC_DIR}/MainWindow_1024.ui
  ${SRC_DIR}/ChromaWindow.ui
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

set(QT_USE_QTOPENGL YES)

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

qt4_add_translation(QM_FILES ${TS_FILES})
#add_custom_target (translations_target DEPENDS ${QM_FILES})


SET(MACOSX_BUNDLE )

#--------------------------------------------------------------------------------
# Compile and link it
INCLUDE_DIRECTORIES (
  ${CMAKE_CURRENT_SOURCE_DIR}/${INCLUDE_DIR}
  # Look in the cmake build directory (some generated headers could be there)
  ${CMAKE_CURRENT_BINARY_DIR}
  )
ADD_EXECUTABLE(${APP} ${MACOSX_BUNDLE} 
  ${SRC_FILES} ${SRC_HDRS}
  ${MOC_SRCS} ${MOC_HDRS}
  ${UI_HDRS} 
  ${QtApp_RCC_SRCS} ${QM_FILES})
TARGET_LINK_LIBRARIES(${APP} ${SCC_TARGET_LIBS})
