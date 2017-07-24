# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

cmake_minimum_required(VERSION 3.3 FATAL_ERROR)
cmake_policy(SET CMP0063 NEW)

project(date LANGUAGES NONE)
set(CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake")

set(PACKAGE_COMMANDS "")
if(NOT CPACK_GENERATOR)
  if(WIN32)
     set(CPACK_GENERATOR ZIP)
  else()
     set(CPACK_GENERATOR TGZ)
  endif()
endif()

include_directories(${CMAKE_SOURCE_DIR}/date)

include(GNUInstallDirs)
set(DPERMISSION DIRECTORY_PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE)
set(INSTALL_IANA_PATH ${CMAKE_INSTALL_DATAROOTDIR}/iana)

set(MODULE_SRCS
  ${CMAKE_SOURCE_DIR}/date.cpp
  ${CMAKE_SOURCE_DIR}/date/tz.cpp
  ${CMAKE_SOURCE_DIR}/date.def
)

include(CTest)
add_subdirectory(iana)

if(CMAKE_HOST_UNIX)
  set(CMAKE_LIBRARY_PATH ${CMAKE_LIBRARY_PATH} "/usr/lib64" "/usr/lib/x86_64-linux-gnu")
  find_library(PTHREAD_LIBRARY pthread)
endif()

find_package(Lua51)
if(LUA_LIBRARIES)
  find_program(LUA NAMES lua lua.bat)
  add_subdirectory(lua51)
endif()

find_package(luasandbox 1.2 CONFIG)
if(LUASANDBOX_LIBRARIES)
  add_subdirectory(luasandbox)
endif()

add_custom_target(docs lua gen_gh_pages.lua "0.0.1" "${CMAKE_SOURCE_DIR}" "${CMAKE_BINARY_DIR}" WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
add_custom_target(packages ${PACKAGE_COMMANDS})
