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

# scc_define_option
# Provides an option that the user can optionally select.
# Can accept condition to control when option is available for user.
# Usage:
#   scc_define_option(<option_variable> "help string describing the option" <initial value or boolean expression> [IF <condition>] [TYPE cachetype])
#
#  This function was modified from ocv_define_option in OpenCVIUtils.cmake in OpenCV 2.4.5
#
function(scc_define_option variable description value)
  set(__value ${value})
  set(__condition "")
  set(__type "")
  set(__varname "__value")
  foreach(arg ${ARGN})
    if(arg STREQUAL "IF" OR arg STREQUAL "if")
      set(__varname "__condition")
    elseif(arg STREQUAL "TYPE" OR arg STREQUAL "type")
      set(__varname "__type")
    else()
      list(APPEND ${__varname} ${arg})
    endif()
  endforeach()
  if(x${__condition} STREQUAL x)
    set(__condition 2 GREATER 1)
  endif()
  if(x${__type} STREQUAL x)
    set(__type STRING)
  endif()

  if(${__condition} AND NOT x${__value} STREQUAL x)
    if("${__value}" MATCHES ";")
      if (${__value} STREQUAL ON OR ${__value} STREQUAL TRUE OR ${__value} STREQUAL YES OR
	  ${__value} STREQUAL on OR ${__value} STREQUAL true OR ${__value} STREQUAL yes)
        option(${variable} "${description}" ON)
      elseif (${__value} STREQUAL OFF OR ${__value} STREQUAL FALSE OR ${__value} STREQUAL NO OR
	      ${__value} STREQUAL off OR ${__value} STREQUAL false OR ${__value} STREQUAL no)
        option(${variable} "${description}" OFF)
      else()
	set(${variable} ${__value} CACHE ${__type} "${description}")
      endif()
    elseif(DEFINED ${__value})
      if (${__value} STREQUAL ON OR ${__value} STREQUAL TRUE OR ${__value} STREQUAL YES OR
	  ${__value} STREQUAL on OR ${__value} STREQUAL true OR ${__value} STREQUAL yes)
        option(${variable} "${description}" ON)
      elseif (${__value} STREQUAL OFF OR ${__value} STREQUAL FALSE OR ${__value} STREQUAL NO OR
	      ${__value} STREQUAL off OR ${__value} STREQUAL false OR ${__value} STREQUAL no)
        option(${variable} "${description}" OFF)
      else()
	set(${variable} ${__value} CACHE ${__type} "${description}")
      endif()
    else()
      if (${__value} STREQUAL ON OR ${__value} STREQUAL TRUE OR ${__value} STREQUAL YES OR 
	  ${__value} STREQUAL on OR ${__value} STREQUAL true OR ${__value} STREQUAL yes)
        option(${variable} "${description}" ON)
      elseif (${__value} STREQUAL OFF OR ${__value} STREQUAL FALSE OR ${__value} STREQUAL NO OR
	      ${__value} STREQUAL off OR ${__value} STREQUAL false OR ${__value} STREQUAL no)
        option(${variable} "${description}" OFF)
      else()
	set(${variable} ${__value} CACHE ${__type} "${description}")
      endif()
    endif()
  else()
    unset(${variable} CACHE)
  endif()
endfunction(scc_define_option)

function(scc_clear_vars)
  foreach(_var ${ARGN})
    unset(${_var} CACHE)
  endforeach()
endfunction()

