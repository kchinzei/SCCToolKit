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
set(APP capturecenter2)

project(${APP})

SET(FILES_TO_TRANSLATE)

SET(SRC_FILES
  main.mm
  )

SET(MOC_HDRS
  )

SET(SRC_HDRS
  )

SET(UI_FILES
  )

SET(TS_FILES
  )

SET(QM_FILES )

scc_mark_as_objective_c(main.mm)

#--------------------------------------------------------------------------------
# QRC files to include
#
SET(QtApp_RCCS
  )

#--------------------------------------------------------------------------------
# Other resource files to add in the target.
# ${RSRC_DIR}/*.${RSRC_EXTENSIONS} will be copied in platform-dependent places.
#
#SET(RSRC_DIR
#  ${CMAKE_SOURCE_DIR}/Resources
#  )
#SET(RSRC_EXTENSIONS
#  png
#)

#--------------------------------------------------------------------------------
# Application icon files will be copied in platform-dependent manner.
#
#SET(APPICON
#  icon.icns
#  )
#SET(APPICONFILE
#  ${RSRC_DIR}/${APPICON}
#  )

# (usully you don't edit. But you may do it when necessary.)
SET(FILES_TO_TRANSLATE 
  ${FILES_TO_TRANSLATE}
  ${SRC_FILES}
  ${MOC_HDRS} 
  ${SRC_HDRS} 
  ${UI_FILES}
  )


#--------------------------------------------------------------------------------
# QT_USE_FILE is a variable defined by FIND_PACKAGE( Qt4 ) that contains a path to
# a CMake script that sets up this directory for building with Qt4
#
if(QT_USE_FILE)
  include(${QT_USE_FILE})
endif(QT_USE_FILE)

#--------------------------------------------------------------------------------
# this command will generate rules that will run rcc on all files from QTTEST_RCS
# in result QTTEST_GEN_RCS variable will contain paths to files produced by rcc
#
#QT4_ADD_RESOURCES(QtApp_RCC_SRCS ${QtApp_RCCS})
set(auto_rcc ON)

#--------------------------------------------------------------------------------
# this will run uic on .ui files:
#
#QT4_WRAP_UI(UI_HDRS ${UI_FILES})
set(auti_uic ON)

#--------------------------------------------------------------------------------
# and finally this will run moc on the headers
#
QT_WRAP_CPP(MOC_SRCS ${MOC_HDRS})

#--------------------------------------------------------------------------------
# we need this to be able to include headers produced by uic in our code
# CMAKE_BINARY_DIR holds a path to the build directory, while INCLUDE_DIRECTORIES()
#  works just like INCLUDEPATH from qmake
#
INCLUDE_DIRECTORIES (
  ${CMAKE_SOURCE_DIR}/${INCLUDE_DIR}
  # Look in the cmake build directory (some generated headers could be there)
  ${CMAKE_CURRENT_BINARY_DIR}
)

ADD_DEFINITIONS(${QT_DEFINITIONS})

#--------------------------------------------------------------------------------
# Input directory
INCLUDE_DIRECTORIES(${CMAKE_CURRENT_SOURCE_DIR})

#--------------------------------------------------------------------------------
# and finally compile and link everything
#
ADD_EXECUTABLE(${APP} ${SRC_FILES} ${MOC_SRCS} ${UI_HDRS} ${QtApp_RCC_SRCS} ${MOC_HDRS} ${SRC_HDRS} ${APPICONFILE} ${RSRC_FILES} ${QM_FILES})
TARGET_LINK_LIBRARIES(${APP} ${SCC_TARGET_LIBS})
