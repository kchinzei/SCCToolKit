# This module finds where the DeckLink SDK include file is installed.
# DeckLink SDK is the toolkit for BlackMagickDesign Capture hardware.
# Visit www.blackmagic-design.com/support
#
# This code sets the following variables:
#  DeckLinkSDK_FOUND    = DeckLinkSDK is found
#  DeckLinkSDK_PATH     = where DeckLinkSDK is. Cashed
#  DeckLinkSDK_INCLUDE_PATH = path to where ${DeckLinkSDK_INCLUDE_FILE} is found
#  DeckLinkSDK_INCLUDE_FILE = DeckLinkAPI.idl (Win) or DeckLinkAPI.h (Mac/Linux)
#  DeckLinkSDK_SRC_FILE = full path to DeckLinkAPIDispatch.cpp (Mac/Linux) or empty (Win)
#  DeckLinkSDK_LIBS     = external libraries to link for target.
#  DeckLinkSDK_DEF      = additional compiler flags.
#
# If a system environment variable either of DECKLINK_SDK_DIR, BLACKMAGIC_SDK_DIR, DECKLINK_DIR or BLACKMAGIC_DIR set,
# it looks at paths from them.
# Typical CmakeLists.txt snippet is;
#    FIND_PACKAGE(DeckLinkSDK REQUIRED)
#    IF(DeckLinkSDK_FOUND)
#      INCLUDE_DIRECTORIES("${DeckLinkSDK_INCLUDE_PATH}")
#      IF   (COMPILE_DEFINITIONS)
#        SET(COMPILE_DEFINITIONS "${COMPILE_DEFINITIONS};${DeckLinkSDK_DEF}")
#      ELSE (COMPILE_DEFINITIONS)
#        SET(COMPILE_DEFINITIONS ${DeckLinkSDK_DEF})
#      ENDIF(COMPILE_DEFINITIONS)
#      ADD_EXECUTABLE(${your_app} ${your_srcs} "${DeckLinkSDK_SRC_FILE}")
#      TARGET_LINK_LIBRARIES(${your_app} ${your_libs} "${DeckLinkSDK_LIBS}")
#    ENDIF(DeckLinkSDK_FOUND)
# You do the following in your DeckLink related sources;
#    #include "DeckLinkSDK.h"
#
# You can optionally provide version argument, for example;
#    FIND_PACKAGE(DeckLinkSDK 10.5 REQUIRED)
# will ensure the version of the SDK is greater than or equal to 10.5 (e.g., 10.4.99 will produce an error.)

#=============================================================================
# (c) Kiyoyuki Chinzei, AIST japan.
# Small Computings for Clinicals
# Do not remove this copyright claim and the license conditions below.
# This file is released under two licenses: the BSD 3-Clause license and the MIT license.
# See https://opensource.org/licenses
# You may pick the license that best suits your needs.
#=============================================================================

# _resolve_backslash
#
# Resolve backslashes in ${variable} to properly work on path expression. It assumes 3 cases:
#  1) set(variable "c:\\foo\\hoge")
#  2) set(variable "c:\foo\hoge")
#  3) set(variable "/foo/hoge\ hoge")
# For these cases, scc_resolve_backslash(variable) will resolve
#  1) "c:/foo/hoge"
#  2) "c:/foo/hoge"
#  3) "/foo/hoge hoge"
# accordingly. It does not check valiable is valid.
function(_resolve_backslash variable)
  set(_tmpv ${${variable}})
  string(REPLACE "\\\\" "/" _tmpv ${_tmpv})
  string(REPLACE "\\ " " " _tmpv ${_tmpv})
  string(REPLACE "\\" "/" _tmpv ${_tmpv})
  set(${variable} "${_tmpv}" PARENT_SCOPE)
endfunction()

#
# Main code of this module
#
SET(DeckLink_DEFAULT "/src/Blackmagic_SDK")

#UNSET(DeckLinkSDK_FOUND)
#SET(DeckLinkSDK_INCLUDE_PATH "")
#SET(DeckLinkSDK_INCLUDE_FILE "")
#SET(DeckLinkSDK_SRC_FILE "")
#SET(DeckLinkSDK_DEF "")
#UNSET(DeckLinkSDK_INCLUDE_PATH CACHE)
#UNSET(DeckLinkSDK_INCLUDE_FILE CACHE)
#UNSET(DeckLinkSDK_SRC_FILE CACHE)
#UNSET(DeckLinkSDK_LIBS CACHE)
#UNSET(DeckLinkSDK_DEF)