# scc_read_opencv_config
#
# This is used to obtain Qt information if OpenCV was build with Qt.
# If it was so, we must use the same Qt. It may be the case of home-built OpenCV.
# 
function(scc_read_opencv_config)
  if(OpenCV_FOUND)
    find_file(__OPENCV_CACHE CMakeCache.txt PATHS ${OpenCV_DIR})
    if(__OPENCV_CACHE)
      set(__Qt5Core_DIR_OLD ${Qt5Core_DIR})
      # Read settings from cache
      load_cache(${OpenCV_DIR} READ_WITH_PREFIX
	__OPENCV_
	WITH_QT
	Qt5Concurrent_DIR
	Qt5Core_DIR
	Qt5Gui_DIR
	Qt5OpenGL_DIR
	Qt5Widgets_DIR
	Qt5LinguistTools_DIR
	QT_QMAKE_EXECUTABLE
	)
      # Is it compiled with Qt?
      if(__OPENCV_WITH_QT)
	# What version?
	if(__OPENCV_Qt5Core_DIR)
	  if(NOT Qt5Core_DIR STREQUAL __Qt5Core_DIR_OLD)
	    set(_qt5core_changed YES)
	  else()
	    set(_qt5core_changed NO)
	  endif()
	  set(Qt5Core_DIR "${__OPENCV_Qt5Core_DIR}" CACHE INTERNAL "" FORCE)
	  if(__OPENCV_Qt5Gui_DIR)
	    set(Qt5Gui_DIR "${__OPENCV_Qt5Gui_DIR}" CACHE INTERNAL "" FORCE)
	  else()
	    scc_guess_qt5module_dir(Qt5Gui ${_qt5core_changed})
	  endif()
	  if(__OPENCV_Qt5OpenGL_DIR)
	    set(Qt5OpenGL_DIR "${__OPENCV_Qt5OpenGL_DIR}" CACHE INTERNAL "" FORCE)
	  else()
	    scc_guess_qt5module_dir(Qt5OpenGL ${_qt5core_changed})
	  endif()
	  if(__OPENCV_Qt5Widgets_DIR)
	    set(Qt5Widgets_DIR "${__OPENCV_Qt5Widgets_DIR}" CACHE INTERNAL "" FORCE)
	  else()
	    scc_guess_qt5module_dir(Qt5Widgets ${_qt5core_changed})
	  endif()
	  if(__OPENCV_Qt5Concurrent_DIR)
	    set(Qt5Concurrent_DIR "${__OPENCV_Qt5Concurrent_DIR}" CACHE INTERNAL "" FORCE)
	  else()
	    scc_guess_qt5module_dir(Qt5Concurrent ${_qt5core_changed})
	  endif()
	  if(__OPENCV_Qt5LinguistTools_DIR)
	    set(Qt5LinguistTools_DIR ${__Qt5LinguistTools_DIR} CACHE INTRERNAL "" FORCE)
	  else()
	    scc_guess_qt5module_dir(Qt5LinguistTools ${_qt5core_changed})
	  endif()
	  scc_clear_vars(QT_QMAKE_EXECUTABLE)
	  set(SCC_QT_MAJOR_VERSION 5 CACHE STRING "" FORCE)
	else(__OPENCV_Qt5Core_DIR)
	  set(QT_QMAKE_EXECUTABLE "${__OPENCV_QT_QMAKE_EXECUTABLE}" CACHE INTERNAL "" FORCE)
	  scc_clear_vars(Qt5Concurrent_DIR Qt5Core_DIR Qt5Gui_DIR Qt5OpenGL_DIR Qt5Widgets_DIR Qt5LinguistTools_DIR)
	  set(SCC_QT_MAJOR_VERSION 4 CACHE STRING "" FORCE)
	endif(__OPENCV_Qt5Core_DIR)
      endif(__OPENCV_WITH_QT)
    endif(__OPENCV_CACHE)
    unset(__OPENCV_CACHE CACHE)
  endif(OpenCV_FOUND)
endfunction(scc_read_opencv_config)

# scc_guess_qt5module_dir
# Since Qt5, cmake config files are provided per modules (Qt5Core, Qt5Gui, etc)
# This forces user to specify path to every module, which is painful.
# scc_guess_qt5module_dir() can guess module's path from that of Q5tCore.
#
# Assumption: Modules (Qt5XXXConfig.cmake files) are in the same parent directory,
# such as /foo/Qt5Core, /foo/Qt5XXX, ...
#
# usage: scc_guess_qt5module_dir(qt5module_dir module_name qt5core_dir [FORCE])
#  module_name : name of the module, e.g., Qt5Gui
#  [FORCE] : when appended, returned dir will force overwritten.
#
function(scc_guess_qt5module_dir module_name)
  set(_force ${ARGN})
  set(_qt5module_dir ${module_name}_DIR)
  if(Qt5Core_DIR)
    get_filename_component(_parent_dir ${Qt5Core_DIR} DIRECTORY)
    set(module_dir ${_parent_dir}/${module_name})
    if(_force OR NOT ${_qt5module_dir})
      set(${_qt5module_dir} ${module_dir} CACHE FILEPATH "" FORCE)
    else()
      set(${_qt5module_dir} ${module_dir} CACHE FILEPATH "")
    endif()
  endif(Qt5Core_DIR)
endfunction()

function(scc_message)
  foreach(it ${ARGN})
    message("${it} = ${${it}}")
  endforeach()
endfunction()