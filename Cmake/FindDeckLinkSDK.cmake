# - Find DeckLink SDK includes.
# This module finds where the DeckLink SDK include file is installed.
# DeckLink SDK is the toolkit for BlackMagickDesign Capture hardware.
# Visit www.blackmagic-design.com/support
#
# This code sets the following variables:
#  DeckLinkSDK_FOUND    = DeckLinkSDK was found
#  DeckLinkSDK_PATH     = where DeckLinkSDK is. Cashed
#  DeckLinkSDK_INCLUDE_PATH = path to where ${DeckLinkSDK_INCLUDE_FILE} is found
#  DeckLinkSDK_INCLUDE_FILE = DeckLinkAPI.idl (Win) or DeckLinkAPI.h (Mac/Linux)
#  DeckLinkSDK_SRC_FILE = full path to DeckLinkAPIDispatch.cpp (Mac/Linux) or empty (Win)
#  DeckLinkSDK_LIBS     = external libraries to link for target.
#  DeckLinkSDK_DEF      = additional compiler flags.
#
# If a system environment variable either of DECKLINK_SDK_DIR, BLACKMAGIC_SDK_DIR, DECKLINK_DIR or BLACKMAGIC_DIR set, it looks at paths from them.
# Typical CmakeLists.txt snippet is;
#    IF(DeckLinkSDK_FOUND)
#      INCLUDE_DIRECTORIES("${DeckLinkSDK_INCLUDE_PATH}")
#      SET(COMPILE_DEFINITIONS "${COMPILE_DEFINITIONS};${DeckLinkSDK_DEF}")
#      TARGET_LINK_LIBRARIES(${your_app} ${your_libs} "${DeckLinkSDK_LIBS}")
#      ADD_EXECUTABLE(${your_app} ${your_srcs} "${DeckLinkSDK_SRC_FILE}")
#    ENDIF(DeckLinkSDK_FOUND)
# You do the following in your DeckLink related sources;
#    #include "DeckLinkSDK_INCLUDE_FILE"

#=============================================================================
# (c) Kiyoyuki Chinzei, AIST japan.
# Small Computings for Clinicals
# Do not remove this copyright claim and the condition of the use.
# Use, modify and distribute it freely, but at your own risk.
#=============================================================================

SET(DeckLink_DEFAULT "/src/Blackmagic_SDK")

SET(DeckLinkSDK_INCLUDE_PATH "")
SET(DeckLinkSDK_INCLUDE_FILE "")
SET(DeckLinkSDK_SRC_FILE "")
SET(DeckLinkSDK_LIBS "")
SET(DeckLinkSDK_DEF "")

IF(WIN32)
    SET(DeckLinkSDK_INCLUDE_FILE DeckLinkAPI.idl)
    SET(DeckLinkSDK_INCLUDE_PATH Win/include)
ELSE(WIN32)
    SET(DeckLinkSDK_SRC_FILE DeckLinkAPIDispatch.cpp)
    SET(DeckLinkSDK_INCLUDE_FILE DeckLinkAPI.h)
    IF(APPLE)
	SET(DeckLinkSDK_INCLUDE_PATH Mac/include)
	FIND_LIBRARY(DeckLinkSDK_LIBS CoreFoundation)
    ELSE(APPLE)
	SET(DeckLinkSDK_INCLUDE_PATH Linux/include)
	SET(DeckLinkSDK_LIBS "")
    ENDIF(APPLE)
ENDIF(WIN32)
MARK_AS_ADVANCED(FORCE DeckLinkSDK_LIBS)

# We attempt to examine with or without ${DeckLink_DEFAULT}
# We need to tempolariy unset ${DeckLinkSDK_PATH} cache.
if(DeckLinkSDK_PATH)
  scc_resolve_backslash(DeckLinkSDK_PATH)
  SET(DeckLinkSDK_PATH_TMP "${DeckLinkSDK_PATH}")
else(DeckLinkSDK_PATH)
  SET(DeckLinkSDK_PATH_TMP "${DeckLink_DEFAULT}")
endif(DeckLinkSDK_PATH)

UNSET(DeckLinkSDK_PATH CACHE)
FIND_PATH(DeckLinkSDK_PATH
    ${DeckLinkSDK_INCLUDE_PATH}/${DeckLinkSDK_INCLUDE_FILE}
    PATHS "${DeckLinkSDK_PATH_TMP}" ENV DECKLINK_SDK_DIR ENV BLACKMAGIC_SDK_DIR ENV DECKLINK_DIR ENV BLACKMAGIC_DIR
    DOC "Where DeckLinkSDK locates."
   )
UNSET(DeckLinkSDK_PATH_TMP)

IF(EXISTS "${DeckLinkSDK_PATH}/${DeckLinkSDK_INCLUDE_PATH}/${DeckLinkSDK_INCLUDE_FILE}")
    IF(DeckLinkSDK_SRC_FILE)
	SET(DeckLinkSDK_SRC_FILE "${DeckLinkSDK_PATH}/${DeckLinkSDK_INCLUDE_PATH}/${DeckLinkSDK_SRC_FILE}")
    ENDIF(DeckLinkSDK_SRC_FILE)
    SET(DeckLinkSDK_INCLUDE_PATH "${DeckLinkSDK_PATH}/${DeckLinkSDK_INCLUDE_PATH}")
    SET(DeckLinkSDK_PATH
      "${DeckLinkSDK_PATH}"
      CACHE PATH "Where DeckLinkSDK locates.")
#    MARK_AS_ADVANCED(
#      DeckLinkSDK_INCLUDE_PATH
#      DeckLinkSDK_INCLUDE_FILE
#      DeckLinkSDK_SRC_FILE)
ELSE()    
    UNSET(DeckLinkSDK_INCLUDE_PATH)
    UNSET(DeckLinkSDK_SRC_FILE)
    UNSET(DeckLinkSDK_LIBS)
    UNSET(DeckLinkSDK_DEF)
    UNSET(DeckLinkSDK_PATH CACHE)
    SET(DeckLinkSDK_PATH
      DeckLinkSDK-NOTFOUND
      CACHE PATH "Where DeckLinkSDK locates.")
ENDIF()

# Handle the QUIETLY and REQUIRED arguments and set DeckLinkSDK_FOUND to TRUE if 
# all listed variables are TRUE

INCLUDE(FindPackageHandleStandardArgs)
find_package_handle_standard_args(
  DeckLinkSDK 
  DEFAULT_MSG
  DeckLinkSDK_PATH)
SET(DeckLinkSDK_FOUND ${DECKLINKSDK_FOUND})