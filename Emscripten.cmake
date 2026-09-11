include_guard(GLOBAL)
include("Util.cmake")

find_package(Python 3.10)

if(NOT Python_FOUND)
  message(FATAL_ERROR "Python 3.8 not found")
endif()

find_package(Git)
if(NOT Git_FOUND)
  message(FATAL_ERROR "Git not found")
endif()

if(NOT IS_READABLE emsdk)
  exec(git clone https://github.com/emscripten-core/emsdk.git emsdk)
endif()

exec(./emsdk install 6.0.9 WORKING_DIRECTORY "${topDir}/emsdk")
exec(./emsdk activate 6.0.9 WORKING_DIRECTORY "${topDir}/emsdk")

set(emDir "${topDir}/emsdk/upstream/emscripten")

# Recommended by me ig
set(emFlags "-mmutable-globals -msimd128")
