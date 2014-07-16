#/*=========================================================================
# 
# Program:   Small Computings for Clinicals Project
# Module:    $HeadURL: $
# Date:      $Date: $
# Version:   $Revision: $
# 
# Kiyoyuki Chinzei, Ph.D.
# (c) National Institute of Advanced Industrial Science and Technology (AIST), Japan All rights reserved.
# Acknowledgement: This work is/was supported by many research fundings.
# See Acknowledgement.txt
# 
# This software is distributed WITHOUT ANY WARRANTY; without even
# the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
# PURPOSE.  See the above copyright notices for more information.
# 
# =========================================================================*/

PROJECT( SCC )

cmake_minimum_required(VERSION 2.8.10)

SET(SCC_CMAKE_DIR "${SCC_SOURCE_DIR}/CMake")
SET(CMAKE_MODULE_PATH "${SCC_CMAKE_DIR}" ${CMAKE_MODULE_PATH})
INCLUDE(${SCC_CMAKE_DIR}/SCCToolKitUtils.cmake)

#ENABLE_TESTING()
#INCLUDE (${CMAKE_ROOT}/Modules/Dart.cmake)

#-----------------------------------------------------------------------------
# Version number
set(SCC_VERSION_MAJOR "1")
set(SCC_VERSION_MINOR "0")
set(SCC_VERSION_PATCH "0")
set(SCC_VERSION ${SCC_VERSION_MAJOR}.${SCC_VERSION_MINOR}.${SCC_VERSION_PATCH})

#set(SCC_DLLVERSION ${SCC_VERSION_MAJOR}${SCC_VERSION_MINOR}${SCC_VERSION_PATCH})

#-----------------------------------------------------------------------------
# Build configuration options.
# define_option() foound in SCCUtils.cmake
# define_option(<option_variable> "help string describing the option" <initial value or boolean expression> [IF <condition>])
scc_define_option(SCC_BUILD_SHARED_LIBS "Build shared libraries."					OFF)
scc_define_option(SCC_BUILD_EXAMPLES	"Build example programs. Apps are not built by turning on it."	ON)
scc_define_option(SCC_BUILD_DOCUMENTS   "Build SCCToolKit Documentation by Doxygen"			OFF)

scc_define_option(SCC_CONFIG_ALLINONE   "SCCToolKitConfig.cmake includes external include/lib files."	ON)

scc_define_option(SCC_WITH_DISPATCH	"Use Grand Central Dispatch (libdispatch) (OSX only)."		ON	IF APPLE)
scc_define_option(SCC_WITH_CIIMAGE	"Use CIImage extension (OSX only)."				ON	IF APPLE)
scc_define_option(SCC_WITH_DECKLINK	"Use BlckMagicDesign's DeckLink extension. The SDK required."	ON)
scc_define_option(SCC_QT_MAJOR_VERSION	"Desired Qt version. If OpenCV built with Qt, that one used."	4	TYPE STRING)

#-----------------------------------------------------------------------------
# Dependent modules for SCCToolKit:
# You can copy the following into your CMakeLists.txt

FIND_PACKAGE(OpenCV REQUIRED)
#FIND_PACKAGE(OpenCV-EX QUIET)
#FIND_PACKAGE(OpenIGTLink QUIET)

IF(SCC_WITH_DECKLINK)
  FIND_PACKAGE(DeckLinkSDK REQUIRED)
ENDIF(SCC_WITH_DECKLINK)

# Try to find Qt. If OpenCV was built with Qt, we use it. Read OpenCV's cache
# This may change SCC_QT_MAJOR_VERSION
scc_read_opencv_config()

# Try to find our version.
IF(SCC_QT_MAJOR_VERSION EQUAL 4)
  SET(QT_USE_QTOPENGL YES)
  FIND_PACKAGE(Qt4 4.7 REQUIRED QtCore QtGui QtOpenGL)
  IF(QT4_FOUND)
    INCLUDE(${QT_USE_FILE})
  ENDIF(QT4_FOUND)
  INCLUDE("${SCC_CMAKE_DIR}/Qt4MacrosExtra.cmake")
  INCLUDE("${SCC_CMAKE_DIR}/QtMacrosExtra.cmake")
