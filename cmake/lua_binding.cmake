# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

set(CMAKE_CXX_VISIBILITY_PRESET hidden)
set(CMAKE_CXX_STANDARD 14)

if(APPLE)
    set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -undefined dynamic_lookup")
    set(CMAKE_SHARED_LIBRARY_SUFFIX ".so")
endif()

if(MSVC)
  # Predefined Macros: http://msdn.microsoft.com/en_us/library/b0084kay.aspx
  # Compiler options: http://msdn.microsoft.com/en_us/library/fwkeyyhe.aspx
  # set a high warning level and treat them as errors
  set(CMAKE_CXX_FLAGS           "/W3 /WX /EHs")
  # debug multi threaded dll runtime, complete debugging info, runtime error checking
  set(CMAKE_CXX_FLAGS_DEBUG     "/MDd /Zi /RTC1")
  # multi threaded dll runtime, optimize for speed, auto inlining
  set(CMAKE_CXX_FLAGS_RELEASE   "/MD /O2 /Ob2 /DNDEBUG")
  add_definitions(-D_CRT_SECURE_NO_WARNINGS)
else()
  # Predefined Macros: clang|gcc -dM -E -x c /dev/null
  # Compiler options: http://gcc.gnu.org/onlinedocs/gcc/Invoking_GCC.html#Invoking_GCC
  set(CMAKE_CXX_FLAGS         "-pedantic $ENV{CFLAGS} -Wall -Wextra")
  set(CMAKE_CXX_FLAGS_RELEASE "-O2 -DNDEBUG")
endif()

set(CMAKE_INSTALL_PREFIX "")
set(CMAKE_SHARED_LIBRARY_PREFIX "")

add_definitions(-DDIST_VERSION="${PROJECT_VERSION}")
if(PROJECT_NAME MATCHES  "(lua51|luasandbox)_(.+)")
  set(MODULE_NAME ${CMAKE_MATCH_2})
else()
  message(FATAL_ERROR "invalid lua project name prefix: " ${PROJECT_NAME})
endif()

string(REPLACE "_" "-" CPACK_PACKAGE_NAME ${PROJECT_NAME})
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "Lua date module")
set(CPACK_INSTALL_CMAKE_PROJECTS "${CMAKE_CURRENT_BINARY_DIR};${PROJECT_NAME};ALL;/")
set(CPACK_PACKAGE_VERSION_MAJOR  ${PROJECT_VERSION_MAJOR})
set(CPACK_PACKAGE_VERSION_MINOR  ${PROJECT_VERSION_MINOR})
set(CPACK_PACKAGE_VERSION_PATCH  ${PROJECT_VERSION_PATCH})
set(CPACK_PACKAGE_VENDOR         "Trink")
set(CPACK_PACKAGE_CONTACT        "Mike Trinkala <trink@acm.org>")
set(CPACK_OUTPUT_CONFIG_FILE     "${CMAKE_BINARY_DIR}/${PROJECT_NAME}.cpack")
set(CPACK_STRIP_FILES            TRUE)
set(CPACK_DEBIAN_FILE_NAME       "DEB-DEFAULT")
set(CPACK_RPM_FILE_NAME          "RPM-DEFAULT")
set(CPACK_RESOURCE_FILE_LICENSE  "${CMAKE_SOURCE_DIR}/LICENSE.txt")
set(CPACK_RPM_PACKAGE_LICENSE    "MPLv2.0")

set(PACKAGE_COMMANDS ${PACKAGE_COMMANDS} COMMAND cpack -G ${CPACK_GENERATOR} --config ${PROJECT_NAME}.cpack PARENT_SCOPE)

set(SB_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../sandboxes)
if(IS_DIRECTORY ${SB_DIR})
    install(DIRECTORY ${SB_DIR}/ DESTINATION ${INSTALL_SANDBOX_PATH} ${DPERMISSION})
endif()

set(MODULE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../modules)
if(IS_DIRECTORY ${MODULE_DIR})
    install(DIRECTORY ${MODULE_DIR}/ DESTINATION ${INSTALL_MODULE_PATH} ${DPERMISSION})
endif()

set(IOMODULE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../io_modules)
if(IS_DIRECTORY ${IOMODULE_DIR})
    install(DIRECTORY ${IOMODULE_DIR}/ DESTINATION ${INSTALL_IOMODULE_PATH} ${DPERMISSION})
endif()

add_custom_target(${PROJECT_NAME}_copy_tests ALL COMMAND ${CMAKE_COMMAND} -E copy_directory
${CMAKE_SOURCE_DIR}/tests
${CMAKE_CURRENT_BINARY_DIR})

