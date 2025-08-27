#----------------------------------------------------------------
# Generated CMake target import file for configuration "RelWithDebInfo".
#----------------------------------------------------------------

# Commands may need to know the format version.
set(CMAKE_IMPORT_FILE_VERSION 1)

# Import target "Microsoft::UVAtlas" for configuration "RelWithDebInfo"
set_property(TARGET Microsoft::UVAtlas APPEND PROPERTY IMPORTED_CONFIGURATIONS RELWITHDEBINFO)
set_target_properties(Microsoft::UVAtlas PROPERTIES
  IMPORTED_LINK_INTERFACE_LANGUAGES_RELWITHDEBINFO "CXX"
  IMPORTED_LOCATION_RELWITHDEBINFO "${_IMPORT_PREFIX}/lib/libUVAtlas.a"
  )

list(APPEND _cmake_import_check_targets Microsoft::UVAtlas )
list(APPEND _cmake_import_check_files_for_Microsoft::UVAtlas "${_IMPORT_PREFIX}/lib/libUVAtlas.a" )

# Commands beyond this point should not need to know the version.
set(CMAKE_IMPORT_FILE_VERSION)
