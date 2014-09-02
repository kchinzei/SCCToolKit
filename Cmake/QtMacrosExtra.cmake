#/*=========================================================================
# 
# Program:   Small Computings for Clinicals Project
# Module:    $HeadURL: $
# Date:      $Date: $
# Version:   $Revision: $
# 
# Kiyoyuki Chinzei, Ph.D.
# (c) National Institute of Advanced Industrial Science and Technology (AIST), Japan All rights reserved.
#
# Acknowledgement: This work is/was supported by many research fundings.
# See Acknowledgement.txt
# 
# This software is distributed WITHOUT ANY WARRANTY; without even
# the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
# PURPOSE.  See the above copyright notices for more information.
# 
# =========================================================================*/

FUNCTION (SCC_MARK_AS_OBJECTIVE_C)
  set(_label "OBJC")
  set_source_files_properties(${ARGN} PROPERTIES LABELS ${_label})
ENDFUNCTION (SCC_MARK_AS_OBJECTIVE_C)

FUNCTION(QT_WRAP_CPP outfiles )
  if(COMMAND qt5_wrap_cpp)
    qt5_wrap_cpp(${ARGV})
  else()
    qt4_wrap_cpp(${ARGV})
  endif()
  set(${outfiles} ${${outfiles}} PARENT_SCOPE)
ENDFUNCTION(QT_WRAP_CPP)

FUNCTION(QT_WRAP_UI outfiles )
  if(COMMAND qt5_wrap_ui)
    qt5_wrap_ui(${ARGV})
  else()
    qt4_wrap_ui(${ARGV})
  endif()
  set(${outfiles} ${${outfiles}} PARENT_SCOPE)
ENDFUNCTION(QT_WRAP_UI)

FUNCTION(QT_ADD_RESOURCES outfiles )
  if(COMMAND qt5_add_resources)
    qt5_add_resources(${ARGV})
  else()
    qt4_add_resources(${ARGV})
  endif()
  set(${outfiles} ${${outfiles}} PARENT_SCOPE)
ENDFUNCTION(QT_ADD_RESOURCES)

FUNCTION(QT_CREATE_TRANSLATION _qm_files)
  if(COMMAND qt5_create_translation)
    qt5_create_translation(${ARGV})
  else()
    qt4_create_translation(${ARGV})
  endif()
  set(${_qm_files} ${${_qm_files}} PARENT_SCOPE)
ENDFUNCTION(QT_CREATE_TRANSLATION)

FUNCTION(QT_ADD_TRANSLATION _qm_files)
  if(COMMAND qt5_add_translation)
    qt5_add_translation(${ARGV})
  else()
    qt4_add_translation(${ARGV})
  endif()
  set(${_qm_files} ${${_qm_files}} PARENT_SCOPE)
ENDFUNCTION(QT_ADD_TRANSLATION)