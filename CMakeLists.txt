# ======================================================================
#  larsoft main build file
#
#  cd .../path/to/build/directory
#  source .../path/to/larsoft/ups/setup_for_development <-d|-p>
#  cmake [-DCMAKE_INSTALL_PREFIX=/install/path]
#        -DCMAKE_BUILD_TYPE=$CETPKG_TYPE
#        $CETPKG_SOURCE
#  make
#  make test
#  make install
#  make package (builds distribution tarfile)
# ======================================================================


cmake_minimum_required(VERSION 3.19 FATAL_ERROR)

project(icarusutil VERSION 09.62.00 LANGUAGES CXX)

# cetbuildtools contains our cmake modules
find_package(cetbuildtools REQUIRED)

list(APPEND CMAKE_MODULE_PATH $ENV{CANVAS_ROOT_IO_DIR}/Modules)

include(CetCMakeEnv)
cet_cmake_env()

set_install_root()

cet_set_compiler_flags(DIAGS CAUTIOUS
  WERROR
  NO_UNDEFINED
  EXTRA_FLAGS -pedantic
)

cet_report_compiler_flags()

# these are minimum required versions, not the actual product versions
find_ups_product( art )
find_ups_product(art_root_io)



# macros for dictionary and simple_plugin
include(ArtDictionary)
include(ArtMake)
include(BuildPlugins)

# ADD SOURCE CODE SUBDIRECTORIES HERE

# subdirectory for test code
# add_subdirectory(test)

# ups - table and config files
add_subdirectory(ups)

# XML project files.
# add_subdirectory(xml)

# Scripts and utilities.
# add_subdirectory(scripts)

# Python modules.
add_subdirectory(python)

# POMS config and script files
add_subdirectory(POMS)

# Validation scripts
# add_subdirectory(validation)

# Tools (programs)
# add_subdirectory(tools)

# FCL module
# add_subdirectory(fclmodule)

# Root batch framework.
# add_subdirectory(root_batch)

# Root analysis modules.
# add_subdirectory(root_analyze)

# Add subdirectory for scripts
add_subdirectory(scripts)

# packaging utility
include(UseCPack)