ELSEIF(SCC_QT_MAJOR_VERSION EQUAL 5)
  FIND_PACKAGE(Qt5Core)
  # First of all we need to find Qt5Core.
  # If it's not found, cmake asks user gives the path. Once Qt5Core is found, scc_read_opencv_config() can guess others.
  if(Qt5Core_FOUND)
    scc_guess_qt5module_dir(Qt5Gui)
    scc_guess_qt5module_dir(Qt5Widgets)
    scc_guess_qt5module_dir(Qt5OpenGL)
    scc_guess_qt5module_dir(Qt5Concurrent)
    scc_guess_qt5module_dir(Qt5LinguistTools)
    FIND_PACKAGE(Qt5Gui REQUIRED)
    FIND_PACKAGE(Qt5Widgets REQUIRED)
    FIND_PACKAGE(Qt5OpenGL REQUIRED)
    FIND_PACKAGE(Qt5Concurrent REQUIRED)
    FIND_PACKAGE(Qt5LinguistTools REQUIRED)
    if(Qt5Gui_FOUND AND Qt5Widgets_FOUND AND Qt5Concurrent_FOUND AND Qt5OpenGL_FOUND AND Qt5LinguistTools_FOUND)
      set(QT5_FOUND ON)
      include("${SCC_CMAKE_DIR}/Qt5MacrosExtra.cmake")
      include("${SCC_CMAKE_DIR}/QtMacrosExtra.cmake")
      set(QT_LIBRARIES Qt5::Core Qt5::Gui Qt5::Widgets Qt5::OpenGL Qt5::Concurrent)
    else()
      message(FATAL_ERROR "Some of Qt5 modules not found even though Qt5Core was found. Qt5 installation may have problem.")
    endif()
  endif()
ENDIF()

IF(QT4_FOUND OR QT5_FOUND)
  scc_define_option(SCC_UPDATE_QT_TSFILES "Compile Qt translation files (WARNING: don't leave it ON.) "   OFF)
ENDIF()

#IF(OpenIGTLink_FOUND)
#  INCLUDE("${OpenIGTLink_USE_FILE}")
#ENDIF(OpenIGTLink_FOUND)

#-----------------------------------------------------------------------------
# Output directories.

IF(NOT LIBRARY_OUTPUT_PATH)
  SET (LIBRARY_OUTPUT_PATH ${SCC_BINARY_DIR}/bin CACHE INTERNAL "Single output directory for building all libraries.")
ENDIF(NOT LIBRARY_OUTPUT_PATH)
IF(NOT EXECUTABLE_OUTPUT_PATH)
  SET (EXECUTABLE_OUTPUT_PATH ${SCC_BINARY_DIR}/bin CACHE INTERNAL "Single output directory for building all executables.")
ENDIF(NOT EXECUTABLE_OUTPUT_PATH)
MARK_AS_ADVANCED(LIBRARY_OUTPUT_PATH EXECUTABLE_OUTPUT_PATH)

SET(SCC_LIBRARY_PATH "${LIBRARY_OUTPUT_PATH}")
SET(SCC_EXECUTABLE_PATH "${EXECUTABLE_OUTPUT_PATH}")

#-----------------------------------------------------------------------------
# Installation vars.
# SCC_INSTALL_BIN_DIR          - binary dir (executables)
# SCC_INSTALL_LIB_DIR          - library dir (libs)
# SCC_INSTALL_DATA_DIR         - share dir (say, examples, data, etc)
# SCC_INSTALL_INCLUDE_DIR      - include dir (headers)
# SCC_INSTALL_PACKAGE_DIR      - package/export configuration files
# SCC_INSTALL_NO_DEVELOPMENT   - do not install development files
# SCC_INSTALL_NO_RUNTIME       - do not install runtime files
# SCC_INSTALL_NO_DOCUMENTATION - do not install documentation files

IF(NOT SCC_INSTALL_BIN_DIR)
  SET(SCC_INSTALL_BIN_DIR "bin")
ENDIF(NOT SCC_INSTALL_BIN_DIR)

IF(NOT SCC_INSTALL_LIB_DIR)
  SET(SCC_INSTALL_LIB_DIR "lib/scc")
ENDIF(NOT SCC_INSTALL_LIB_DIR)

IF(NOT SCC_INSTALL_DATA_DIR)
  SET(SCC_INSTALL_DATA_DIR "share/scc")