IF(WIN32)
    SET(__include_file DeckLinkAPI.idl)
    SET(__include_path Win/include)
ELSE(WIN32)
    SET(__src_file DeckLinkAPIDispatch.cpp)
    SET(__include_file DeckLinkAPI.h)
    IF(APPLE)
	SET(__include_path Mac/include)
	FIND_LIBRARY(DeckLinkSDK_LIBS CoreFoundation)
    ELSE(APPLE)
	SET(__include_path Linux/include)
	SET(DeckLinkSDK_LIBS "")
    ENDIF(APPLE)
ENDIF(WIN32)
MARK_AS_ADVANCED(FORCE DeckLinkSDK_LIBS)

# We attempt to examine with or without ${DeckLink_DEFAULT}
# We need to tempolariy unset ${DeckLinkSDK_PATH} cache.
IF(DeckLinkSDK_PATH)
  SET(decklinksdk_path_tmp "${DeckLinkSDK_PATH}")
ELSEIF(DeckLink_DEFAULT)
  SET(decklinksdk_path_tmp "${DeckLink_DEFAULT}")
ENDIF(DeckLinkSDK_PATH)
_resolve_backslash(decklinksdk_path_tmp)

UNSET(DeckLinkSDK_PATH CACHE)
FIND_PATH(DeckLinkSDK_PATH
    ${__include_path}/${__include_file}
    PATHS "${decklinksdk_path_tmp}" ENV DECKLINK_SDK_DIR ENV BLACKMAGIC_SDK_DIR ENV DECKLINK_DIR ENV BLACKMAGIC_DIR
    DOC "Where DeckLinkSDK locates."
   )

FIND_PATH(DeckLinkSDK_INCLUDE_PATH ${__include_file} PATHS "${DeckLinkSDK_PATH}" PATH_SUFFIXES ${__include_path})
SET(DeckLinkSDK_INCLUDE_FILE ${__include_file})
IF(__src_file)
  FIND_FILE(DeckLinkSDK_SRC_FILE ${__src_file} PATHS "${DeckLinkSDK_INCLUDE_PATH}")
ENDIF(__src_file)

MARK_AS_ADVANCED(DeckLinkSDK_INCLUDE_PATH DeckLinkSDK_SRC_FILE)

SET(version.h "${DeckLinkSDK_INCLUDE_PATH}/DeckLinkAPIVersion.h")
IF(EXISTS "${version.h}")
  FILE(STRINGS "${version.h}" _tmpstr REGEX "^#define[\t ]+BLACKMAGIC_DECKLINK_API_VERSION_STRING[\t ]+\".*\"")
  STRING(REGEX REPLACE                      "^#define[\t ]+BLACKMAGIC_DECKLINK_API_VERSION_STRING[\t ]+\"([^\"]*)\".*" "\\1"
    DeckLinkSDK_VERSION_STRING "${_tmpstr}")
ENDIF()

INCLUDE(FindPackageHandleStandardArgs)
IF(__src_file)
  FIND_PACKAGE_HANDLE_STANDARD_ARGS(
    DeckLinkSDK
    REQUIRED_VARS DeckLinkSDK_PATH DeckLinkSDK_INCLUDE_PATH DeckLinkSDK_SRC_FILE
    VERSION_VAR DeckLinkSDK_VERSION_STRING
    FAIL_MESSAGE "DeckLink SDK not found. Usually in 'Blackmagic DeckLink SDK *.*.*'.")
ELSE()
  FIND_PACKAGE_HANDLE_STANDARD_ARGS(
    DeckLinkSDK
    REQUIRED_VARS DeckLinkSDK_PATH DeckLinkSDK_INCLUDE_PATH
    VERSION_VAR DeckLinkSDK_VERSION_STRING
    FAIL_MESSAGE "DeckLink SDK not found. Usually in 'Blackmagic DeckLink SDK *.*.*'.")
ENDIF()
