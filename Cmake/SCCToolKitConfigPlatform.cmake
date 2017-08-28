#/*=========================================================================
#
#  SCCToolKit root CMakeList.txt
#
#  Program:   Small Computings for Clinicals Project
#  Module:    $HeadURL: $
#  Language:  Cmake
#  Date:      $Date: $
#  Version:   $Revision: $
#
#  Kiyoyuki Chinzei, Ph.D.
#  (c) National Institute of Advanced Industrial Science and Technology (AIST), Japan All rights reserved.
#
#  Acknowledgement: This work is/was supported by many research fundings.
#  See Acknowledgement.txt
# 
#  This CMakeLists.txt was copied from OpenIGTLink (around Oct 2009).
#
#  This software is distributed WITHOUT ANY WARRANTY; without even
#  the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
#  PURPOSE.  See the above copyright notices for more information.
#
#=========================================================================*/

if(CMAKE_SYSTEM_NAME STREQUAL "Darwin")
  SET(SCC_USE_PTHREADS 1)
  SET(SCC_PLATFORM_MACOSX 1)
  SET(SCC_HAVE_GETSOCKNAME_WITH_SOCKLEN_T 1)
endif(CMAKE_SYSTEM_NAME STREQUAL "Darwin")

if(CMAKE_SYSTEM_NAME MATCHES "Linux")
  SET(SCC_USE_PTHREADS 1)
  SET(SCC_PLATFORM_LINUX 1)
  SET(SCC_HAVE_GETSOCKNAME_WITH_SOCKLEN_T 1)
endif(CMAKE_SYSTEM_NAME MATCHES "Linux")

if(CMAKE_SYSTEM_NAME STREQUAL "Windows")
  SET(SCC_USE_WIN32_THREADS 1)
  SET(SCC_PLATFORM_WIN32 1)
endif(CMAKE_SYSTEM_NAME STREQUAL "Windows")

#-----------------------------------------------------------------------------
# Type Check 
# 

include(CheckTypeSize)
check_type_size(int         CMAKE_SIZEOF_INT)
check_type_size(long        CMAKE_SIZEOF_LONG)
check_type_size("void*"     CMAKE_SIZEOF_VOID_P)
check_type_size(char        CMAKE_SIZEOF_CHAR)
check_type_size(short       CMAKE_SIZEOF_SHORT)
check_type_size(float       CMAKE_SIZEOF_FLOAT)
check_type_size(double      CMAKE_SIZEOF_DOUBLE)
check_type_size("long long" CMAKE_SIZEOF_LONG_LONG)
check_type_size("__int64"   CMAKE_SIZEOF___INT64)
check_type_size("int64_t"   CMAKE_SIZEOF_INT64_T)

#ADD_DEFINITIONS(-DIGTL_SIZEOF_CHAR=${CMAKE_SIZEOF_CHAR})
#ADD_DEFINITIONS(-DIGTL_SIZEOF_DOUBLE=${CMAKE_SIZEOF_DOUBLE})
#ADD_DEFINITIONS(-DIGTL_SIZEOF_FLOAT=${CMAKE_SIZEOF_FLOAT})
#ADD_DEFINITIONS(-DIGTL_SIZEOF_INT=${CMAKE_SIZEOF_INT})
#ADD_DEFINITIONS(-DIGTL_SIZEOF_LONG=${CMAKE_SIZEOF_LONG})
#ADD_DEFINITIONS(-DIGTL_SIZEOF_SHORT=${CMAKE_SIZEOF_SHORT})
#ADD_DEFINITIONS(-DIGTL_SIZEOF_FLOAT=${CMAKE_SIZEOF_FLOAT})
#ADD_DEFINITIONS(-DIGTL_SIZEOF_DOUBLE=${CMAKE_SIZEOF_DOUBLE})

#IF(CMAKE_SIZEOF_LONG_LONG)
#  ADD_DEFINITIONS(-DIGTL_TYPE_USE_LONG_LONG=1)
#  ADD_DEFINITIONS(-DIGTL_SIZEOF_LONG_LONG=${CMAKE_SIZEOF_LONG_LONG})
#ELSE(CMAKE_SIZEOF_LONG_LONG)
#  IF(CMAKE_SIZEOF___INT64)
#    ADD_DEFINITIONS(-DIGTL_TYPE_USE___INT64=1)

#  ELSE(CMAKE_SIZEOF___INT64)
#    IF(CMAKE_SIZEOF_INT64_T)
#      ADD_DEFINITIONS(-DIGTL_TYPE_USE_INT64_T=1)
#      ADD_DEFINITIONS(-DIGTL_SIZEOF_INT64_T=${CMAKE_SIZEOF_INT64_T})
#    ENDIF(CMAKE_SIZEOF_INT64_T)
#  ENDIF(CMAKE_SIZEOF___INT64)
#ENDIF(CMAKE_SIZEOF_LONG_LONG)


#-----------------------------------------------------------------------------
# Environment dependent part
#
if (CMAKE_GENERATOR STREQUAL "Xcode")
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11")
else()
  # cmake incorrectly applies CXX compiler and flags to *.m files.
  # that affects Makefile. Xcode safely avoid this issue.
  add_definitions(-Doverride=)
  add_definitions(-Dnullptr=NULL)
endif()

INCLUDE (FindThreads)

IF(CMAKE_COMPILER_IS_GNUCXX)
  SET(SCC_REQUIRED_C_FLAGS "${SCC_REQUIRED_C_FLAGS} -w")
  SET(SCC_REQUIRED_CXX_FLAGS "${SCC_REQUIRED_CXX_FLAGS} -ftemplate-depth-50")

  # If the library is built as a static library, pass -fPIC option to the compiler
  IF(SCC_BUILD_GENERATE_PIC)
    SET(SCC_REQUIRED_C_FLAGS "${SCC_REQUIRED_C_FLAGS} -fPIC")
    SET(SCC_REQUIRED_CXX_FLAGS "${SCC_REQUIRED_CXX_FLAGS} -fPIC")
  ENDIF(SCC_BUILD_GENERATE_PIC)

  # pthread
  IF(CMAKE_HAVE_THREADS_LIBRARY)
    SET(SCC_REQUIRED_LINK_FLAGS "${SCC_REQUIRED_LINK_FLAGS} ${CMAKE_THREAD_LIBS_INIT}")
  ENDIF(CMAKE_HAVE_THREADS_LIBRARY)
ENDIF(CMAKE_COMPILER_IS_GNUCXX)