ENDIF(NOT SCC_INSTALL_DATA_DIR)

IF(NOT SCC_INSTALL_INCLUDE_DIR)
  SET(SCC_INSTALL_INCLUDE_DIR "include/scc")
ENDIF(NOT SCC_INSTALL_INCLUDE_DIR)

IF(NOT SCC_INSTALL_CMAKE_DIR)
  SET(SCC_INSTALL_CMAKE_DIR "share/scc/cmake")
ENDIF(NOT SCC_INSTALL_CMAKE_DIR)

IF(NOT SCC_INSTALL_PACKAGE_DIR)
  SET(SCC_INSTALL_PACKAGE_DIR ${SCC_INSTALL_LIB_DIR}
    CACHE INTERNAL "")
ENDIF(NOT SCC_INSTALL_PACKAGE_DIR)

IF(NOT SCC_INSTALL_NO_DOCUMENTATION)
  SET(SCC_INSTALL_NO_DOCUMENTATION 0)
ENDIF(NOT SCC_INSTALL_NO_DOCUMENTATION)

SET(SCC_DIR "${CMAKE_BINARY_DIR}" CACHE INTERNAL "SCCToolKit dir to be used by subprojects")

#-----------------------------------------------------------------------------
# Include directories
SET(SCC_INCLUDE_DIRS_BUILD_TREE ${SCC_INCLUDE_DIRS_BUILD_TREE}
  "${SCC_BINARY_DIR}"
  "${SCC_SOURCE_DIR}/Source"
)
INCLUDE_DIRECTORIES(${SCC_INCLUDE_DIRS_BUILD_TREE})

# ====================================================================
# Link libraries: e.g.   libSCCToolKit110.so, ...110.lib ...110d.lib, etc...
SET(SCC_LIB_NAMES SCCToolKit)
SET(SCC_LIBS "")
foreach(__LIB ${SCC_LIB_NAMES})
  # CMake>=2.6 supports the notation "debug XXd optimized XX"
  SET(SCC_LIBS ${SCC_LIBS} debug ${__LIB}${SCC_DLLVERSION}${SCC_DEBUG_POSTFIX} optimized ${__LIB}${SCC_DLLVERSION})
endforeach(__LIB)

LINK_DIRECTORIES("${SCC_LIBRARY_PATH}")

SET(SCC_EXTERNAL_LIBS 
	${OpenCV_LIBS}
	${QT_LIBRARIES}
#	${OPENCV-EX_LIBS}
#	${OpenIGTLink_LIBRARIES}
)

IF(APPLE)
  SET(FRAMEWORK_NAMES 
    CoreVideo
    QuartzCore
    OpenGL
    QTKit
    AppKit
    )
  FOREACH(fw ${FRAMEWORK_NAMES})
    SET(tmp SCC_FRAMEWORK_${fw})
    FIND_LIBRARY(${tmp} ${fw})
    SET(SCC_EXTERNAL_LIBS ${SCC_EXTERNAL_LIBS} "${${tmp}}")
    MARK_AS_ADVANCED(${tmp})
  ENDFOREACH(fw)
ENDIF(APPLE)

SET(SCC_TARGET_LIBS 
	${SCC_LIB_NAMES}
	${SCC_EXTERNAL_LIBS}
	)

#-----------------------------------------------------------------------------
# Add compiler flags SCCToolKit needs to work on this platform.  
IF(NOT SCC_BUILD_SHARED_LIBS)
  SET(CMAKE_CXX_FLAGS "-DSCC_Static")