if(PROJECT_NAME MATCHES "^lua51")
    set(CPACK_DEBIAN_PACKAGE_DEPENDS "lua5.1")
    set(INSTALL_MODULE_PATH ${CMAKE_INSTALL_LIBDIR}/lua)
    set(INSTALL_IOMODULE_PATH ${CMAKE_INSTALL_LIBDIR}/lua)
    set(INSTALL_SANDBOX_PATH ${CMAKE_INSTALL_DATAROOTDIR}/lua)
    if(WIN32)
        string(REPLACE "\\" "\\\\" TEST_MODULE_PATH "${CMAKE_CURRENT_BINARY_DIR}\\?.lua")
        string(REGEX REPLACE "\\.lua$" ".dll" TEST_MODULE_CPATH ${TEST_MODULE_PATH})
    else()
        set(TEST_MODULE_PATH "${CMAKE_CURRENT_BINARY_DIR}/?.lua")
        string(REGEX REPLACE "\\.lua$" ".so" TEST_MODULE_CPATH ${TEST_MODULE_PATH})
    endif()
    add_test(NAME ${PROJECT_NAME}_test COMMAND ${LUA} test.lua)
    set_property(TEST ${PROJECT_NAME}_test PROPERTY ENVIRONMENT
    "LUA_PATH=${TEST_MODULE_PATH}" "LUA_CPATH=${TEST_MODULE_CPATH}" TZ=UTC)
    set(CPACK_DEBIAN_PACKAGE_DEPENDS "lua5.1, iana-tzdata")
    string(REGEX REPLACE "[()]" "" CPACK_RPM_PACKAGE_REQUIRES ${CPACK_DEBIAN_PACKAGE_DEPENDS})
else(PROJECT_NAME MATCHES "^luasandbox")
    set(CPACK_DEBIAN_PACKAGE_DEPENDS "luasandbox (>= 1.2)")
    set(LUA_LIBRARIES ${LUASANDBOX_LIBRARIES})
    set(LUA_INCLUDE_DIR ${LUASANDBOX_INCLUDE_DIR}/luasandbox)
    set(INSTALL_MODULE_PATH ${CMAKE_INSTALL_LIBDIR}/luasandbox/modules)
    set(INSTALL_IOMODULE_PATH ${CMAKE_INSTALL_LIBDIR}/luasandbox/io_modules)
    set(INSTALL_SANDBOX_PATH ${CMAKE_INSTALL_DATAROOTDIR}/luasandbox/sandboxes)
    add_definitions(-DLUA_SANDBOX)
    if(WIN32)
        string(REPLACE "\\" "\\\\" TEST_MODULE_PATH "${CMAKE_CURRENT_BINARY_DIR}\\?.lua")
        string(REGEX REPLACE "\\.lua$" ".dll" TEST_MODULE_CPATH ${TEST_MODULE_PATH})
    else()
        set(TEST_MODULE_PATH "${CMAKE_CURRENT_BINARY_DIR}/?.lua")
        string(REGEX REPLACE "\\.lua$" ".so" TEST_MODULE_CPATH ${TEST_MODULE_PATH})
    endif()
    configure_file(${CMAKE_SOURCE_DIR}/cmake/test_module.in.h ${CMAKE_CURRENT_BINARY_DIR}/test_module.h)
    include_directories(${CMAKE_CURRENT_BINARY_DIR} ${LUASANDBOX_INCLUDE_DIR})
    add_executable(${PROJECT_NAME}_test test_sandbox.c)
    target_link_libraries(${PROJECT_NAME}_test ${LUASANDBOX_TEST_LIBRARY} ${LUASANDBOX_LIBRARIES})
    add_test(NAME ${PROJECT_NAME}_test COMMAND ${PROJECT_NAME}_test)
    if(WIN32)
       string(REPLACE "/luasandbox.lib" "" LIB_PATH ${LUASANDBOX_LIBRARY})
       message(LIB_PATH ${LIB_PATH})
       set_tests_properties(${PROJECT_NAME}_test PROPERTIES ENVIRONMENT PATH=${LIB_PATH})
    endif()
    set(CPACK_DEBIAN_PACKAGE_DEPENDS "luasandbox (>= 1.0), iana-tzdata")
    string(REGEX REPLACE "[()]" "" CPACK_RPM_PACKAGE_REQUIRES ${CPACK_DEBIAN_PACKAGE_DEPENDS})
endif()
set_tests_properties(${PROJECT_NAME}_test PROPERTIES ENVIRONMENT "IANA_TZDATA=${CMAKE_SOURCE_DIR}/iana/tzdata")

add_definitions(-DINSTALL=/usr/${INSTALL_IANA_PATH} -DHAS_REMOTE_API=0 -DAUTO_DOWNLOAD=0) # todo modify tz.cpp to load the path from the ENV

include_directories(${LUA_INCLUDE_DIR})
add_library(${PROJECT_NAME} SHARED ${MODULE_SRCS})
set_target_properties(${PROJECT_NAME} PROPERTIES OUTPUT_NAME ${MODULE_NAME})
if(WIN32)
    target_link_libraries(${PROJECT_NAME} ${LUA_LIBRARIES})
endif()
if(PTHREAD_LIBRARY)
  target_link_libraries(${PROJECT_NAME} ${PTHREAD_LIBRARY})
endif()
set(EMPTY_DIR ${CMAKE_BINARY_DIR}/empty)
file(MAKE_DIRECTORY ${EMPTY_DIR})
install(DIRECTORY ${EMPTY_DIR}/ DESTINATION ${INSTALL_MODULE_PATH} ${DPERMISSION})
install(TARGETS ${PROJECT_NAME} DESTINATION ${INSTALL_MODULE_PATH})
include(CPack)
