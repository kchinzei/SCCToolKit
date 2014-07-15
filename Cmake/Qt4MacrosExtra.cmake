# ===================================================================================
#
#  SCCToolKit Macro
#
#  Since version 2.8.4, cmake provided Qt-related commands such as automoc. Also cmake had macros like qt4_wrap_cpp
#  These coomads and macros assume sources are C++. In SCCToolKit for Mac we use Objective-C++, which causes
#  many errors when applying cmake's built-in Qt functions.
#  Since Qt 5, macros are integrated in Qt package, but the situation was the same.
#   Qt4MacrosExtra.cmake is a set of patches to Qt4 macros to override Qt4Macros.
#
#  Program:   Intelligent Surgical Instruments Project
#  Module:    $HeadURL: $
#  Language:  Cmake
#  Date:      $Date: $
#  Version:   $Revision: $
#
#  (c) National Institute of Advanced Industrial Science and Technology (AIST), Japan All rights reserved.
#  This work is/was supported by
#             AIST Strategic Funding
#             MHLW H24-Area-Norm-007
#             NEDO P10003 "Intelligent Surgical Instruments Project"
# ===================================================================================

#=============================================================================
# Copyright 2005-2009 Kitware, Inc.
#
# Distributed under the OSI-approved BSD License (the "License");
# see accompanying file Copyright.txt for details.
#
# This software is distributed WITHOUT ANY WARRANTY; without even the
# implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the License for more information.
#=============================================================================
# (To distribute this file outside of CMake, substitute the full
#  License text for the above reference.)


# QT4_WRAP_CPP(outfiles inputfile ... )

MACRO (QT4_WRAP_CPP outfiles )
  # get include dirs
  if(${CMAKE_VERSION} VERSION_GREATER 2.8.12)
    QT4_GET_MOC_FLAGS(moc_flags)
    QT4_EXTRACT_OPTIONS(moc_files moc_options moc_target ${ARGN})

    foreach (it ${moc_files})
      get_filename_component(it ${it} ABSOLUTE)
      get_source_file_property(_lang ${it} LABELS)
      if(${_lang} MATCHES "OBJC")
	QT4_MAKE_OUTPUT_FILE(${it} moc_ mm outfile)
      else()
	QT4_MAKE_OUTPUT_FILE(${it} moc_ cxx outfile)
      endif()
      QT4_CREATE_MOC_COMMAND(${it} ${outfile} "${moc_flags}" "${moc_options}" "${moc_target}")
      set(${outfiles} ${${outfiles}} ${outfile})
    endforeach()
  else()
    QT4_GET_MOC_FLAGS(moc_flags)
    QT4_EXTRACT_OPTIONS(moc_files moc_options ${ARGN})

    FOREACH (it ${moc_files})
      GET_FILENAME_COMPONENT(it ${it} ABSOLUTE)
      get_source_file_property(_lang ${it} LABELS)
      if(${_lang} MATCHES "OBJC")
	QT4_MAKE_OUTPUT_FILE(${it} moc_ mm outfile)
      else()
	QT4_MAKE_OUTPUT_FILE(${it} moc_ cxx outfile)
      endif()
      QT4_CREATE_MOC_COMMAND(${it} ${outfile} "${moc_flags}" "${moc_options}")
      SET(${outfiles} ${${outfiles}} ${outfile})
    ENDFOREACH(it)
  endif()
ENDMACRO (QT4_WRAP_CPP)


MACRO(QT4_CREATE_TRANSLATION _qm_files)
   if(${CMAKE_VERSION} VERSION_GREATER 2.8.12)
     QT4_EXTRACT_OPTIONS(_lupdate_files _lupdate_options _lupdate_target ${ARGN})
   else()
     QT4_EXTRACT_OPTIONS(_lupdate_files _lupdate_options ${ARGN})
   endif()
   SET(_my_sources)
   SET(_my_dirs)
   SET(_my_tsfiles)
   SET(_ts_pro)
   FOREACH (_file ${_lupdate_files})
     GET_FILENAME_COMPONENT(_ext ${_file} EXT)
     GET_FILENAME_COMPONENT(_abs_FILE ${_file} ABSOLUTE)
     IF(_ext MATCHES "ts")
       LIST(APPEND _my_tsfiles ${_abs_FILE})
     ELSE(_ext MATCHES "ts")
       IF(NOT _ext)
         LIST(APPEND _my_dirs ${_abs_FILE})
       ELSE(NOT _ext)
         LIST(APPEND _my_sources ${_abs_FILE})
       ENDIF(NOT _ext)
     ENDIF(_ext MATCHES "ts")
   ENDFOREACH(_file)
   FOREACH(_ts_file ${_my_tsfiles})
     IF(_my_sources)
       # make a .pro file to call lupdate on, so we don't make our commands too
       # long for some systems
       GET_FILENAME_COMPONENT(_ts_name ${_ts_file} NAME_WE)
       SET(_ts_pro ${CMAKE_CURRENT_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/${_ts_name}_lupdate.pro)
       SET(_pro_srcs)
       set(_pro_objc_srcs)
       FOREACH(_pro_src ${_my_sources})
	 get_source_file_property(_lang ${_pro_src} LABELS)
	 if(${_lang} MATCHES "OBJC")
           set(_pro_objc_srcs "${_pro_objc_srcs} \"${_pro_src}\"")
	 else()
           SET(_pro_srcs "${_pro_srcs} \"${_pro_src}\"")
	 endif()
       ENDFOREACH(_pro_src ${_my_sources})
       SET(_pro_includes)
       GET_DIRECTORY_PROPERTY(_inc_DIRS INCLUDE_DIRECTORIES)
       LIST(REMOVE_DUPLICATES _inc_DIRS)
       FOREACH(_pro_include ${_inc_DIRS})
         GET_FILENAME_COMPONENT(_abs_include "${_pro_include}" ABSOLUTE)
         SET(_pro_includes "${_pro_includes} \"${_abs_include}\"")
       ENDFOREACH(_pro_include ${CMAKE_CXX_INCLUDE_PATH})
       if(${_pro_objc_srcs})
	 FILE(WRITE ${_ts_pro} "CONFIG += objective_c\nSOURCES = ${_pro_srcs}\nOBJECTIVE_SOURCES = ${_pro_objc_srcs}\nINCLUDEPATH = ${_pro_includes}\n")
       else()
	 FILE(WRITE ${_ts_pro} "SOURCES = ${_pro_srcs}\nINCLUDEPATH = ${_pro_includes}\n")
       endif()
     ENDIF(_my_sources)
     ADD_CUSTOM_COMMAND(OUTPUT ${_ts_file}
        COMMAND ${QT_LUPDATE_EXECUTABLE}
        ARGS ${_lupdate_options} ${_ts_pro} ${_my_dirs} -ts ${_ts_file}
        DEPENDS ${_my_sources} ${_ts_pro} VERBATIM)
   ENDFOREACH(_ts_file)
   QT4_ADD_TRANSLATION(${_qm_files} ${_my_tsfiles})
ENDMACRO(QT4_CREATE_TRANSLATION)
