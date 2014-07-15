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
# Copyright 2005-2011 Kitware, Inc.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
# * Redistributions of source code must retain the above copyright
#   notice, this list of conditions and the following disclaimer.
#
# * Redistributions in binary form must reproduce the above copyright
#   notice, this list of conditions and the following disclaimer in the
#   documentation and/or other materials provided with the distribution.
#
# * Neither the name of Kitware, Inc. nor the names of its
#   contributors may be used to endorse or promote products derived
#   from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#=============================================================================


# qt5_wrap_cpp(outfiles inputfile ... )
# Original was in Qt5CoreMacros.cmake

function(QT5_WRAP_CPP outfiles )
    # get include dirs
    qt5_get_moc_flags(moc_flags)

    set(options)
    set(oneValueArgs TARGET)
    set(multiValueArgs OPTIONS)

    cmake_parse_arguments(_WRAP_CPP "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    set(moc_files ${_WRAP_CPP_UNPARSED_ARGUMENTS})
    set(moc_options ${_WRAP_CPP_OPTIONS})
    set(moc_target ${_WRAP_CPP_TARGET})

    if (moc_target AND CMAKE_VERSION VERSION_LESS 2.8.12)
        message(FATAL_ERROR "The TARGET parameter to qt5_wrap_cpp is only available when using CMake 2.8.12 or later.")
    endif()
    foreach(it ${moc_files})
        get_filename_component(it ${it} ABSOLUTE)
	get_source_file_property(_lang ${it} LABELS)
	if(${_lang} MATCHES "OBJC")
	  qt5_make_output_file(${it} moc_ mm outfile)
	else()
	  qt5_make_output_file(${it} moc_ cpp outfile)
	endif()
        qt5_create_moc_command(${it} ${outfile} "${moc_flags}" "${moc_options}" "${moc_target}")
        list(APPEND ${outfiles} ${outfile})
    endforeach()
    set(${outfiles} ${${outfiles}} PARENT_SCOPE)
endfunction()