ENDIF(NOT SCC_BUILD_SHARED_LIBS)
SET(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${SCC_REQUIRED_C_FLAGS}")
SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${SCC_REQUIRED_CXX_FLAGS}")
SET(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} ${SCC_REQUIRED_LINK_FLAGS}")
SET(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} ${SCC_REQUIRED_LINK_FLAGS}")
SET(CMAKE_MODULE_LINKER_FLAGS "${CMAKE_MODULE_LINKER_FLAGS} ${SCC_REQUIRED_LINK_FLAGS}")

#-----------------------------------------------------------------------------
# Summary platform information.
INCLUDE(${SCC_CMAKE_DIR}/SCCToolKitConfigPlatform.cmake)
CONFIGURE_FILE(${SCC_CMAKE_DIR}/SCCToolKitConfigure.h.in 
  ${SCC_BINARY_DIR}/SCCToolKitConfigure.h)

#-----------------------------------------------------------------------------
# Help other projects use SCCToolKit.
# Create the SCCToolKitConfig.cmake file containing the SCCToolKit configuration.
# 1. For configuration that directly refers to this build
get_property(SCC_INCLUDE_DIRECTORIES DIRECTORY PROPERTY INCLUDE_DIRECTORIES)
get_property(SCC_LINK_DIRECTORIES    DIRECTORY PROPERTY LINK_DIRECTORIES)
if(SCC_CONFIG_ALLINONE)
  set(CMAKE_INCLUDE_DIRS_CONFIGCMAKE ${SCC_INCLUDE_DIRECTORIES})
  set(CMAKE_LIB_DIRS_CONFIGCMAKE ${SCC_LINK_DIRECTORIES})
  set(SCC_LIBS_CONFIGCMAKE ${SCC_LIBS} ${SCC_EXTERNAL_LIBS})
else()
  set(CMAKE_INCLUDE_DIRS_CONFIGCMAKE ${SCC_INCLUDE_DIRS_BUILD_TREE})
  set(CMAKE_LIB_DIRS_CONFIGCMAKE ${LIBRARY_OUTPUT_PATH})
  set(SCC_LIBS_CONFIGCMAKE ${SCC_LIBS})
endif()
set(SCC_CMAKE_DIR_CONFIGCMAKE "${SCC_CMAKE_DIR}")
set(SCC_CONFIG_FILE_BUILD "${SCC_BINARY_DIR}/SCCToolKitConfig.cmake")
configure_file("${SCC_CMAKE_DIR}/SCCToolKitConfig.cmake.in"
               ${SCC_CONFIG_FILE_BUILD} IMMEDIATE @ONLY)

# 2. For installed configuration.
if(SCC_CONFIG_ALLINONE)
  set(CMAKE_INCLUDE_DIRS_CONFIGCMAKE "${CMAKE_INSTALL_PREFIX}/${SCC_INSTALL_INCLUDE_DIR}" ${SCC_INCLUDE_DIRECTORIES})
  set(CMAKE_LIB_DIRS_CONFIGCMAKE "${CMAKE_INSTALL_PREFIX}/${SCC_INSTALL_LIB_DIR}" ${SCC_LIBRARY_DIRECTORIES})
else()
  set(CMAKE_INCLUDE_DIRS_CONFIGCMAKE "${CMAKE_INSTALL_PREFIX}/${SCC_INSTALL_INCLUDE_DIR}")
  set(CMAKE_LIB_DIRS_CONFIGCMAKE "${CMAKE_INSTALL_PREFIX}/${SCC_INSTALL_LIB_DIR}")
endif()
set(SCC_CMAKE_DIR_CONFIGCMAKE "${CMAKE_INSTALL_PREFIX}/${SCC_INSTALL_CMAKE_DIR}")
configure_file("${SCC_CMAKE_DIR}/SCCToolKitConfig.cmake.in"
               "${CMAKE_BINARY_DIR}/Install/SCCToolKitConfig.cmake" IMMEDIATE @ONLY)


#-----------------------------------------------------------------------------
# Configure Subdirectories
ADD_SUBDIRECTORY(Source)
IF(SCC_BUILD_EXAMPLES)
  ADD_SUBDIRECTORY(Examples)
ENDIF(SCC_BUILD_EXAMPLES)

#-----------------------------------------------------------------------------
# Doxygen 
#IF(BUILD_DOCUMENTATION)
#  #SUBDIRS(Utilities/Doxygen)
#  ADD_SUBDIRECTORY( Documents/Doxygen )
#  CONFIGURE_FILE(${SCC_SOURCE_DIR}/Utilities/Doxygen/doxygen.config.in
#               ${SCC_BINARY_DIR}/doxygen.config)

#  CONFIGURE_FILE(${SCC_SOURCE_DIR}/Utilities/Doxygen/sccdoxygen.pl.in
#               ${SCC_BINARY_DIR}/sccdoxygen.pl)
#ENDIF(BUILD_DOCUMENTATION)
